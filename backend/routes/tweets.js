const express = require('express');
const Tweet = require('../models/Tweet');
const User = require('../models/User');
const Notification = require('../models/Notification');
const mongoose = require('mongoose');
const { auth, optionalAuth } = require('../middleware/auth');
const router = express.Router();

// Get timeline (home feed)
// router.get('/timeline', optionalAuth, async (req, res) => {
//   try {
//     const page = parseInt(req.query.page) || 1;
//     const limit = parseInt(req.query.limit) || 20;
//     const skip = (page - 1) * limit;

//     let query = { isDeleted: { $ne: true } };
//     // If user is authenticated, show personalized timeline
//     if (req.user) {
//       const user = await User.findOne({ _id: req.user._id });
//       const followingUsers = user.following || [];
//       query = {
//         $or: [
//           { userId: { $in: [req.user.id, ...followingUsers] } },
//           { mentions: req.user.username }
//         ],
//         isDeleted: { $ne: true }
//       };
//     }

//     const tweets = await Tweet.find(query)
//       .populate('userId', 'id username displayName profileImageUrl isVerified')
//       .populate('retweetedByUserId', 'id username displayName profileImageUrl isVerified')
//       .populate('replyToUserId', 'id username displayName profileImageUrl isVerified')
//       .populate({
//         path: 'originalTweetId',
//         populate: {
//           path: 'userId',
//           select: 'id username displayName profileImageUrl isVerified'
//         }
//       })
//       .populate({
//         path: 'quotedTweetId',
//         populate: {
//           path: 'userId',
//           select: 'id username displayName profileImageUrl isVerified'
//         }
//       })
//       .sort({ createdAt: -1 })
//       .skip(skip)
//       .limit(limit);

//     // Update engagement scores periodically
//     tweets.forEach(tweet => {
//       if (tweet.lastEngagement < new Date(Date.now() - 60 * 60 * 1000)) { // 1 hour
//         tweet.updateEngagementScore();
//       }
//     });

//     res.status(200).json({
//       status: 'success',
//       tweets,
//       pagination: {
//         page,
//         limit,
//         hasMore: tweets.length === limit
//       }
//     });

//   } catch (error) {
//     console.error('Get timeline error:', error);
//     res.status(500).json({
//       status: 'error',
//       message: 'Failed to get timeline'
//     });
//   }
// });

router.get('/timeline', optionalAuth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    let query = { isDeleted: { $ne: true } };
    let recommendedTweets = [];

    console.log('Getting timeline for user:', req.user ? req.user._id : 'anonymous');

    if (req.user && req.user._id) {
      // Find the authenticated user
      const user = await User.findById(req.user._id).select('following preferences username');
      console.log(user);
      if (!user) {
        return res.status(404).json({
          status: 'error',
          message: 'User not found'
        });
      }


      // Debug: Test query for user's own tweets
      // Add user's own tweets
      const ownTweets = await Tweet.find({
        userId: req.user._id, // User ID is already an ObjectId
        isDeleted: { $ne: true }
      })
        .populate('userId', '_id username displayName profileImageUrl isVerified')
        .sort({ createdAt: -1 })
        .limit(limit);

      // Get user's followed users
      const followingUsers = user.following || [];

      // Get user's interacted hashtags
      const userInteractions = await Notification.find({
        fromUserId: req.user._id, // Fix ObjectId
        type: { $in: ['like', 'retweet', 'reply'] }
      }).distinct('tweetId');

      const interactedHashtags = await Tweet.find({
        _id: { $in: userInteractions },
        hashtags: { $exists: true, $ne: [] }
      }).distinct('hashtags');

      // Get trending hashtags
      const trendingHashtags = await Tweet.getTrendingHashtags(10, 24);
      const trendingHashtagNames = trendingHashtags.map(trend => trend._id);

      // Collaborative filtering
      const similarUsers = await User.aggregate([
        {
          $match: {
            _id: { $ne: req.user._id }, // Fix ObjectId
            following: { $in: followingUsers }
          }
        },
        {
          $project: {
            _id: 1,
            commonFollows: {
              $size: { $setIntersection: ['$following', followingUsers] }
            }
          }
        },
        { $sort: { commonFollows: -1 } },
        { $limit: 10 }
      ]);
      const similarUserIds = similarUsers.map(user => user._id);

      // Build personalized query
      const orConditions = [
        { userId: req.user._id }, // User's own tweets
      ];
      if (followingUsers.length > 0) {
        orConditions.push({
          userId: { $in: followingUsers }
        });
      }
      if (user.username) {
        orConditions.push({ mentions: user.username });
      }
      if (interactedHashtags.length > 0) {
        orConditions.push({ hashtags: { $in: interactedHashtags } });
      }
      if (trendingHashtagNames.length > 0) {
        orConditions.push({ hashtags: { $in: trendingHashtagNames } });
      }
      if (similarUserIds.length > 0) {
        orConditions.push({
          userId: {
            $in: similarUserIds.map(id => id) // Fix ObjectId
          }
        });
      }

      query = {
        $or: orConditions,
        isDeleted: { $ne: true },
        ...(user.preferences?.language && { language: user.preferences.language })
      };

      // Fetch recommended tweets
      recommendedTweets = await Tweet.find(query)
        .populate('userId', '_id username displayName profileImageUrl isVerified')
        .populate('retweetedByUserId', '_id username displayName profileImageUrl isVerified')
        .populate('replyToUserId', '_id username displayName profileImageUrl isVerified')
        .populate({
          path: 'originalTweetId',
          populate: {
            path: 'userId',
            select: '_id username displayName profileImageUrl isVerified'
          }
        })
        .populate({
          path: 'quotedTweetId',
          populate: {
            path: 'userId',
            select: '_id username displayName profileImageUrl isVerified'
          }
        })
        .sort({ createdAt: -1, engagementScore: -1 })
        .skip(skip)
        .limit(limit);
      // Fallback if no tweets are found
      if (recommendedTweets.length === 0) {
        recommendedTweets = await Tweet.find({
          isDeleted: { $ne: true }
        })
          .populate('userId', '_id username displayName profileImageUrl isVerified')
          .sort({ createdAt: -1 })
          .limit(limit);
      }
    } else {
      // Non-authenticated users
      const trendingHashtags = await Tweet.getTrendingHashtags(10, 24);
      const trendingHashtagNames = trendingHashtags.map(trend => trend._id);

      query = {
        $or: [
          ...(trendingHashtagNames.length > 0 ? [{ hashtags: { $in: trendingHashtagNames } }] : []),
          { isVerified: true }
        ],
        isDeleted: { $ne: true }
      };

      recommendedTweets = await Tweet.find(query)
        .populate('userId', '_id username displayName profileImageUrl isVerified')
        .populate('retweetedByUserId', '_id username displayName profileImageUrl isVerified')
        .populate('replyToUserId', '_id username displayName profileImageUrl isVerified')
        .populate({
          path: 'originalTweetId',
          populate: {
            path: 'userId',
            select: '_id username displayName profileImageUrl isVerified'
          }
        })
        .populate({
          path: 'quotedTweetId',
          populate: {
            path: 'userId',
            select: '_id username displayName profileImageUrl isVerified'
          }
        })
        .sort({ createdAt: -1, engagementScore: -1 })
        .skip(skip)
        .limit(limit);

      // Fallback for non-authenticated users
      if (recommendedTweets.length === 0) {
        recommendedTweets = await Tweet.find({
          isDeleted: { $ne: true }
        })
          .populate('userId', '_id username displayName profileImageUrl isVerified')
          .sort({ createdAt: -1 })
          .limit(limit);
      }
    }


    // Update engagement scores
    recommendedTweets.forEach(tweet => {
      if (tweet.lastEngagement < new Date(Date.now() - 60 * 60 * 1000)) {
        tweet.updateEngagementScore();
      }
    });

    res.status(200).json({
      status: 'success',
      tweets: recommendedTweets,
      pagination: {
        page,
        limit,
        hasMore: recommendedTweets.length === limit
      }
    });
  } catch (error) {
    console.error('Timeline - Get timeline error:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get timeline'
    });
  }
});

// Create new tweet
router.post('/', auth, async (req, res) => {
  try {
    const { content, imageUrls, videoUrls, replyToTweetId, quotedTweetId, communityId } = req.body;
    console.log(req.body);
    if (!content || content.trim().length === 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Tweet content is required'
      });
    }

    const tweetData = {
      userId: req.user.id,
      content: content.trim(),
      imageUrls: imageUrls || [],
      videoUrls: videoUrls || [],
      communityId
    };

    // Handle reply
    if (replyToTweetId) {
      const parentTweet = await Tweet.findOne({ _id: replyToTweetId });
      if (!parentTweet) {
        return res.status(404).json({
          status: 'error',
          message: 'Parent tweet not found'
        });
      }
      tweetData.replyToTweetId = replyToTweetId;
      tweetData.replyToUserId = parentTweet.userId;
    }
    // Handle quote tweet
    if (quotedTweetId) {
      const quotedTweet = await Tweet.findOne({ _id: quotedTweetId });
      if (!quotedTweet) {
        return res.status(404).json({
          status: 'error',
          message: 'Quoted tweet not found'
        });
      }
      tweetData.isQuoteTweet = true;
      tweetData.quotedTweetId = quotedTweetId;
    }

    const tweet = new Tweet(tweetData);
    await tweet.save();

    // Update parent tweet reply count
    if (replyToTweetId) {
      await Tweet.findOneAndUpdate(
        { _id: replyToTweetId },
        { $inc: { repliesCount: 1 } }
      );

      // Create notification for reply
      await Notification.createNotification({
        userId: tweetData.replyToUserId,
        type: 'reply',
        fromUserId: req.user._id || req.user.id,
        tweetId: tweet.id || tweet._id
      });
    }

    // Update quoted tweet count
    if (quotedTweetId) {
      await Tweet.findOneAndUpdate(
        { _id: quotedTweetId },
        { $inc: { quoteTweetsCount: 1 } }
      );
      console.log(quotedTweetId, "parentTweet");

      // Create notification for quote tweet
      const quotedTweet = await Tweet.findOne({ _id: quotedTweetId });
      await Notification.createNotification({
        userId: quotedTweet.userId,
        type: 'quote',
        fromUserId: req.user.id || req.user._id,
        tweetId: tweet.id || tweet._id
      });
    }

    // Update user tweet count
    await User.findOneAndUpdate(
      { _id: req.user._id || req.user.id },
      { $inc: { tweetsCount: 1 } }
    );

    // Populate the response
    await tweet.populate('userId', 'id username displayName profileImageUrl isVerified');

    res.status(201).json({
      status: 'success',
      message: 'Tweet created successfully',
      tweet
    });

  } catch (error) {
    console.error('Create tweet error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to create tweet'
    });
  }
});

// Like/Unlike tweet
router.post('/:tweetId/like', auth, async (req, res) => {
  try {
    const { tweetId } = req.params;
    const userId = req.user.id;

    const tweet = await Tweet.findOne({ _id: tweetId });
    if (!tweet) {
      return res.status(404).json({
        status: 'error',
        message: 'Tweet not found'
      });
    }

    const isLiked = tweet.likedBy.includes(userId);

    if (isLiked) {
      // Unlike
      tweet.likedBy = tweet.likedBy.filter(id => id !== userId);
      tweet.likesCount = tweet.likedBy.length;
    } else {
      // Like
      tweet.likedBy.push(userId);
      tweet.likesCount = tweet.likedBy.length;

      // Create notification for like (but not for own tweets)
      if (tweet.userId !== userId) {
        await Notification.createNotification({
          userId: tweet.userId,
          type: 'like',
          fromUserId: userId,
          tweetId: tweet.id
        });
      }
    }

    await tweet.updateEngagementScore();

    res.status(200).json({
      status: 'success',
      message: isLiked ? 'Tweet unliked' : 'Tweet liked',
      isLiked: !isLiked,
      likesCount: tweet.likesCount
    });

  } catch (error) {
    console.error('Like tweet error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to like tweet'
    });
  }
});

// Retweet/Unretweet tweet
router.post('/:tweetId/retweet', auth, async (req, res) => {
  try {
    const { tweetId } = req.params;
    const userId = req.user.id;

    const tweet = await Tweet.findOne({ _id: tweetId });
    if (!tweet) {
      return res.status(404).json({
        status: 'error',
        message: 'Tweet not found'
      });
    }
    // Check if user is trying to retweet their own tweet
    if (tweet.userId === userId) {
      return res.status(400).json({
        status: 'error',
        message: 'Cannot retweet your own tweet'
      });
    }

    const isRetweeted = tweet.retweetedBy.includes(userId);

    if (isRetweeted) {
      // Unretweet
      tweet.retweetedBy = tweet.retweetedBy.filter(id => id !== userId);
      tweet.retweetsCount = tweet.retweetedBy.length;

      // Remove retweet from user's timeline
      await Tweet.findOneAndDelete({
        userId: userId,
        originalTweetId: tweetId,
        isRetweet: true
      });
    } else {
      // Retweet
      tweet.retweetedBy.push(userId);
      tweet.retweetsCount = tweet.retweetedBy.length;

      // Create retweet entry
      const retweet = new Tweet({
        userId: userId,
        content: tweet.content,
        imageUrls: tweet.imageUrls,
        videoUrls: tweet.videoUrls,
        isRetweet: true,
        originalTweetId: tweetId,
        retweetedByUserId: userId
      });
      await retweet.save();

      // Create notification for retweet
      await Notification.createNotification({
        userId: tweet.userId,
        type: 'retweet',
        fromUserId: userId,
        tweetId: tweet.id
      });
    }

    await tweet.updateEngagementScore();

    res.status(200).json({
      status: 'success',
      message: isRetweeted ? 'Tweet unretweeted' : 'Tweet retweeted',
      isRetweeted: !isRetweeted,
      retweetsCount: tweet.retweetsCount
    });

  } catch (error) {
    console.error('Retweet error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to retweet'
    });
  }
});

// Get tweet replies
router.get('/:tweetId/replies', optionalAuth, async (req, res) => {
  try {
    const { tweetId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const replies = await Tweet.find({
      replyToTweetId: tweetId,
      isDeleted: { $ne: true }
    })
      .populate('userId', 'id username displayName profileImageUrl isVerified')
      .populate('replyToUserId', 'id username displayName profileImageUrl isVerified')
      .sort({ createdAt: 1 }) // Oldest first for replies
      .skip(skip)
      .limit(limit);

    res.status(200).json({
      status: 'success',
      replies,
      pagination: {
        page,
        limit,
        hasMore: replies.length === limit
      }
    });

  } catch (error) {
    console.error('Get replies error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get replies'
    });
  }
});

// Get single tweet by ID
router.get('/:tweetId', optionalAuth, async (req, res) => {
  try {
    const { tweetId } = req.params;

    const tweet = await Tweet.findOne({ id: tweetId, isDeleted: { $ne: true } })
      .populate('userId', 'id username displayName profileImageUrl isVerified')
      .populate('retweetedByUserId', 'id username displayName profileImageUrl isVerified')
      .populate('replyToUserId', 'id username displayName profileImageUrl isVerified')
      .populate({
        path: 'originalTweetId',
        populate: {
          path: 'userId',
          select: 'id username displayName profileImageUrl isVerified'
        }
      })
      .populate({
        path: 'quotedTweetId',
        populate: {
          path: 'userId',
          select: 'id username displayName profileImageUrl isVerified'
        }
      });

    if (!tweet) {
      return res.status(404).json({
        status: 'error',
        message: 'Tweet not found'
      });
    }

    // Track view if user is authenticated and it's not their own tweet
    if (req.user && tweet.userId !== req.user.id) {
      const alreadyViewed = tweet.viewedBy.some(view => view.userId === req.user.id);
      if (!alreadyViewed) {
        tweet.viewedBy.push({ userId: req.user.id });
        tweet.viewsCount = tweet.viewedBy.length;
        await tweet.updateEngagementScore();
      }
    }

    res.status(200).json({
      status: 'success',
      tweet
    });

  } catch (error) {
    console.error('Get tweet error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get tweet'
    });
  }
});

// Delete tweet
router.delete('/:tweetId', auth, async (req, res) => {
  try {
    const { tweetId } = req.params;

    const tweet = await Tweet.findOne({ id: tweetId });
    if (!tweet) {
      return res.status(404).json({
        status: 'error',
        message: 'Tweet not found'
      });
    }

    // Check if user owns the tweet
    if (tweet.userId !== req.user.id) {
      return res.status(403).json({
        status: 'error',
        message: 'You can only delete your own tweets'
      });
    }

    // Soft delete
    tweet.isDeleted = true;
    await tweet.save();

    // Update user tweet count
    await User.findOneAndUpdate(
      { id: req.user.id },
      { $inc: { tweetsCount: -1 } }
    );

    res.status(200).json({
      status: 'success',
      message: 'Tweet deleted successfully'
    });

  } catch (error) {
    console.error('Delete tweet error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to delete tweet'
    });
  }
});

// Get trending hashtags
router.get('/trends/hashtags', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    const timeframe = parseInt(req.query.timeframe) || 24; // hours

    const trends = await Tweet.getTrendingHashtags(limit, timeframe);

    res.status(200).json({
      status: 'success',
      trends
    });

  } catch (error) {
    console.error('Get trends error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get trends'
    });
  }
});

module.exports = router;