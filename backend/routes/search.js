const express = require('express');
const User = require('../models/User');
const Tweet = require('../models/Tweet');
const Community = require('../models/Community');
const { optionalAuth } = require('../middleware/auth');
const router = express.Router();

// Search users
router.get('/users', optionalAuth, async (req, res) => {
  try {
    const { q, page = 1, limit = 20 } = req.query;
    
    if (!q || q.trim().length === 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Search query is required'
      });
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    const users = await User.find({
      $or: [
        { username: { $regex: q, $options: 'i' } },
        { displayName: { $regex: q, $options: 'i' } },
        { bio: { $regex: q, $options: 'i' } }
      ]
    })
    .select('id username displayName profileImageUrl isVerified followersCount bio')
    .sort({ followersCount: -1, isVerified: -1 })
    .skip(skip)
    .limit(parseInt(limit));

    res.status(200).json({
      status: 'success',
      users,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        hasMore: users.length === parseInt(limit)
      }
    });

  } catch (error) {
    console.error('Search users error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to search users'
    });
  }
});

// Search tweets
router.get('/tweets', optionalAuth, async (req, res) => {
  try {
    const { q, page = 1, limit = 20 } = req.query;
    
    if (!q || q.trim().length === 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Search query is required'
      });
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    // Build search query
    let searchQuery = {
      isDeleted: { $ne: true },
      $or: [
        { content: { $regex: q, $options: 'i' } },
        { hashtags: { $regex: q, $options: 'i' } }
      ]
    };

    // If query starts with #, search hashtags specifically
    if (q.startsWith('#')) {
      const hashtag = q.slice(1).toLowerCase();
      searchQuery = {
        isDeleted: { $ne: true },
        hashtags: hashtag
      };
    }

    // If query starts with @, search mentions specifically
    if (q.startsWith('@')) {
      const mention = q.slice(1).toLowerCase();
      searchQuery = {
        isDeleted: { $ne: true },
        mentions: mention
      };
    }

    const tweets = await Tweet.find(searchQuery)
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
      .sort({ engagementScore: -1, createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    res.status(200).json({
      status: 'success',
      tweets,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        hasMore: tweets.length === parseInt(limit)
      }
    });

  } catch (error) {
    console.error('Search tweets error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to search tweets'
    });
  }
});

// Search communities
router.get('/communities', optionalAuth, async (req, res) => {
  try {
    const { q, page = 1, limit = 20 } = req.query;
    
    if (!q || q.trim().length === 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Search query is required'
      });
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    const communities = await Community.find({
      $or: [
        { name: { $regex: q, $options: 'i' } },
        { description: { $regex: q, $options: 'i' } },
        { tags: { $regex: q, $options: 'i' } }
      ],
      isActive: true
    })
    .populate('creatorId', 'id username displayName profileImageUrl isVerified')
    .sort({ membersCount: -1 })
    .skip(skip)
    .limit(parseInt(limit));

    res.status(200).json({
      status: 'success',
      communities,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        hasMore: communities.length === parseInt(limit)
      }
    });

  } catch (error) {
    console.error('Search communities error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to search communities'
    });
  }
});

// Global search (all types)
router.get('/', optionalAuth, async (req, res) => {
  try {
    const { q, type = 'all', page = 1, limit = 10 } = req.query;
    
    if (!q || q.trim().length === 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Search query is required'
      });
    }

    const results = {};
    const searchLimit = parseInt(limit);

    if (type === 'all' || type === 'users') {
      const users = await User.find({
        $or: [
          { username: { $regex: q, $options: 'i' } },
          { displayName: { $regex: q, $options: 'i' } }
        ]
      })
      .select('id username displayName profileImageUrl isVerified followersCount')
      .sort({ followersCount: -1, isVerified: -1 })
      .limit(searchLimit);
      
      results.users = users;
    }

    if (type === 'all' || type === 'tweets') {
      let tweetSearchQuery = {
        isDeleted: { $ne: true },
        $or: [
          { content: { $regex: q, $options: 'i' } },
          { hashtags: { $regex: q, $options: 'i' } }
        ]
      };

      if (q.startsWith('#')) {
        const hashtag = q.slice(1).toLowerCase();
        tweetSearchQuery = {
          isDeleted: { $ne: true },
          hashtags: hashtag
        };
      }

      const tweets = await Tweet.find(tweetSearchQuery)
        .populate('userId', 'id username displayName profileImageUrl isVerified')
        .sort({ engagementScore: -1, createdAt: -1 })
        .limit(searchLimit);
      
      results.tweets = tweets;
    }

    if (type === 'all' || type === 'communities') {
      const communities = await Community.find({
        $or: [
          { name: { $regex: q, $options: 'i' } },
          { description: { $regex: q, $options: 'i' } },
          { tags: { $regex: q, $options: 'i' } }
        ],
        isActive: true
      })
      .populate('creatorId', 'id username displayName profileImageUrl isVerified')
      .sort({ membersCount: -1 })
      .limit(searchLimit);
      
      results.communities = communities;
    }

    res.status(200).json({
      status: 'success',
      query: q,
      results
    });

  } catch (error) {
    console.error('Global search error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Search failed'
    });
  }
});

// Get search suggestions
router.get('/suggestions', optionalAuth, async (req, res) => {
  try {
    const { q } = req.query;
    
    if (!q || q.trim().length < 2) {
      return res.status(200).json({
        status: 'success',
        suggestions: []
      });
    }

    // Get trending hashtags
    const trendingHashtags = await Tweet.getTrendingHashtags(5);
    const hashtagSuggestions = trendingHashtags
      .filter(tag => tag._id.toLowerCase().includes(q.toLowerCase()))
      .map(tag => ({ type: 'hashtag', value: `#${tag._id}`, count: tag.count }));

    // Get user suggestions
    const userSuggestions = await User.find({
      $or: [
        { username: { $regex: q, $options: 'i' } },
        { displayName: { $regex: q, $options: 'i' } }
      ]
    })
    .select('id username displayName profileImageUrl isVerified')
    .sort({ followersCount: -1, isVerified: -1 })
    .limit(5);

    const suggestions = [
      ...hashtagSuggestions,
      ...userSuggestions.map(user => ({
        type: 'user',
        value: user.username,
        user: user
      }))
    ];

    res.status(200).json({
      status: 'success',
      suggestions: suggestions.slice(0, 10)
    });

  } catch (error) {
    console.error('Get suggestions error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get suggestions'
    });
  }
});

module.exports = router;