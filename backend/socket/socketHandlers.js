const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Message = require('../models/Message');
const { Conversation } = require('../models/Message');
const Notification = require('../models/Notification');

// Store active socket connections
const activeConnections = new Map();

// Socket authentication middleware
const authenticateSocket = async (socket, next) => {
  try {
    const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return next(new Error('Authentication error: No token provided'));
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findOne({ id: decoded.id }).select('-password');
    
    if (!user) {
      return next(new Error('Authentication error: User not found'));
    }

    socket.userId = user.id;
    socket.user = user;
    next();
  } catch (error) {
    next(new Error('Authentication error: Invalid token'));
  }
};

// Main socket handler
const socketHandlers = (io, socket) => {
  console.log(`User ${socket.userId} connected via socket`);
  
  // Store the connection
  activeConnections.set(socket.userId, socket);
  
  // Join user to their personal room
  socket.join(`user_${socket.userId}`);
  
  // Update user online status
  updateUserOnlineStatus(socket.userId, true);
  
  // Handle joining conversation rooms
  socket.on('join_conversation', async (data) => {
    try {
      const { conversationId } = data;
      
      // Verify user is part of this conversation
      const conversation = await Conversation.findOne({
        id: conversationId,
        participants: socket.userId
      });
      
      if (conversation) {
        socket.join(`conversation_${conversationId}`);
        console.log(`User ${socket.userId} joined conversation ${conversationId}`);
        
        // Notify other participants that user is online in this conversation
        socket.to(`conversation_${conversationId}`).emit('user_joined_conversation', {
          userId: socket.userId,
          username: socket.user.username,
          conversationId
        });
      }
    } catch (error) {
      console.error('Error joining conversation:', error);
      socket.emit('error', { message: 'Failed to join conversation' });
    }
  });
  
  // Handle leaving conversation rooms
  socket.on('leave_conversation', (data) => {
    try {
      const { conversationId } = data;
      socket.leave(`conversation_${conversationId}`);
      
      // Notify other participants
      socket.to(`conversation_${conversationId}`).emit('user_left_conversation', {
        userId: socket.userId,
        username: socket.user.username,
        conversationId
      });
    } catch (error) {
      console.error('Error leaving conversation:', error);
    }
  });
  
  // Handle real-time messaging
  socket.on('send_message', async (data) => {
    try {
      const { conversationId, content, messageType = 'text', attachments = [], replyToMessageId } = data;
      
      // Verify user is part of this conversation
      const conversation = await Conversation.findOne({
        id: conversationId,
        participants: socket.userId
      });
      
      if (!conversation) {
        return socket.emit('error', { message: 'Conversation not found' });
      }
      
      // Create message
      const message = new Message({
        senderId: socket.userId,
        conversationId,
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
      
      // Update unread counts for other participants
      conversation.participants.forEach(participantId => {
        if (participantId !== socket.userId) {
          const unreadIndex = conversation.unreadCounts.findIndex(uc => uc.userId === participantId);
          if (unreadIndex > -1) {
            conversation.unreadCounts[unreadIndex].count += 1;
          } else {
            conversation.unreadCounts.push({ userId: participantId, count: 1 });
          }
        }
      });
      
      await conversation.save();
      
      // Emit to all participants in the conversation
      io.to(`conversation_${conversationId}`).emit('new_message', {
        message,
        conversationId
      });
      
      // Send push notification to offline users
      const offlineParticipants = conversation.participants.filter(id => 
        id !== socket.userId && !activeConnections.has(id)
      );
      
      for (const participantId of offlineParticipants) {
        await Notification.createNotification({
          userId: participantId,
          type: 'message',
          fromUserId: socket.userId,
          messageId: message.id,
          content: content.substring(0, 100)
        });
        
        // Emit to user's personal room (in case they're connected but not in conversation room)
        io.to(`user_${participantId}`).emit('new_notification', {
          type: 'message',
          from: socket.user.username,
          content: content.substring(0, 50) + '...'
        });
      }
      
    } catch (error) {
      console.error('Error sending message:', error);
      socket.emit('error', { message: 'Failed to send message' });
    }
  });
  
  // Handle typing indicators
  socket.on('typing_start', (data) => {
    const { conversationId } = data;
    socket.to(`conversation_${conversationId}`).emit('user_typing', {
      userId: socket.userId,
      username: socket.user.username,
      conversationId
    });
  });
  
  socket.on('typing_stop', (data) => {
    const { conversationId } = data;
    socket.to(`conversation_${conversationId}`).emit('user_stopped_typing', {
      userId: socket.userId,
      username: socket.user.username,
      conversationId
    });
  });
  
  // Handle message read receipts
  socket.on('mark_messages_read', async (data) => {
    try {
      const { conversationId } = data;
      
      // Mark messages as read
      await Message.updateMany(
        {
          conversationId,
          senderId: { $ne: socket.userId },
          isRead: false
        },
        {
          isRead: true,
          readAt: new Date()
        }
      );
      
      // Update conversation unread count
      const conversation = await Conversation.findOne({ id: conversationId });
      if (conversation) {
        await conversation.markAsRead(socket.userId);
        
        // Notify other participants about read receipts
        socket.to(`conversation_${conversationId}`).emit('messages_read', {
          userId: socket.userId,
          conversationId,
          readAt: new Date()
        });
      }
      
    } catch (error) {
      console.error('Error marking messages as read:', error);
      socket.emit('error', { message: 'Failed to mark messages as read' });
    }
  });
  
  // Handle live tweet engagement updates
  socket.on('tweet_engagement', (data) => {
    const { tweetId, action, isEngaged } = data; // action: 'like', 'retweet', 'reply'
    
    // Broadcast engagement update to all connected users
    socket.broadcast.emit('tweet_engagement_update', {
      tweetId,
      action,
      isEngaged,
      userId: socket.userId
    });
  });
  
  // Handle live notifications
  socket.on('request_notifications', async () => {
    try {
      const unreadCount = await Notification.countDocuments({
        userId: socket.userId,
        isRead: false
      });
      
      socket.emit('notification_count', { unreadCount });
    } catch (error) {
      console.error('Error getting notifications:', error);
    }
  });
  
  // Handle disconnection
  socket.on('disconnect', (reason) => {
    console.log(`User ${socket.userId} disconnected: ${reason}`);
    
    // Remove from active connections
    activeConnections.delete(socket.userId);
    
    // Update user offline status (with a delay to handle reconnections)
    setTimeout(() => {
      if (!activeConnections.has(socket.userId)) {
        updateUserOnlineStatus(socket.userId, false);
      }
    }, 5000); // 5 second delay
    
    // Notify all conversation rooms about user going offline
    socket.rooms.forEach(room => {
      if (room.startsWith('conversation_')) {
        socket.to(room).emit('user_went_offline', {
          userId: socket.userId,
          username: socket.user.username
        });
      }
    });
  });
  
  // Handle connection errors
  socket.on('error', (error) => {
    console.error(`Socket error for user ${socket.userId}:`, error);
  });
};

// Helper function to update user online status
const updateUserOnlineStatus = async (userId, isOnline) => {
  try {
    await User.findOneAndUpdate(
      { id: userId },
      {
        isOnline,
        lastActive: new Date()
      }
    );
  } catch (error) {
    console.error('Error updating user online status:', error);
  }
};

// Function to send notification to user if they're connected
const sendNotificationToUser = (io, userId, notification) => {
  if (activeConnections.has(userId)) {
    io.to(`user_${userId}`).emit('new_notification', notification);
  }
};

// Function to broadcast to all connected users
const broadcastToAll = (io, event, data) => {
  io.emit(event, data);
};

// Function to get active user count
const getActiveUserCount = () => {
  return activeConnections.size;
};

// Function to get active users list
const getActiveUsers = () => {
  return Array.from(activeConnections.keys());
};

module.exports = (io, socket) => {
  // Apply authentication middleware
  socket.use((packet, next) => {
    if (packet[0] === 'authenticate') {
      return authenticateSocket(socket, next);
    }
    next();
  });
  
  // Set up socket handlers
  socketHandlers(io, socket);

  // Store io instance for use in routes
  socket.app?.set('socketio', io);
};

// Export helper functions
module.exports.sendNotificationToUser = sendNotificationToUser;
module.exports.broadcastToAll = broadcastToAll;
module.exports.getActiveUserCount = getActiveUserCount;
module.exports.getActiveUsers = getActiveUsers;