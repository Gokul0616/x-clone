const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const validator = require('validator');

const userSchema = new mongoose.Schema({
  id: {
    type: String,
    required: true,
    unique: true,
    default: () => `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  },
  username: {
    type: String,
    required: [true, 'Username is required'],
    unique: true,
    trim: true,
    minlength: [3, 'Username must be at least 3 characters'],
    maxlength: [20, 'Username cannot exceed 20 characters'],
    match: [/^[a-zA-Z0-9_]+$/, 'Username can only contain letters, numbers and underscores']
  },
  displayName: {
    type: String,
    required: [true, 'Display name is required'],
    trim: true,
    maxlength: [50, 'Display name cannot exceed 50 characters']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    validate: [validator.isEmail, 'Please provide a valid email']
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [6, 'Password must be at least 6 characters'],
    select: false // Don't include password in queries by default
  },
  bio: {
    type: String,
    maxlength: [160, 'Bio cannot exceed 160 characters']
  },
  profileImageUrl: {
    type: String,
    validate: [validator.isURL, 'Please provide a valid URL']
  },
  bannerImageUrl: {
    type: String,
    validate: [validator.isURL, 'Please provide a valid URL']
  },
  location: {
    type: String,
    maxlength: [50, 'Location cannot exceed 50 characters']
  },
  website: {
    type: String,
    validate: [validator.isURL, 'Please provide a valid URL']
  },
  joinedDate: {
    type: Date,
    default: Date.now
  },
  followingCount: {
    type: Number,
    default: 0,
    min: 0
  },
  followersCount: {
    type: Number,
    default: 0,
    min: 0
  },
  tweetsCount: {
    type: Number,
    default: 0,
    min: 0
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  isPrivate: {
    type: Boolean,
    default: false
  },
  following: [{
    type: String,
    ref: 'User'
  }],
  followers: [{
    type: String,
    ref: 'User'
  }],
  blockedUsers: [{
    type: String,
    ref: 'User'
  }],
  mutedUsers: [{
    type: String,
    ref: 'User'
  }],
  preferences: {
    theme: {
      type: String,
      enum: ['light', 'dark', 'auto'],
      default: 'auto'
    },
    language: {
      type: String,
      default: 'en'
    },
    notifications: {
      likes: { type: Boolean, default: true },
      retweets: { type: Boolean, default: true },
      mentions: { type: Boolean, default: true },
      follows: { type: Boolean, default: true },
      messages: { type: Boolean, default: true }
    }
  },
  lastActive: {
    type: Date,
    default: Date.now
  },
  isOnline: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better performance
userSchema.index({ username: 1 });
userSchema.index({ email: 1 });
userSchema.index({ id: 1 });
userSchema.index({ displayName: 'text', username: 'text', bio: 'text' });

// Virtual for user's age
userSchema.virtual('accountAge').get(function() {
  return Math.floor((Date.now() - this.joinedDate) / (1000 * 60 * 60 * 24));
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

// Instance method to check password
userSchema.methods.correctPassword = async function(candidatePassword, userPassword) {
  return await bcrypt.compare(candidatePassword, userPassword);
};

// Instance method to update counts
userSchema.methods.updateFollowingCount = function() {
  this.followingCount = this.following.length;
  return this.save();
};

userSchema.methods.updateFollowersCount = function() {
  this.followersCount = this.followers.length;
  return this.save();
};

// Static method to search users
userSchema.statics.searchUsers = function(query, limit = 10) {
  return this.find({
    $text: { $search: query }
  }, {
    score: { $meta: 'textScore' }
  })
  .sort({ score: { $meta: 'textScore' } })
  .limit(limit)
  .select('-password');
};

module.exports = mongoose.model('User', userSchema);