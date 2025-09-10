const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const notificationSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: uuidv4,
    required: true
  },
  userId: {
    type: String,
    required: [true, 'User ID is required'],
    ref: 'User'
  },
  type: {
    type: String,
    required: [true, 'Notification type is required'],
    enum: ['like', 'retweet', 'reply', 'mention', 'follow', 'unfollow', 'quote', 'message', 'community_invite', 'community_join', 'connection_request', 'connection_accept',]
  },
  fromUserId: {
    type: String,
    ref: 'User'
  },
  tweetId: {
    type: String,
    ref: 'Tweet'
  },
  communityId: {
    type: String,
    ref: 'Community'
  },
  messageId: {
    type: String,
    ref: 'Message'
  },
  content: {
    type: String,
    maxlength: [200, 'Notification content cannot exceed 200 characters']
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  isRead: {
    type: Boolean,
    default: false
  },
  readAt: {
    type: Date
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ type: 1 });
notificationSchema.index({ isRead: 1 });

// Virtual for from user info
notificationSchema.virtual('fromUser', {
  ref: 'User',
  localField: 'fromUserId',
  foreignField: '_id',
  justOne: true
});

// Virtual for tweet info
notificationSchema.virtual('tweet', {
  ref: 'Tweet',
  localField: 'tweetId',
  foreignField: '_id',
  justOne: true
});

// Virtual for community info
notificationSchema.virtual('community', {
  ref: 'Community',
  localField: 'communityId',
  foreignField: '_id',
  justOne: true
});

// Static method to create notification
notificationSchema.statics.createNotification = async function (notificationData) {
  try {
    const notification = new this({
      ...notificationData,
      _id: uuidv4(), // Ensure a unique ID
    });
    await notification.save();

    // Emit real-time notification via Socket.IO
    // This will be handled in the socket handlers
    return notification;
  } catch (error) {
    console.error('Error creating notification:', error);
    throw error;
  }
};

// Static method to mark all as read
notificationSchema.statics.markAllAsRead = function (userId) {
  return this.updateMany(
    { userId, isRead: false },
    { isRead: true, readAt: new Date() }
  );
};

module.exports = mongoose.model('Notification', notificationSchema);