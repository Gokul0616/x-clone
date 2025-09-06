const express = require('express');
const Community = require('../models/Community');
const Tweet = require('../models/Tweet');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { auth, optionalAuth } = require('../middleware/auth');
const router = express.Router();

// Get all communities
router.get('/', optionalAuth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const category = req.query.category;
    const skip = (page - 1) * limit;

    let query = { isActive: true };
    if (category) {
      query.category = category;
    }

    const communities = await Community.find(query)
      .populate('creatorId', 'id username displayName profileImageUrl isVerified')
      .sort({ membersCount: -1, createdAt: -1 })
      .skip(skip)
      .limit(limit);

    res.status(200).json({
      status: 'success',
      communities,
      pagination: {
        page,
        limit,
        hasMore: communities.length === limit
      }
    });

  } catch (error) {
    console.error('Get communities error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get communities'
    });
  }
});

// Get community by ID
router.get('/:communityId', optionalAuth, async (req, res) => {
  try {
    const { communityId } = req.params;

    const community = await Community.findOne({ id: communityId, isActive: true })
      .populate('creatorId', 'id username displayName profileImageUrl isVerified')
      .populate('moderators', 'id username displayName profileImageUrl isVerified');

    if (!community) {
      return res.status(404).json({
        status: 'error',
        message: 'Community not found'
      });
    }

    res.status(200).json({
      status: 'success',
      community
    });

  } catch (error) {
    console.error('Get community error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get community'
    });
  }
});

// Create new community
router.post('/', auth, async (req, res) => {
  try {
    const { name, description, category, tags, rules, isPrivate = false } = req.body;
    const creatorId = req.user.id;

    if (!name || !description || !category) {
      return res.status(400).json({
        status: 'error',
        message: 'Name, description, and category are required'
      });
    }

    // Check if community name already exists
    const existingCommunity = await Community.findOne({ 
      name: { $regex: new RegExp('^' + name + '$', 'i') }
    });

    if (existingCommunity) {
      return res.status(400).json({
        status: 'error',
        message: 'Community with this name already exists'
      });
    }

    const community = new Community({
      name: name.trim(),
      description: description.trim(),
      category,
      tags: tags || [],
      rules: rules || [],
      isPrivate,
      creatorId,
      members: [creatorId],
      moderators: [creatorId]
    });

    await community.save();
    await community.populate('creatorId', 'id username displayName profileImageUrl isVerified');

    res.status(201).json({
      status: 'success',
      message: 'Community created successfully',
      community
    });

  } catch (error) {
    console.error('Create community error:', error);
    
    if (error.name === 'ValidationError') {
      const errors = Object.values(error.errors).map(e => e.message);
      return res.status(400).json({
        status: 'error',
        message: 'Validation failed',
        errors
      });
    }

    res.status(500).json({
      status: 'error',
      message: 'Failed to create community'
    });
  }
});

// Join/Leave community
router.post('/:communityId/join', auth, async (req, res) => {
  try {
    const { communityId } = req.params;
    const userId = req.user.id;

    const community = await Community.findOne({ id: communityId, isActive: true });
    if (!community) {
      return res.status(404).json({
        status: 'error',
        message: 'Community not found'
      });
    }

    const isMember = community.members.includes(userId);

    if (isMember) {
      // Leave community
      if (community.creatorId === userId) {
        return res.status(400).json({
          status: 'error',
          message: 'Community creator cannot leave the community'
        });
      }

      await community.removeMember(userId);
      
      // Remove from moderators if applicable
      if (community.moderators.includes(userId)) {
        community.moderators = community.moderators.filter(id => id !== userId);
        await community.save();
      }

      res.status(200).json({
        status: 'success',
        message: 'Left community successfully',
        isMember: false
      });
    } else {
      // Join community
      await community.addMember(userId);

      // Create notification for community creator
      await Notification.createNotification({
        userId: community.creatorId,
        type: 'community_join',
        fromUserId: userId,
        communityId: community.id
      });

      res.status(200).json({
        status: 'success',
        message: 'Joined community successfully',
        isMember: true
      });
    }

  } catch (error) {
    console.error('Join/Leave community error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to join/leave community'
    });
  }
});

// Get community members
router.get('/:communityId/members', optionalAuth, async (req, res) => {
  try {
    const { communityId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const community = await Community.findOne({ id: communityId, isActive: true });
    if (!community) {
      return res.status(404).json({
        status: 'error',
        message: 'Community not found'
      });
    }

    const members = await User.find({
      id: { $in: community.members }
    })
    .select('id username displayName profileImageUrl isVerified followersCount joinedDate')
    .sort({ followersCount: -1 })
    .skip(skip)
    .limit(limit);

    // Mark moderators and creator
    const membersWithRoles = members.map(member => {
      const memberObj = member.toObject();
      memberObj.isCreator = member.id === community.creatorId;
      memberObj.isModerator = community.moderators.includes(member.id);
      return memberObj;
    });

    res.status(200).json({
      status: 'success',
      members: membersWithRoles,
      pagination: {
        page,
        limit,
        hasMore: members.length === limit
      }
    });

  } catch (error) {
    console.error('Get community members error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get community members'
    });
  }
});

// Get community tweets
router.get('/:communityId/tweets', optionalAuth, async (req, res) => {
  try {
    const { communityId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const community = await Community.findOne({ id: communityId, isActive: true });
    if (!community) {
      return res.status(404).json({
        status: 'error',
        message: 'Community not found'
      });
    }

    const tweets = await Tweet.find({
      communityId: communityId,
      isDeleted: { $ne: true }
    })
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
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit);

    res.status(200).json({
      status: 'success',
      tweets,
      pagination: {
        page,
        limit,
        hasMore: tweets.length === limit
      }
    });

  } catch (error) {
    console.error('Get community tweets error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get community tweets'
    });
  }
});

// Update community (moderators and creator only)
router.put('/:communityId', auth, async (req, res) => {
  try {
    const { communityId } = req.params;
    const userId = req.user.id;
    const { description, rules, bannerImageUrl, profileImageUrl } = req.body;

    const community = await Community.findOne({ id: communityId, isActive: true });
    if (!community) {
      return res.status(404).json({
        status: 'error',
        message: 'Community not found'
      });
    }

    // Check if user is moderator or creator
    if (!community.moderators.includes(userId) && community.creatorId !== userId) {
      return res.status(403).json({
        status: 'error',
        message: 'Only moderators can update community'
      });
    }

    const updates = {};
    if (description) updates.description = description.trim();
    if (rules) updates.rules = rules;
    if (bannerImageUrl) updates.bannerImageUrl = bannerImageUrl;
    if (profileImageUrl) updates.profileImageUrl = profileImageUrl;

    const updatedCommunity = await Community.findOneAndUpdate(
      { id: communityId },
      updates,
      { new: true, runValidators: true }
    ).populate('creatorId', 'id username displayName profileImageUrl isVerified');

    res.status(200).json({
      status: 'success',
      message: 'Community updated successfully',
      community: updatedCommunity
    });

  } catch (error) {
    console.error('Update community error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to update community'
    });
  }
});

// Add moderator (creator only)
router.post('/:communityId/moderators', auth, async (req, res) => {
  try {
    const { communityId } = req.params;
    const { userId } = req.body;
    const creatorId = req.user.id;

    const community = await Community.findOne({ id: communityId, isActive: true });
    if (!community) {
      return res.status(404).json({
        status: 'error',
        message: 'Community not found'
      });
    }

    // Check if user is creator
    if (community.creatorId !== creatorId) {
      return res.status(403).json({
        status: 'error',
        message: 'Only community creator can add moderators'
      });
    }

    // Check if target user exists and is a member
    if (!community.members.includes(userId)) {
      return res.status(400).json({
        status: 'error',
        message: 'User must be a community member to become moderator'
      });
    }

    if (community.moderators.includes(userId)) {
      return res.status(400).json({
        status: 'error',
        message: 'User is already a moderator'
      });
    }

    await community.addModerator(userId);

    res.status(200).json({
      status: 'success',
      message: 'Moderator added successfully'
    });

  } catch (error) {
    console.error('Add moderator error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to add moderator'
    });
  }
});

// Get community categories
router.get('/meta/categories', async (req, res) => {
  try {
    const categories = [
      'Technology',
      'Design',
      'Business',
      'Entertainment',
      'Sports',
      'Gaming',
      'Art',
      'Music',
      'Other'
    ];

    res.status(200).json({
      status: 'success',
      categories
    });

  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to get categories'
    });
  }
});

module.exports = router;