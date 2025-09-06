const mongoose = require('mongoose');

const tweetSchema = new mongoose.Schema({
  id: {
    type: String,
    required: true,
    unique: true,
    default: () => `tweet_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  },
  userId: {
    type: String,
    required: [true, 'User ID is required'],
    ref: 'User'
  },
  content: {
    type: String,
    required: [true, 'Tweet content is required'],
    maxlength: [280, 'Tweet cannot exceed 280 characters'],
    trim: true
  },
  imageUrls: [{
    type: String,
    validate: {
      validator: function(v) {
        return /^https?:\/\/.+\.(jpg|jpeg|png|gif|webp)$/i.test(v);
      },
      message: 'Invalid image URL format'
    }
  }],
  videoUrls: [{
    type: String,
    validate: {
      validator: function(v) {
        return /^https?:\/\/.+\.(mp4|mov|avi|webm)$/i.test(v);
      },
      message: 'Invalid video URL format'
    }
  }],
  createdAt: {
    type: Date,
    default: Date.now
  },
  likesCount: {
    type: Number,
    default: 0,
    min: 0
  },
  retweetsCount: {
    type: Number,
    default: 0,
    min: 0
  },
  repliesCount: {
    type: Number,
    default: 0,
    min: 0
  },
  quoteTweetsCount: {
    type: Number,
    default: 0,
    min: 0
  },
  viewsCount: {
    type: Number,
    default: 0,
    min: 0
  },
  likedBy: [{
    type: String,
    ref: 'User'
  }],
  retweetedBy: [{
    type: String,
    ref: 'User'
  }],
  viewedBy: [{
    userId: { type: String, ref: 'User' },
    viewedAt: { type: Date, default: Date.now }
  }],
  // Retweet functionality
  isRetweet: {
    type: Boolean,
    default: false
  },
  originalTweetId: {
    type: String,
    ref: 'Tweet'
  },
  retweetedByUserId: {
    type: String,
    ref: 'User'
  },
  // Quote tweet functionality
  isQuoteTweet: {
    type: Boolean,
    default: false
  },
  quotedTweetId: {
    type: String,
    ref: 'Tweet'
  },
  // Reply functionality
  replyToTweetId: {
    type: String,
    ref: 'Tweet'
  },
  replyToUserId: {
    type: String,
    ref: 'User'
  },
  // Content analysis
  hashtags: [{
    type: String,
    lowercase: true
  }],
  mentions: [{
    type: String,
    ref: 'User'
  }],
  urls: [{
    type: String
  }],
  // Community and thread info
  communityId: {
    type: String,
    ref: 'Community'
  },
  threadId: {
    type: String
  },
  isPinned: {
    type: Boolean,
    default: false
  },
  // Moderation
  isDeleted: {
    type: Boolean,
    default: false
  },
  isSensitive: {
    type: Boolean,
    default: false
  },
  reportCount: {
    type: Number,
    default: 0
  },
  // Engagement metrics for recommendations
  engagementScore: {
    type: Number,
    default: 0
  },
  lastEngagement: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for better performance
tweetSchema.index({ userId: 1, createdAt: -1 });
tweetSchema.index({ hashtags: 1 });
tweetSchema.index({ mentions: 1 });
tweetSchema.index({ createdAt: -1 });
tweetSchema.index({ engagementScore: -1 });
tweetSchema.index({ content: 'text' });
tweetSchema.index({ replyToTweetId: 1 });
tweetSchema.index({ originalTweetId: 1 });
tweetSchema.index({ quotedTweetId: 1 });

// Pre-save middleware to extract hashtags, mentions, and URLs
tweetSchema.pre('save', function(next) {
  if (this.isModified('content')) {
    // Extract hashtags
    const hashtagRegex = /#[a-zA-Z0-9_]+/g;
    this.hashtags = [...new Set((this.content.match(hashtagRegex) || []).map(tag => tag.slice(1).toLowerCase()))];
    
    // Extract mentions
    const mentionRegex = /@[a-zA-Z0-9_]+/g;
    this.mentions = [...new Set((this.content.match(mentionRegex) || []).map(mention => mention.slice(1).toLowerCase()))];
    
    // Extract URLs
    const urlRegex = /(https?:\/\/[^\s]+)/g;
    this.urls = [...new Set(this.content.match(urlRegex) || [])];
    
    // Calculate initial engagement score
    this.engagementScore = this.calculateEngagementScore();
  }
  next();
});

// Instance method to calculate engagement score
tweetSchema.methods.calculateEngagementScore = function() {
  const weights = {
    like: 1,
    retweet: 3,
    reply: 2,
    quoteTweet: 4,
    view: 0.1
  };
  
  const ageInHours = (Date.now() - this.createdAt) / (1000 * 60 * 60);
  const decayFactor = Math.exp(-ageInHours / 24); // Decay over 24 hours
  
  const baseScore = 
    (this.likesCount * weights.like) +
    (this.retweetsCount * weights.retweet) +
    (this.repliesCount * weights.reply) +
    (this.quoteTweetsCount * weights.quoteTweet) +
    (this.viewsCount * weights.view);
  
  return Math.round(baseScore * decayFactor);
};

// Instance method to update engagement score
tweetSchema.methods.updateEngagementScore = function() {
  this.engagementScore = this.calculateEngagementScore();
  this.lastEngagement = new Date();
  return this.save();
};

// Static method to get trending hashtags
tweetSchema.statics.getTrendingHashtags = async function(limit = 10, timeframe = 24) {
  const cutoffDate = new Date(Date.now() - timeframe * 60 * 60 * 1000);
  
  return this.aggregate([
    {
      $match: {
        createdAt: { $gte: cutoffDate },
        hashtags: { $exists: true, $ne: [] }
      }
    },
    {
      $unwind: '$hashtags'
    },
    {
      $group: {
        _id: '$hashtags',
        count: { $sum: 1 },
        engagementSum: { $sum: '$engagementScore' }
      }
    },
    {
      $sort: { count: -1, engagementSum: -1 }
    },
    {
      $limit: limit
    }
  ]);
};

// Static method for timeline feed
tweetSchema.statics.getTimelineFeed = function(userId, followingUsers, page = 1, limit = 20) {
  const skip = (page - 1) * limit;
  
  return this.find({
    $or: [
      { userId: { $in: [userId, ...followingUsers] } },
      { mentions: userId }
    ],
    isDeleted: { $ne: true }
  })
  .populate('userId', 'id username displayName profileImageUrl isVerified')
  .populate('retweetedByUserId', 'id username displayName profileImageUrl isVerified')
  .populate('replyToUserId', 'id username displayName profileImageUrl isVerified')
  .sort({ createdAt: -1 })
  .skip(skip)
  .limit(limit);
};

// Virtual for user info
tweetSchema.virtual('user', {
  ref: 'User',
  localField: 'userId',
  foreignField: 'id',
  justOne: true
});

// Virtual for original tweet (for retweets)
tweetSchema.virtual('originalTweet', {
  ref: 'Tweet',
  localField: 'originalTweetId',
  foreignField: 'id',
  justOne: true
});

// Virtual for quoted tweet
tweetSchema.virtual('quotedTweet', {
  ref: 'Tweet',
  localField: 'quotedTweetId',
  foreignField: 'id',
  justOne: true
});

// Virtual for reply to tweet
tweetSchema.virtual('replyToTweet', {
  ref: 'Tweet',
  localField: 'replyToTweetId',
  foreignField: 'id',
  justOne: true
});

module.exports = mongoose.model('Tweet', tweetSchema);