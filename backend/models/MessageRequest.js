const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const messageRequestSchema = new mongoose.Schema({
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
  receiverId: {
    type: String,
    required: [true, 'Receiver ID is required'],
    ref: 'User'
  },
  conversationId: {
    type: String,
    required: [true, 'Conversation ID is required'],
    ref: 'Conversation'
  },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'declined'],
    default: 'pending'
  },
  firstMessageId: {
    type: String,
    ref: 'Message',
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  respondedAt: {
    type: Date
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
messageRequestSchema.index({ receiverId: 1, status: 1 });
messageRequestSchema.index({ senderId: 1 });
messageRequestSchema.index({ createdAt: -1 });

// Virtual for sender info
messageRequestSchema.virtual('sender', {
  ref: 'User',
  localField: 'senderId',
  foreignField: '_id',
  justOne: true
});

// Virtual for receiver info
messageRequestSchema.virtual('receiver', {
  ref: 'User',
  localField: 'receiverId',
  foreignField: '_id',
  justOne: true
});

// Virtual for first message
messageRequestSchema.virtual('firstMessage', {
  ref: 'Message',
  localField: 'firstMessageId',
  foreignField: '_id',
  justOne: true
});

// Virtual for conversation
messageRequestSchema.virtual('conversation', {
  ref: 'Conversation',
  localField: 'conversationId',
  foreignField: '_id',
  justOne: true
});

// Instance method to accept request
messageRequestSchema.methods.accept = async function() {
  this.status = 'accepted';
  this.respondedAt = new Date();
  
  // Make conversation visible to receiver
  const { Conversation } = require('./Message');
  await Conversation.findByIdAndUpdate(this.conversationId, {
    isRequestAccepted: true
  });
  
  return this.save();
};

// Instance method to decline request
messageRequestSchema.methods.decline = async function() {
  this.status = 'declined';
  this.respondedAt = new Date();
  return this.save();
};

module.exports = mongoose.model('MessageRequest', messageRequestSchema);