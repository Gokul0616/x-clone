const express = require('express');
const User = require('../models/User');
const Tweet = require('../models/Tweet');
const Notification = require('../models/Notification');
const { auth, optionalAuth } = require('../middleware/auth');
const router = express.Router();

// Get user by ID
router.get('/:userId', optionalAuth, async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findOne({ id: userId }).select('-password');
    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    res.status(200).json({
      status: 'success',
      user
    });

  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get user'
    });
  }
});

// Get user by username
router.get('/username/:username', optionalAuth, async (req, res) => {
  try {
    const { username } = req.params;

    const user = await User.findOne({ username }).select('-password');
    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    res.status(200).json({
      status: 'success',
      user
    });

  } catch (error) {
    console.error('Get user by username error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get user'
    });
  }
});

// Get user's tweets
router.get('/:userId/tweets', optionalAuth, async (req, res) => {
  try {
    const { userId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const user = await User.findOne({ id: userId });
    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    const tweets = await Tweet.find({
      userId: userId,
      isDeleted: { $ne: true }
    })
    .populate('userId', 'id username displayName profileImageUrl isVerified')
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
    console.error('Get user tweets error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get user tweets'
    });
  }
});

// Follow/Unfollow user
router.post('/:userId/follow', auth, async (req, res) => {
  try {
    const { userId } = req.params;
    const currentUserId = req.user.id;

    if (userId === currentUserId) {
      return res.status(400).json({
        status: 'error',
        message: 'You cannot follow yourself'
      });
    }

    const targetUser = await User.findOne({ id: userId });
    if (!targetUser) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    const currentUser = await User.findOne({ id: currentUserId });
    const isFollowing = currentUser.following.includes(userId);

    if (isFollowing) {
      // Unfollow
      currentUser.following = currentUser.following.filter(id => id !== userId);
      targetUser.followers = targetUser.followers.filter(id => id !== currentUserId);
      
      await currentUser.updateFollowingCount();
      await targetUser.updateFollowersCount();

      res.status(200).json({
        status: 'success',
        message: 'User unfollowed successfully',
        isFollowing: false
      });
    } else {
      // Follow
      currentUser.following.push(userId);
      targetUser.followers.push(currentUserId);
      
      await currentUser.updateFollowingCount();
      await targetUser.updateFollowersCount();

      // Create notification
      await Notification.createNotification({
        userId: userId,
        type: 'follow',
        fromUserId: currentUserId
      });

      res.status(200).json({
        status: 'success',
        message: 'User followed successfully',
        isFollowing: true
      });
    }

  } catch (error) {
    console.error('Follow user error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to follow/unfollow user'
    });
  }
});

// Get user's followers
router.get('/:userId/followers', optionalAuth, async (req, res) => {
  try {
    const { userId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const user = await User.findOne({ id: userId });
    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    const followers = await User.find({
      id: { $in: user.followers }
    })
    .select('id username displayName profileImageUrl isVerified followersCount')
    .skip(skip)
    .limit(limit);

    res.status(200).json({
      status: 'success',
      followers,
      pagination: {
        page,
        limit,
        hasMore: followers.length === limit
      }
    });

  } catch (error) {
    console.error('Get followers error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get followers'
    });
  }
});

// Get user's following
router.get('/:userId/following', optionalAuth, async (req, res) => {
  try {
    const { userId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const user = await User.findOne({ id: userId });
    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    const following = await User.find({
      id: { $in: user.following }
    })
    .select('id username displayName profileImageUrl isVerified followersCount')
    .skip(skip)
    .limit(limit);

    res.status(200).json({
      status: 'success',
      following,
      pagination: {
        page,
        limit,
        hasMore: following.length === limit
      }
    });

  } catch (error) {
    console.error('Get following error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get following'
    });
  }
});

// Get user's liked tweets
router.get('/:userId/likes', optionalAuth, async (req, res) => {
  try {
    const { userId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const user = await User.findOne({ id: userId });
    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    const likedTweets = await Tweet.find({
      likedBy: userId,
      isDeleted: { $ne: true }
    })
    .populate('userId', 'id username displayName profileImageUrl isVerified')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit);

    res.status(200).json({
      status: 'success',
      tweets: likedTweets,
      pagination: {
        page,
        limit,
        hasMore: likedTweets.length === limit
      }
    });

  } catch (error) {
    console.error('Get liked tweets error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get liked tweets'
    });
  }
});

// Block user
router.post('/:userId/block', auth, async (req, res) => {
  try {
    const { userId } = req.params;
    const currentUserId = req.user.id;

    if (userId === currentUserId) {
      return res.status(400).json({
        status: 'error',
        message: 'You cannot block yourself'
      });
    }

    const targetUser = await User.findOne({ id: userId });
    if (!targetUser) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    const currentUser = await User.findOne({ id: currentUserId });
    const isBlocked = currentUser.blockedUsers.includes(userId);

    if (isBlocked) {
      // Unblock
      currentUser.blockedUsers = currentUser.blockedUsers.filter(id => id !== userId);
      await currentUser.save();

      res.status(200).json({
        status: 'success',
        message: 'User unblocked successfully',
        isBlocked: false
      });
    } else {
      // Block
      currentUser.blockedUsers.push(userId);
      
      // Also unfollow each other if following
      currentUser.following = currentUser.following.filter(id => id !== userId);
      targetUser.followers = targetUser.followers.filter(id => id !== currentUserId);
      targetUser.following = targetUser.following.filter(id => id !== currentUserId);
      currentUser.followers = currentUser.followers.filter(id => id !== userId);

      await currentUser.save();
      await targetUser.save();

      res.status(200).json({
        status: 'success',
        message: 'User blocked successfully',
        isBlocked: true
      });
    }

  } catch (error) {
    console.error('Block user error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to block/unblock user'
    });
  }
});

// Update user preferences
router.put('/preferences', auth, async (req, res) => {
  try {
    const { theme, language, notifications } = req.body;
    const updates = {};

    if (theme) updates['preferences.theme'] = theme;
    if (language) updates['preferences.language'] = language;
    if (notifications) {
      Object.keys(notifications).forEach(key => {
        updates[`preferences.notifications.${key}`] = notifications[key];
      });
    }

    const user = await User.findOneAndUpdate(
      { id: req.user.id },
      updates,
      { new: true, runValidators: true }
    ).select('-password');

    res.status(200).json({
      status: 'success',
      message: 'Preferences updated successfully',
      user
    });

  } catch (error) {
    console.error('Update preferences error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to update preferences'
    });
  }
});

module.exports = router;