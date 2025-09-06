const express = require('express');
const Tweet = require('../models/Tweet');
const User = require('../models/User');
const Community = require('../models/Community');
const { auth, optionalAuth } = require('../middleware/auth');
const router = express.Router();

// Custom recommendation algorithm (non-AI)
class RecommendationEngine {
  // Calculate user similarity based on follows and interactions
  static async calculateUserSimilarity(userId1, userId2) {
    const user1 = await User.findOne({ id: userId1 });
    const user2 = await User.findOne({ id: userId2 });
    
    if (!user1 || !user2) return 0;
    
    // Calculate Jaccard similarity for following lists
    const user1Following = new Set(user1.following);
    const user2Following = new Set(user2.following);
    
    const intersection = new Set([...user1Following].filter(x => user2Following.has(x)));
    const union = new Set([...user1Following, ...user2Following]);
    
    return intersection.size / union.size;
  }
  
  // Get content-based score for tweets
  static async getContentScore(tweet, userProfile) {
    let score = 0;
    
    // Hashtag relevance
    if (userProfile.favoriteHashtags) {
      const tweetHashtags = new Set(tweet.hashtags);
      const userHashtags = new Set(userProfile.favoriteHashtags);
      const hashtagIntersection = new Set([...tweetHashtags].filter(x => userHashtags.has(x)));
      score += hashtagIntersection.size * 2;
    }
    
    // Community relevance
    if (userProfile.communities && tweet.communityId) {
      if (userProfile.communities.includes(tweet.communityId)) {
        score += 3;
      }
    }
    
    // User interaction history
    if (userProfile.interactedUsers && userProfile.interactedUsers.includes(tweet.userId)) {
      score += 2;
    }
    
    return score;
  }
  
  // Collaborative filtering score
  static async getCollaborativeScore(tweet, userId, similarUsers) {
    let score = 0;
    
    // Check if similar users liked this tweet
    const similarUserLikes = tweet.likedBy.filter(user => similarUsers.includes(user));
    score += similarUserLikes.length * 1.5;
    
    // Check if similar users retweeted this tweet
    const similarUserRetweets = tweet.retweetedBy.filter(user => similarUsers.includes(user));
    score += similarUserRetweets.length * 2;
    
    return score;
  }
  
  // Time decay factor
  static getTimeDecayFactor(tweetDate) {
    const hoursOld = (Date.now() - tweetDate.getTime()) / (1000 * 60 * 60);
    return Math.exp(-hoursOld / 24); // Decay over 24 hours
  }
  
  // Quality score based on engagement
  static getQualityScore(tweet) {
    const engagementRate = (tweet.likesCount + tweet.retweetsCount + tweet.repliesCount) / 
                          Math.max(tweet.viewsCount, 1);
    return Math.min(engagementRate * 10, 5); // Cap at 5
  }
}

// Get personalized tweet recommendations
router.get('/tweets', auth, async (req, res) => {
  try {
    const userId = req.user.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    
    // Get user profile for recommendations
    const user = await User.findOne({ id: userId });
    const following = user.following || [];
    
    // Get user's interaction history
    const userTweets = await Tweet.find({ userId }).limit(100);
    const userHashtags = [...new Set(userTweets.flatMap(t => t.hashtags))];
    const userInteractions = await Tweet.find({ 
      $or: [
        { likedBy: userId },
        { retweetedBy: userId }
      ]
    }).limit(100);
    
    const interactedUsers = [...new Set(userInteractions.map(t => t.userId))];
    const userCommunities = await Community.find({ members: userId }).select('id');
    
    const userProfile = {
      favoriteHashtags: userHashtags.slice(0, 10),
      communities: userCommunities.map(c => c.id),
      interactedUsers: interactedUsers.slice(0, 20)
    };
    
    // Find similar users
    const allUsers = await User.find({ 
      id: { $ne: userId, $in: [...following, ...interactedUsers] }
    }).limit(50);
    
    const similarUsers = [];
    for (const otherUser of allUsers) {
      const similarity = await RecommendationEngine.calculateUserSimilarity(userId, otherUser.id);
      if (similarity > 0.1) {
        similarUsers.push(otherUser.id);
      }
    }
    
    // Get candidate tweets (excluding user's own tweets and already seen)
    const candidateTweets = await Tweet.find({
      userId: { $ne: userId },
      isDeleted: { $ne: true },
      createdAt: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }, // Last 7 days
      $and: [
        { likedBy: { $ne: userId } },
        { retweetedBy: { $ne: userId } }
      ]
    })
    .populate('userId', 'id username displayName profileImageUrl isVerified')
    .limit(200); // Get more candidates to score
    
    // Score each tweet
    const scoredTweets = [];
    for (const tweet of candidateTweets) {
      let totalScore = 0;
      
      // Base engagement score
      totalScore += tweet.engagementScore * 0.3;
      
      // Content-based score
      const contentScore = await RecommendationEngine.getContentScore(tweet, userProfile);
      totalScore += contentScore * 0.4;
      
      // Collaborative filtering score
      const collaborativeScore = await RecommendationEngine.getCollaborativeScore(tweet, userId, similarUsers);
      totalScore += collaborativeScore * 0.2;
      
      // Time decay
      const timeDecay = RecommendationEngine.getTimeDecayFactor(tweet.createdAt);
      totalScore *= timeDecay;
      
      // Quality score
      const qualityScore = RecommendationEngine.getQualityScore(tweet);
      totalScore += qualityScore * 0.1;
      
      // Boost if from followed users
      if (following.includes(tweet.userId)) {
        totalScore *= 1.2;
      }
      
      scoredTweets.push({
        tweet,
        score: totalScore
      });
    }
    
    // Sort by score and paginate
    scoredTweets.sort((a, b) => b.score - a.score);
    const skip = (page - 1) * limit;
    const paginatedTweets = scoredTweets.slice(skip, skip + limit);
    
    const recommendations = paginatedTweets.map(item => item.tweet);

    res.status(200).json({
      status: 'success',
      tweets: recommendations,
      pagination: {
        page,
        limit,
        hasMore: scoredTweets.length > skip + limit
      },
      metadata: {
        totalCandidates: candidateTweets.length,
        similarUsers: similarUsers.length,
        userHashtags: userHashtags.length
      }
    });

  } catch (error) {
    console.error('Get tweet recommendations error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get tweet recommendations'
    });
  }
});

// Get user recommendations (who to follow)
router.get('/users', auth, async (req, res) => {
  try {
    const userId = req.user.id;
    const limit = parseInt(req.query.limit) || 10;
    
    const user = await User.findOne({ id: userId });
    const following = user.following || [];
    
    // Get users followed by people you follow (friends of friends)
    const friendsOfFriends = await User.find({
      id: { $in: following }
    }).select('following');
    
    const suggestedUserIds = new Set();
    friendsOfFriends.forEach(friend => {
      friend.following.forEach(friendFollowing => {
        if (friendFollowing !== userId && !following.includes(friendFollowing)) {
          suggestedUserIds.add(friendFollowing);
        }
      });
    });
    
    // Get users with similar interests (based on hashtags)
    const userTweets = await Tweet.find({ userId }).select('hashtags').limit(50);
    const userHashtags = [...new Set(userTweets.flatMap(t => t.hashtags))];
    
    if (userHashtags.length > 0) {
      const similarContentUsers = await Tweet.find({
        hashtags: { $in: userHashtags },
        userId: { $ne: userId, $nin: following }
      }).distinct('userId');
      
      similarContentUsers.forEach(uid => suggestedUserIds.add(uid));
    }
    
    // Get popular users in followed communities
    const userCommunities = await Community.find({ members: userId }).select('members');
    const communityMembers = new Set();
    userCommunities.forEach(community => {
      community.members.forEach(member => {
        if (member !== userId && !following.includes(member)) {
          communityMembers.add(member);
        }
      });
    });
    
    communityMembers.forEach(uid => suggestedUserIds.add(uid));
    
    // Get user details and calculate scores
    const candidates = await User.find({
      id: { $in: Array.from(suggestedUserIds) }
    }).select('id username displayName profileImageUrl isVerified followersCount tweetsCount bio')
    .limit(50);
    
    // Score candidates
    const scoredUsers = candidates.map(candidate => {
      let score = 0;
      
      // Follower count (log scale to prevent bias toward mega-accounts)
      score += Math.log10(candidate.followersCount + 1) * 2;
      
      // Verification bonus
      if (candidate.isVerified) score += 3;
      
      // Activity level
      score += Math.min(candidate.tweetsCount / 100, 5);
      
      // Complete profile bonus
      if (candidate.bio) score += 1;
      if (candidate.profileImageUrl) score += 1;
      
      return { user: candidate, score };
    });
    
    // Sort by score and limit
    scoredUsers.sort((a, b) => b.score - a.score);
    const recommendations = scoredUsers.slice(0, limit).map(item => item.user);

    res.status(200).json({
      status: 'success',
      users: recommendations,
      metadata: {
        totalCandidates: candidates.length,
        basedOnFollowing: friendsOfFriends.length,
        basedOnHashtags: userHashtags.length,
        basedOnCommunities: userCommunities.length
      }
    });

  } catch (error) {
    console.error('Get user recommendations error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get user recommendations'
    });
  }
});

// Get community recommendations
router.get('/communities', auth, async (req, res) => {
  try {
    const userId = req.user.id;
    const limit = parseInt(req.query.limit) || 10;
    
    const user = await User.findOne({ id: userId });
    const userCommunities = await Community.find({ members: userId }).select('id category tags');
    const joinedCommunityIds = userCommunities.map(c => c.id);
    
    // Get user's interest categories
    const userCategories = [...new Set(userCommunities.map(c => c.category))];
    const userTags = [...new Set(userCommunities.flatMap(c => c.tags))];
    
    // Get hashtags from user's tweets
    const userTweets = await Tweet.find({ userId }).select('hashtags').limit(50);
    const userHashtags = [...new Set(userTweets.flatMap(t => t.hashtags))];
    
    // Find candidate communities
    const candidates = await Community.find({
      id: { $nin: joinedCommunityIds },
      isActive: true,
      $or: [
        { category: { $in: userCategories } },
        { tags: { $in: [...userTags, ...userHashtags] } }
      ]
    })
    .populate('creatorId', 'id username displayName isVerified')
    .limit(50);
    
    // Score communities
    const scoredCommunities = candidates.map(community => {
      let score = 0;
      
      // Category match
      if (userCategories.includes(community.category)) {
        score += 5;
      }
      
      // Tag/hashtag overlap
      const tagOverlap = community.tags.filter(tag => 
        userTags.includes(tag) || userHashtags.includes(tag)
      ).length;
      score += tagOverlap * 2;
      
      // Member count (log scale)
      score += Math.log10(community.membersCount + 1);
      
      // Activity level (recent tweets)
      score += Math.min(community.tweetsCount / 10, 3);
      
      // Creator verification bonus
      if (community.creatorId?.isVerified) {
        score += 1;
      }
      
      return { community, score };
    });
    
    // Sort by score and limit
    scoredCommunities.sort((a, b) => b.score - a.score);
    const recommendations = scoredCommunities.slice(0, limit).map(item => item.community);

    res.status(200).json({
      status: 'success',
      communities: recommendations,
      metadata: {
        totalCandidates: candidates.length,
        userCategories,
        userTags: userTags.slice(0, 5),
        userHashtags: userHashtags.slice(0, 5)
      }
    });

  } catch (error) {
    console.error('Get community recommendations error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get community recommendations'
    });
  }
});

// Get trending content
router.get('/trending', optionalAuth, async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 20;
    const timeframe = parseInt(req.query.timeframe) || 24; // hours
    
    const cutoffDate = new Date(Date.now() - timeframe * 60 * 60 * 1000);
    
    // Get trending tweets
    const trendingTweets = await Tweet.find({
      createdAt: { $gte: cutoffDate },
      isDeleted: { $ne: true }
    })
    .populate('userId', 'id username displayName profileImageUrl isVerified')
    .sort({ engagementScore: -1, likesCount: -1, retweetsCount: -1 })
    .limit(limit);
    
    // Get trending hashtags
    const trendingHashtags = await Tweet.getTrendingHashtags(10, timeframe);
    
    // Get trending users (most followed recently)
    const trendingUsers = await User.find({})
      .select('id username displayName profileImageUrl isVerified followersCount')
      .sort({ followersCount: -1 })
      .limit(10);

    res.status(200).json({
      status: 'success',
      trending: {
        tweets: trendingTweets,
        hashtags: trendingHashtags,
        users: trendingUsers
      },
      timeframe: `${timeframe} hours`
    });

  } catch (error) {
    console.error('Get trending content error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get trending content'
    });
  }
});

module.exports = router;