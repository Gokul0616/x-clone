const express = require('express');
const Message = require('../models/Message');
const { Conversation } = require('../models/Message');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { auth } = require('../middleware/auth');
const router = express.Router();

// Get user's conversations
router.get('/conversations', auth, async (req, res) => {
  try {
    const userId = req.user.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const conversations = await Conversation.find({
      participants: userId
    })
    .populate({
      path: 'participants',
      match: { id: { $ne: userId } },
      select: 'id username displayName profileImageUrl isVerified isOnline lastActive'
    })
    .populate({
      path: 'lastMessageId',
      populate: {
        path: 'senderId',
        select: 'id username displayName'
      }
    })
    .sort({ lastActivity: -1 })
    .skip(skip)
    .limit(limit);

    // Add unread count for current user
    const conversationsWithUnread = conversations.map(conv => {
      const convObj = conv.toObject();
      convObj.unreadCount = conv.getUnreadCount(userId);
      return convObj;
    });

    res.status(200).json({
      status: 'success',
      conversations: conversationsWithUnread,
      pagination: {
        page,
        limit,
        hasMore: conversations.length === limit
      }
    });

  } catch (error) {
    console.error('Get conversations error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get conversations'
    });
  }
});

// Get messages from a conversation
router.get('/conversations/:conversationId', auth, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const skip = (page - 1) * limit;

    // Check if user is part of this conversation
    const conversation = await Conversation.findOne({
      id: conversationId,
      participants: userId
    });

    if (!conversation) {
      return res.status(404).json({
        status: 'error',
        message: 'Conversation not found'
      });
    }

    const messages = await Message.find({
      conversationId: conversationId,
      isDeleted: { $ne: true }
    })
    .populate('senderId', 'id username displayName profileImageUrl')
    .populate('replyToMessageId', 'id content senderId')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit);

    // Mark messages as read
    await Message.updateMany(
      {
        conversationId: conversationId,
        senderId: { $ne: userId },
        isRead: false
      },
      {
        isRead: true,
        readAt: new Date()
      }
    );

    // Update conversation unread count
    await conversation.markAsRead(userId);

    res.status(200).json({
      status: 'success',
      messages: messages.reverse(), // Return in chronological order
      pagination: {
        page,
        limit,
        hasMore: messages.length === limit
      }
    });

  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get messages'
    });
  }
});

// Send a message
router.post('/', auth, async (req, res) => {
  try {
    const { receiverId, content, messageType = 'text', attachments = [], replyToMessageId } = req.body;
    const senderId = req.user.id;

    if (!receiverId || !content || content.trim().length === 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Receiver ID and content are required'
      });
    }

    // Check if receiver exists
    const receiver = await User.findOne({ id: receiverId });
    if (!receiver) {
      return res.status(404).json({
        status: 'error',
        message: 'Receiver not found'
      });
    }

    // Check if sender is blocked by receiver
    if (receiver.blockedUsers.includes(senderId)) {
      return res.status(403).json({
        status: 'error',
        message: 'You are blocked by this user'
      });
    }

    // Find or create conversation
    let conversation = await Conversation.findOne({
      participants: { $all: [senderId, receiverId] },
      isGroup: false
    });

    if (!conversation) {
      conversation = new Conversation({
        participants: [senderId, receiverId],
        unreadCounts: [
          { userId: senderId, count: 0 },
          { userId: receiverId, count: 1 }
        ]
      });
    } else {
      // Update unread count for receiver
      const receiverUnreadIndex = conversation.unreadCounts.findIndex(uc => uc.userId === receiverId);
      if (receiverUnreadIndex > -1) {
        conversation.unreadCounts[receiverUnreadIndex].count += 1;
      } else {
        conversation.unreadCounts.push({ userId: receiverId, count: 1 });
      }
    }

    // Create message
    const message = new Message({
      senderId,
      conversationId: conversation.id,
      content: content.trim(),
      messageType,
      attachments,
      replyToMessageId
    });

    await message.save();
    await message.populate('senderId', 'id username displayName profileImageUrl');

    // Update conversation
    conversation.lastMessageId = message.id;
    conversation.lastActivity = new Date();
    await conversation.save();

    // Create notification for receiver
    await Notification.createNotification({
      userId: receiverId,
      type: 'message',
      fromUserId: senderId,
      messageId: message.id,
      content: content.substring(0, 100)
    });

    // Emit real-time message via Socket.IO
    const io = req.app.get('socketio');
    if (io) {
      io.to(`user_${receiverId}`).emit('new_message', {
        message,
        conversation: conversation.id
      });
    }

    res.status(201).json({
      status: 'success',
      message: 'Message sent successfully',
      data: message
    });

  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to send message'
    });
  }
});

// Create group conversation
router.post('/conversations/group', auth, async (req, res) => {
  try {
    const { participants, groupName, groupImage } = req.body;
    const creatorId = req.user.id;

    if (!participants || participants.length < 2) {
      return res.status(400).json({
        status: 'error',
        message: 'At least 2 participants are required for a group'
      });
    }

    if (!groupName || groupName.trim().length === 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Group name is required'
      });
    }

    // Validate all participants exist
    const allParticipants = [creatorId, ...participants];
    const users = await User.find({ id: { $in: allParticipants } });
    
    if (users.length !== allParticipants.length) {
      return res.status(400).json({
        status: 'error',
        message: 'One or more participants not found'
      });
    }

    // Create group conversation
    const conversation = new Conversation({
      participants: allParticipants,
      isGroup: true,
      groupName: groupName.trim(),
      groupImage,
      unreadCounts: allParticipants.map(userId => ({ userId, count: 0 }))
    });

    await conversation.save();
    await conversation.populate('participants', 'id username displayName profileImageUrl');

    res.status(201).json({
      status: 'success',
      message: 'Group created successfully',
      conversation
    });

  } catch (error) {
    console.error('Create group error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to create group'
    });
  }
});

// Delete message
router.delete('/:messageId', auth, async (req, res) => {
  try {
    const { messageId } = req.params;
    const userId = req.user.id;

    const message = await Message.findOne({ id: messageId });
    if (!message) {
      return res.status(404).json({
        status: 'error',
        message: 'Message not found'
      });
    }

    // Check if user owns the message
    if (message.senderId !== userId) {
      return res.status(403).json({
        status: 'error',
        message: 'You can only delete your own messages'
      });
    }

    // Soft delete
    message.isDeleted = true;
    message.deletedAt = new Date();
    await message.save();

    res.status(200).json({
      status: 'success',
      message: 'Message deleted successfully'
    });

  } catch (error) {
    console.error('Delete message error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to delete message'
    });
  }
});

// Mark conversation as read
router.put('/conversations/:conversationId/read', auth, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user.id;

    const conversation = await Conversation.findOne({
      id: conversationId,
      participants: userId
    });

    if (!conversation) {
      return res.status(404).json({
        status: 'error',
        message: 'Conversation not found'
      });
    }

    // Mark all messages as read
    await Message.updateMany(
      {
        conversationId: conversationId,
        senderId: { $ne: userId },
        isRead: false
      },
      {
        isRead: true,
        readAt: new Date()
      }
    );

    // Update conversation unread count
    await conversation.markAsRead(userId);

    res.status(200).json({
      status: 'success',
      message: 'Conversation marked as read'
    });

  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to mark as read'
    });
  }
});

module.exports = router;