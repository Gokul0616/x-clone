const express = require('express');
const Notification = require('../models/Notification');
const { auth } = require('../middleware/auth');
const router = express.Router();

// Get user's notifications
router.get('/', auth, async (req, res) => {
  try {
    const userId = req.user.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const type = req.query.type; // Filter by notification type
    const skip = (page - 1) * limit;

    let query = { userId };
    if (type) {
      query.type = type;
    }

    const notifications = await Notification.find(query)
      .populate('fromUserId', 'id username displayName profileImageUrl isVerified')
      .populate({
        path: 'tweetId',
        populate: {
          path: 'userId',
          select: 'id username displayName profileImageUrl isVerified'
        }
      })
      .populate('communityId', 'id name profileImageUrl')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    res.status(200).json({
      status: 'success',
      notifications,
      pagination: {
        page,
        limit,
        hasMore: notifications.length === limit
      }
    });

  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get notifications'
    });
  }
});

// Get unread notification count
router.get('/unread-count', auth, async (req, res) => {
  try {
    const userId = req.user.id;

    const unreadCount = await Notification.countDocuments({
      userId,
      isRead: false
    });

    res.status(200).json({
      status: 'success',
      unreadCount
    });

  } catch (error) {
    console.error('Get unread count error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get unread count'
    });
  }
});

// Mark notification as read
router.put('/:notificationId/read', auth, async (req, res) => {
  try {
    const { notificationId } = req.params;
    const userId = req.user.id;

    const notification = await Notification.findOne({
      id: notificationId,
      userId
    });

    if (!notification) {
      return res.status(404).json({
        status: 'error',
        message: 'Notification not found'
      });
    }

    if (!notification.isRead) {
      notification.isRead = true;
      notification.readAt = new Date();
      await notification.save();
    }

    res.status(200).json({
      status: 'success',
      message: 'Notification marked as read'
    });

  } catch (error) {
    console.error('Mark notification as read error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to mark notification as read'
    });
  }
});

// Mark all notifications as read
router.put('/read-all', auth, async (req, res) => {
  try {
    const userId = req.user.id;

    await Notification.markAllAsRead(userId);

    res.status(200).json({
      status: 'success',
      message: 'All notifications marked as read'
    });

  } catch (error) {
    console.error('Mark all as read error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to mark all notifications as read'
    });
  }
});

// Delete notification
router.delete('/:notificationId', auth, async (req, res) => {
  try {
    const { notificationId } = req.params;
    const userId = req.user.id;

    const result = await Notification.findOneAndDelete({
      id: notificationId,
      userId
    });

    if (!result) {
      return res.status(404).json({
        status: 'error',
        message: 'Notification not found'
      });
    }

    res.status(200).json({
      status: 'success',
      message: 'Notification deleted successfully'
    });

  } catch (error) {
    console.error('Delete notification error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to delete notification'
    });
  }
});

// Get notification settings/preferences
router.get('/settings', auth, async (req, res) => {
  try {
    const user = req.user;
    
    res.status(200).json({
      status: 'success',
      settings: user.preferences.notifications
    });

  } catch (error) {
    console.error('Get notification settings error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get notification settings'
    });
  }
});

// Update notification settings/preferences
router.put('/settings', auth, async (req, res) => {
  try {
    const userId = req.user.id;
    const { likes, retweets, mentions, follows, messages } = req.body;

    const updates = {};
    if (typeof likes === 'boolean') updates['preferences.notifications.likes'] = likes;
    if (typeof retweets === 'boolean') updates['preferences.notifications.retweets'] = retweets;
    if (typeof mentions === 'boolean') updates['preferences.notifications.mentions'] = mentions;
    if (typeof follows === 'boolean') updates['preferences.notifications.follows'] = follows;
    if (typeof messages === 'boolean') updates['preferences.notifications.messages'] = messages;

    const User = require('../models/User');
    const user = await User.findOneAndUpdate(
      { id: userId },
      updates,
      { new: true }
    );

    res.status(200).json({
      status: 'success',
      message: 'Notification settings updated successfully',
      settings: user.preferences.notifications
    });

  } catch (error) {
    console.error('Update notification settings error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to update notification settings'
    });
  }
});

module.exports = router;