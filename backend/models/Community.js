const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const communitySchema = new mongoose.Schema({
  _id: {
    type: String,
    default: uuidv4,
    required: true
  },
  name: {
    type: String,
    required: [true, 'Community name is required'],
    trim: true,
    maxlength: [50, 'Community name cannot exceed 50 characters'],
    unique: true
  },
  description: {
    type: String,
    required: [true, 'Community description is required'],
    maxlength: [500, 'Description cannot exceed 500 characters']
  },
  bannerImageUrl: {
    type: String
  },
  profileImageUrl: {
    type: String
  },
  creatorId: {
    type: String,
    required: [true, 'Creator ID is required'],
    ref: 'User'
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  membersCount: {
    type: Number,
    default: 1,
    min: 0
  },
  members: [{
    type: String,
    ref: 'User'
  }],
  moderators: [{
    type: String,
    ref: 'User'
  }],
  rules: [{
    type: String,
    maxlength: [200, 'Rule cannot exceed 200 characters']
  }],
  category: {
    type: String,
    required: [true, 'Category is required'],
    enum: ['Technology', 'Design', 'Business', 'Entertainment', 'Sports', 'Gaming', 'Art', 'Music', 'Other']
  },
  tags: [{
    type: String,
    lowercase: true,
    maxlength: [20, 'Tag cannot exceed 20 characters']
  }],
  isPrivate: {
    type: Boolean,
    default: false
  },
  isActive: {
    type: Boolean,
    default: true
  },
  tweetsCount: {
    type: Number,
    default: 0,
    min: 0
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
communitySchema.index({ name: 1 });
communitySchema.index({ category: 1 });
communitySchema.index({ tags: 1 });
communitySchema.index({ createdAt: -1 });
communitySchema.index({ membersCount: -1 });

// Virtual for creator info
communitySchema.virtual('creator', {
  ref: 'User',
  localField: 'creatorId',
  foreignField: '_id',
  justOne: true
});

// Instance methods
communitySchema.methods.addMember = function(userId) {
  if (!this.members.includes(userId)) {
    this.members.push(userId);
    this.membersCount = this.members.length;
  }
  return this.save();
};

communitySchema.methods.removeMember = function(userId) {
  this.members = this.members.filter(id => id !== userId);
  this.membersCount = this.members.length;
  return this.save();
};

communitySchema.methods.addModerator = function(userId) {
  if (!this.moderators.includes(userId)) {
    this.moderators.push(userId);
  }
  return this.save();
};

module.exports = mongoose.model('Community', communitySchema);