const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const messageSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: uuidv4,
    required: true
  },
  senderId: {
    type: String,
    required: [true, 'Sender ID is required'],
    ref: 'User'
  },
  conversationId: {
    type: String,
    required: [true, 'Conversation ID is required'],
    ref: 'Conversation'
  },
  content: {
    type: String,
    required: [true, 'Message content is required'],
    maxlength: [1000, 'Message cannot exceed 1000 characters'],
    trim: true
  },
  messageType: {
    type: String,
    enum: ['text', 'image', 'video', 'file'],
    default: 'text'
  },
  attachments: [{
    type: {
      type: String,
      enum: ['image', 'video', 'file']
    },
    url: String,
    filename: String,
    size: Number
  }],
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
  },
  isEdited: {
    type: Boolean,
    default: false
  },
  editedAt: {
    type: Date
  },
  isDeleted: {
    type: Boolean,
    default: false
  },
  deletedAt: {
    type: Date
  },
  replyToMessageId: {
    type: String,
    ref: 'Message'
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
messageSchema.index({ conversationId: 1, createdAt: -1 });
messageSchema.index({ senderId: 1 });
messageSchema.index({ createdAt: -1 });

// Virtual for sender info
messageSchema.virtual('sender', {
  ref: 'User',
  localField: 'senderId',
  foreignField: '_id',
  justOne: true
});

module.exports = mongoose.model('Message', messageSchema);

// Conversation Schema
const conversationSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: uuidv4,
    required: true
  },
  participants: [{
    type: String,
    ref: 'User',
    required: true
  }],
  lastMessageId: {
    type: String,
    ref: 'Message'
  },
  lastActivity: {
    type: Date,
    default: Date.now
  },
  unreadCounts: [{
    userId: {
      type: String,
      ref: 'User'
    },
    count: {
      type: Number,
      default: 0
    }
  }],
  isGroup: {
    type: Boolean,
    default: false
  },
  groupName: {
    type: String,
    maxlength: [50, 'Group name cannot exceed 50 characters']
  },
  groupImage: {
    type: String
  },
  // New field for message requests
  isRequestAccepted: {
    type: Boolean,
    default: true // true for normal conversations, false for pending requests
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for conversations
conversationSchema.index({ participants: 1 });
conversationSchema.index({ lastActivity: -1 });
conversationSchema.index({ isRequestAccepted: 1 });

// Virtual for participant users
conversationSchema.virtual('participantUsers', {
  ref: 'User',
  localField: 'participants',
  foreignField: '_id'
});

// Virtual for last message
conversationSchema.virtual('lastMessage', {
  ref: 'Message',
  localField: 'lastMessageId',
  foreignField: '_id',
  justOne: true
});

// Instance method to get unread count for a user
conversationSchema.methods.getUnreadCount = function(userId) {
  const userUnread = this.unreadCounts.find(uc => uc.userId === userId);
  return userUnread ? userUnread.count : 0;
};

// Instance method to mark as read for a user
conversationSchema.methods.markAsRead = function(userId) {
  const userUnreadIndex = this.unreadCounts.findIndex(uc => uc.userId === userId);
  if (userUnreadIndex > -1) {
    this.unreadCounts[userUnreadIndex].count = 0;
  }
  return this.save();
};

// Static method to check if users are mutually following
conversationSchema.statics.areUsersMutuallyFollowing = async function(userId1, userId2) {
  const User = require('./User');
  
  const user1 = await User.findOne({ id: userId1 });
  const user2 = await User.findOne({ id: userId2 });
  
  if (!user1 || !user2) return false;
  
  const user1FollowsUser2 = user1.following.includes(userId2);
  const user2FollowsUser1 = user2.following.includes(userId1);
  
  return user1FollowsUser2 && user2FollowsUser1;
};

module.exports.Conversation = mongoose.model('Conversation', conversationSchema);