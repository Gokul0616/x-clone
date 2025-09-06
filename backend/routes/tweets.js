const express = require('express');
const Tweet = require('../models/Tweet');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { auth, optionalAuth } = require('../middleware/auth');
const router = express.Router();

// Get timeline (home feed)
router.get('/timeline', optionalAuth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    let query = { isDeleted: { $ne: true } };
    
    // If user is authenticated, show personalized timeline
    if (req.user) {
      const user = await User.findOne({ id: req.user.id });
      const followingUsers = user.following || [];
      
      query = {
        $or: [
          { userId: { $in: [req.user.id, ...followingUsers] } },
          { mentions: req.user.username }
        ],
        isDeleted: { $ne: true }
      };
    }

    const tweets = await Tweet.find(query)
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
      })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    // Update engagement scores periodically
    tweets.forEach(tweet => {
      if (tweet.lastEngagement < new Date(Date.now() - 60 * 60 * 1000)) { // 1 hour
        tweet.updateEngagementScore();
      }
    });

    res.status(200).json({
      status: 'success',
      tweets,
      pagination: {
        page,
        limit,
        hasMore: tweets.length === limit
      }
    });

  } catch (error) {
    console.error('Get timeline error:', error);
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
      const parentTweet = await Tweet.findOne({ id: replyToTweetId });
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
      const quotedTweet = await Tweet.findOne({ id: quotedTweetId });
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
        { id: replyToTweetId },
        { $inc: { repliesCount: 1 } }
      );

      // Create notification for reply
      await Notification.createNotification({
        userId: tweetData.replyToUserId,
        type: 'reply',
        fromUserId: req.user.id,
        tweetId: tweet.id
      });
    }

    // Update quoted tweet count
    if (quotedTweetId) {
      await Tweet.findOneAndUpdate(
        { id: quotedTweetId },
        { $inc: { quoteTweetsCount: 1 } }
      );

      // Create notification for quote tweet
      const quotedTweet = await Tweet.findOne({ id: quotedTweetId });
      await Notification.createNotification({
        userId: quotedTweet.userId,
        type: 'quote',
        fromUserId: req.user.id,
        tweetId: tweet.id
      });
    }

    // Update user tweet count
    await User.findOneAndUpdate(
      { id: req.user.id },
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

    const tweet = await Tweet.findOne({ id: tweetId });
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

    const tweet = await Tweet.findOne({ id: tweetId });
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