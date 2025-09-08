import '../models/user_model.dart';
import '../models/tweet_model.dart';
import '../models/community_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';

class MockApiService {
  static final MockApiService _instance = MockApiService._internal();
  factory MockApiService() => _instance;
  MockApiService._internal();

  // Mock current user
  static const String currentUserId = 'user_1';

  // Mock data
  List<UserModel> _mockUsers = [];
  List<TweetModel> _mockTweets = [];
  List<CommunityModel> _mockCommunities = [];
  List<MessageModel> _mockMessages = [];
  List<ConversationModel> _mockConversations = [];
  List<NotificationModel> _mockNotifications = [];

  // Initialize mock data
  void _initializeMockData() {
    if (_mockUsers.isNotEmpty) return; // Already initialized

    // Create mock users
    _mockUsers = [
      UserModel(
        id: 'user_1',
        username: 'johndoe',
        displayName: 'John Doe',
        email: 'john@example.com',
        bio:
            'Software developer passionate about Flutter and mobile development. Building the future one app at a time.',
        profileImageUrl: 'https://i.pravatar.cc/150?img=1',
        bannerImageUrl: 'https://picsum.photos/600/200?random=1',
        location: 'San Francisco, CA',
        website: 'https://johndoe.dev',
        joinedDate: DateTime.now().subtract(const Duration(days: 365)),
        followingCount: 245,
        followersCount: 1840,
        tweetsCount: 1205,
        isVerified: true,
        following: ['user_2', 'user_3', 'user_4'],
        followers: ['user_2', 'user_3', 'user_5'],
      ),
      UserModel(
        id: 'user_2',
        username: 'janedeveloper',
        displayName: 'Jane Smith',
        email: 'jane@example.com',
        bio:
            'UX Designer & Flutter enthusiast. Creating beautiful and functional mobile experiences.',
        profileImageUrl: 'https://i.pravatar.cc/150?img=2',
        bannerImageUrl: 'https://picsum.photos/600/200?random=2',
        location: 'New York, NY',
        website: 'https://janesmith.design',
        joinedDate: DateTime.now().subtract(const Duration(days: 280)),
        followingCount: 180,
        followersCount: 950,
        tweetsCount: 680,
        isVerified: false,
        following: ['user_1', 'user_3'],
        followers: ['user_1', 'user_4', 'user_5'],
      ),
      UserModel(
        id: 'user_3',
        username: 'techenthusiast',
        displayName: 'Alex Johnson',
        email: 'alex@example.com',
        bio:
            'Tech entrepreneur & startup founder. Always excited about new technologies and innovations.',
        profileImageUrl: 'https://i.pravatar.cc/150?img=3',
        bannerImageUrl: 'https://picsum.photos/600/200?random=3',
        location: 'Austin, TX',
        website: 'https://alexjohnson.tech',
        joinedDate: DateTime.now().subtract(const Duration(days: 150)),
        followingCount: 320,
        followersCount: 2100,
        tweetsCount: 890,
        isVerified: true,
        following: ['user_1', 'user_2', 'user_4'],
        followers: ['user_1', 'user_2', 'user_5'],
      ),
      UserModel(
        id: 'user_4',
        username: 'designerguru',
        displayName: 'Sarah Wilson',
        email: 'sarah@example.com',
        bio:
            'Product Designer with a passion for user-centered design and accessibility.',
        profileImageUrl: 'https://i.pravatar.cc/150?img=4',
        bannerImageUrl: 'https://picsum.photos/600/200?random=4',
        location: 'Seattle, WA',
        joinedDate: DateTime.now().subtract(const Duration(days: 200)),
        followingCount: 150,
        followersCount: 780,
        tweetsCount: 340,
        isVerified: false,
        following: ['user_1', 'user_3'],
        followers: ['user_2', 'user_3', 'user_5'],
      ),
      UserModel(
        id: 'user_5',
        username: 'codemaster',
        displayName: 'Mike Chen',
        email: 'mike@example.com',
        bio:
            'Full-stack developer & open source contributor. Love sharing knowledge and building communities.',
        profileImageUrl: 'https://i.pravatar.cc/150?img=5',
        bannerImageUrl: 'https://picsum.photos/600/200?random=5',
        location: 'Toronto, Canada',
        website: 'https://mikechen.dev',
        joinedDate: DateTime.now().subtract(const Duration(days: 300)),
        followingCount: 400,
        followersCount: 1200,
        tweetsCount: 750,
        isVerified: false,
        following: ['user_1', 'user_2', 'user_3', 'user_4'],
        followers: ['user_1', 'user_2', 'user_3', 'user_4'],
      ),
    ];

    // Create mock tweets
    _mockTweets = [
      TweetModel(
        id: 'tweet_1',
        userId: 'user_1',
        content:
            'Just shipped a new Flutter app! The developer experience keeps getting better with each release. 🚀 #FlutterDev #MobileDev',
        imageUrls: ['https://picsum.photos/400/300?random=11'],
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        likesCount: 45,
        retweetsCount: 12,
        repliesCount: 8,
        quoteTweetsCount: 3,
        likedBy: ['user_2', 'user_3'],
        retweetedBy: ['user_2'],
        hashtags: ['FlutterDev', 'MobileDev'],
        user: _mockUsers[0],
      ),
      TweetModel(
        id: 'tweet_2',
        userId: 'user_2',
        content:
            'Working on some exciting UI designs for our next mobile app. The new Material Design 3 components are amazing! ✨',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        likesCount: 28,
        retweetsCount: 6,
        repliesCount: 15,
        quoteTweetsCount: 2,
        likedBy: ['user_1', 'user_3', 'user_4'],
        retweetedBy: ['user_3'],
        user: _mockUsers[1],
      ),
      TweetModel(
        id: 'tweet_3',
        userId: 'user_3',
        content:
            'The future of mobile development is bright! With tools like Flutter, React Native, and native development, we have so many great options.',
        imageUrls: [
          'https://picsum.photos/400/250?random=12',
          'https://picsum.photos/400/250?random=13',
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        likesCount: 67,
        retweetsCount: 23,
        repliesCount: 31,
        quoteTweetsCount: 8,
        likedBy: ['user_1', 'user_2', 'user_4', 'user_5'],
        retweetedBy: ['user_1', 'user_4'],
        user: _mockUsers[2],
      ),
      TweetModel(
        id: 'tweet_4',
        userId: 'user_4',
        content:
            'Accessibility in mobile apps is not optional - it\'s essential. Here are some key principles every designer should know 🧵',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        likesCount: 89,
        retweetsCount: 34,
        repliesCount: 19,
        quoteTweetsCount: 12,
        likedBy: ['user_1', 'user_2', 'user_3', 'user_5'],
        retweetedBy: ['user_2', 'user_5'],
        user: _mockUsers[3],
      ),
      TweetModel(
        id: 'tweet_5',
        userId: 'user_5',
        content:
            'Open source contribution tip: Start small, be consistent, and don\'t be afraid to ask questions. The community is amazing! 💜',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        likesCount: 156,
        retweetsCount: 45,
        repliesCount: 28,
        quoteTweetsCount: 15,
        likedBy: ['user_1', 'user_2', 'user_3', 'user_4'],
        retweetedBy: ['user_1', 'user_3'],
        user: _mockUsers[4],
      ),
      // Reply tweet
      TweetModel(
        id: 'tweet_6',
        userId: 'user_2',
        content:
            'Totally agree! The Flutter community has been incredibly welcoming and helpful.',
        createdAt: DateTime.now().subtract(const Duration(hours: 10)),
        likesCount: 23,
        retweetsCount: 3,
        repliesCount: 2,
        quoteTweetsCount: 0,
        likedBy: ['user_1', 'user_5'],
        retweetedBy: ['user_1'],
        replyToTweetId: 'tweet_5',
        replyToUserId: 'user_5',
        user: _mockUsers[1],
        replyToUser: _mockUsers[4],
      ),
    ];

    // Create mock communities
    _mockCommunities = [
      CommunityModel(
        id: 'community_1',
        name: 'Flutter Developers',
        description:
            'A community for Flutter developers to share knowledge, tips, and showcase their apps.',
        bannerImageUrl: 'https://picsum.photos/600/200?random=21',
        profileImageUrl: 'https://picsum.photos/150/150?random=22',
        creatorId: 'user_1',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        membersCount: 1250,
        members: ['user_1', 'user_2', 'user_3', 'user_4', 'user_5'],
        moderators: ['user_1', 'user_3'],
        rules: [
          'Be respectful and professional',
          'No spam or self-promotion without permission',
          'Stay on topic - Flutter development',
          'Help others learn and grow',
        ],
        category: 'Technology',
        tags: ['flutter', 'dart', 'mobile', 'development'],
        creator: _mockUsers[0],
      ),
      CommunityModel(
        id: 'community_2',
        name: 'UI/UX Designers',
        description:
            'Share design inspiration, get feedback, and discuss the latest trends in UI/UX design.',
        bannerImageUrl: 'https://picsum.photos/600/200?random=23',
        profileImageUrl: 'https://picsum.photos/150/150?random=24',
        creatorId: 'user_2',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        membersCount: 890,
        members: ['user_1', 'user_2', 'user_4'],
        moderators: ['user_2', 'user_4'],
        rules: [
          'Share constructive feedback only',
          'Credit original creators',
          'No offensive content',
          'Keep discussions design-related',
        ],
        category: 'Design',
        tags: ['ui', 'ux', 'design', 'mobile'],
        creator: _mockUsers[1],
      ),
      CommunityModel(
        id: 'community_3',
        name: 'Tech Entrepreneurs',
        description:
            'Connect with fellow entrepreneurs, share startup experiences, and discuss the latest in tech.',
        bannerImageUrl: 'https://picsum.photos/600/200?random=25',
        profileImageUrl: 'https://picsum.photos/150/150?random=26',
        creatorId: 'user_3',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        membersCount: 567,
        members: ['user_1', 'user_3', 'user_5'],
        moderators: ['user_3'],
        rules: [
          'No direct sales pitches',
          'Share valuable insights and experiences',
          'Support fellow entrepreneurs',
          'Keep discussions business-focused',
        ],
        category: 'Business',
        tags: ['startup', 'entrepreneur', 'business', 'tech'],
        creator: _mockUsers[2],
      ),
    ];

    // Create mock messages and conversations
    _mockMessages = [
      MessageModel(
        id: 'message_1',
        senderId: 'user_2',
        conversationId: 'conv_1',
        content: 'Hey! Loved your latest Flutter app. Any tips for beginners?',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
        sender: _mockUsers[1],
      ),
      MessageModel(
        id: 'message_2',
        senderId: 'user_1',
        conversationId: 'conv_1',
        content:
            'Thanks! I\'d recommend starting with the official documentation and building small projects first.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: true,
        sender: _mockUsers[0],
      ),
    ];

    _mockConversations = [
      ConversationModel(
        id: 'conv_1',
        participants: ['user_1', 'user_2'],
        lastMessage: _mockMessages[1],
        lastActivity: DateTime.now().subtract(const Duration(minutes: 30)),
        participantUsers: [_mockUsers[0], _mockUsers[1]],
        unreadCount: 1,
      ),
    ];

    // Create mock notifications
    _mockNotifications = [
      NotificationModel(
        id: 'notif_1',
        userId: 'user_1',
        type: 'like',
        fromUserId: 'user_2',
        tweetId: 'tweet_1',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        isRead: false,
        fromUser: _mockUsers[1],
        tweet: _mockTweets[0],
      ),
      NotificationModel(
        id: 'notif_2',
        userId: 'user_1',
        type: 'follow',
        fromUserId: 'user_3',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        fromUser: _mockUsers[2],
      ),
      NotificationModel(
        id: 'notif_3',
        userId: 'user_1',
        type: 'retweet',
        fromUserId: 'user_4',
        tweetId: 'tweet_1',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        isRead: true,
        fromUser: _mockUsers[3],
        tweet: _mockTweets[0],
      ),
    ];
  }

  // Authentication
  Future<UserModel?> login(String email, String password) async {
    _initializeMockData();
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate network delay

    // Simple mock authentication
    if (email == 'john@example.com' && password == 'password') {
      return _mockUsers.first;
    }
    return null;
  }

  Future<UserModel?> register(
    String email,
    String password,
    String username,
    String displayName,
  ) async {
    _initializeMockData();
    await Future.delayed(const Duration(milliseconds: 800));

    // Create new user
    final newUser = UserModel(
      id: 'user_${_mockUsers.length + 1}',
      username: username,
      displayName: displayName,
      email: email,
      joinedDate: DateTime.now(),
    );

    _mockUsers.add(newUser);
    return newUser;
  }

  // Tweets
  Future<List<TweetModel>> getTimeline({int page = 1, int limit = 20}) async {
    _initializeMockData();
    await Future.delayed(const Duration(milliseconds: 600));

    // Return tweets sorted by creation date
    final sortedTweets = List<TweetModel>.from(_mockTweets)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;

    if (startIndex >= sortedTweets.length) return [];

    return sortedTweets.sublist(
      startIndex,
      endIndex > sortedTweets.length ? sortedTweets.length : endIndex,
    );
  }

  Future<TweetModel?> createTweet(
    String content, {
    List<String>? imageUrls,
    String? replyToTweetId,
    String? quotedTweetId,
  }) async {
    _initializeMockData();
    await Future.delayed(const Duration(milliseconds: 700));

    final newTweet = TweetModel(
      id: 'tweet_${_mockTweets.length + 1}',
      userId: currentUserId,
      content: content,
      imageUrls: imageUrls ?? [],
      createdAt: DateTime.now(),
      replyToTweetId: replyToTweetId,
      quotedTweetId: quotedTweetId,
      user: _mockUsers.firstWhere((user) => user.id == currentUserId),
    );

    _mockTweets.insert(0, newTweet);
    return newTweet;
  }

  Future<bool> likeTweet(String tweetId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final tweetIndex = _mockTweets.indexWhere((tweet) => tweet.id == tweetId);
    if (tweetIndex != -1) {
      final tweet = _mockTweets[tweetIndex];
      final likedBy = List<String>.from(tweet.likedBy);

      if (likedBy.contains(currentUserId)) {
        likedBy.remove(currentUserId);
      } else {
        likedBy.add(currentUserId);
      }

      _mockTweets[tweetIndex] = tweet.copyWith(
        likedBy: likedBy,
        likesCount: likedBy.length,
      );

      return true;
    }
    return false;
  }

  Future<bool> retweetTweet(String tweetId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final tweetIndex = _mockTweets.indexWhere((tweet) => tweet.id == tweetId);
    if (tweetIndex != -1) {
      final tweet = _mockTweets[tweetIndex];
      final retweetedBy = List<String>.from(tweet.retweetedBy);

      if (retweetedBy.contains(currentUserId)) {
        retweetedBy.remove(currentUserId);
      } else {
        retweetedBy.add(currentUserId);
      }

      _mockTweets[tweetIndex] = tweet.copyWith(
        retweetedBy: retweetedBy,
        retweetsCount: retweetedBy.length,
      );

      return true;
    }
    return false;
  }

  Future<List<TweetModel>> getTweetReplies(String tweetId) async {
    _initializeMockData();
    await Future.delayed(const Duration(milliseconds: 400));

    return _mockTweets
        .where((tweet) => tweet.replyToTweetId == tweetId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  // Users
  Future<UserModel?> getUserById(String userId) async {
    _initializeMockData();
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      return _mockUsers.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    _initializeMockData();
    await Future.delayed(const Duration(milliseconds: 500));

    return _mockUsers
        .where(
          (user) =>
              user.displayName.toLowerCase().contains(query.toLowerCase()) ||
              user.username.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  Future<bool> followUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final currentUserIndex = _mockUsers.indexWhere(
      (user) => user.id == currentUserId,
    );
    final targetUserIndex = _mockUsers.indexWhere((user) => user.id == userId);

    if (currentUserIndex != -1 && targetUserIndex != -1) {
      final currentUser = _mockUsers[currentUserIndex];
      final targetUser = _mockUsers[targetUserIndex];

      final following = List<String>.from(currentUser.following);
      final followers = List<String>.from(targetUser.followers);

      if (following.contains(userId)) {
        following.remove(userId);
        followers.remove(currentUserId);
      } else {
        following.add(userId);
        followers.add(currentUserId);
      }

      _mockUsers[currentUserIndex] = currentUser.copyWith(
        following: following,
        followingCount: following.length,
      );

      _mockUsers[targetUserIndex] = targetUser.copyWith(
        followers: followers,
        followersCount: followers.length,
      );

      return true;
    }
    return false;
  }

  // Communities
  Future<List<CommunityModel>> getCommunities() async {
    _initializeMockData();
    await Future.delayed(const Duration(milliseconds: 600));

    return List<CommunityModel>.from(_mockCommunities);
  }

  Future<bool> joinCommunity(String communityId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final communityIndex = _mockCommunities.indexWhere(
      (community) => community.id == communityId,
    );

    if (communityIndex != -1) {
      final community = _mockCommunities[communityIndex];
      final members = List<String>.from(community.members);

      if (members.contains(currentUserId)) {
        members.remove(currentUserId);
      } else {
        members.add(currentUserId);
      }

      _mockCommunities[communityIndex] = community.copyWith(
        members: members,
        membersCount: members.length,
      );

      return true;
    }
    return false;
  }

  Future<CommunityModel?> createCommunity(
    String name,
    String description,
  ) async {
    _initializeMockData();
    await Future.delayed(const Duration(milliseconds: 800));

    final newCommunity = CommunityModel(
      id: 'community_${_mockCommunities.length + 1}',
      name: name,
      description: description,
      creatorId: currentUserId,
      createdAt: DateTime.now(),
      members: [currentUserId],
      moderators: [currentUserId],
      creator: _mockUsers.firstWhere((user) => user.id == currentUserId),
    );

    _mockCommunities.add(newCommunity);
    return newCommunity;
  }

  // Messages
  Future<List<ConversationModel>> getConversations() async {
    _initializeMockData();
    await Future.delayed(const Duration(milliseconds: 500));

    return List<ConversationModel>.from(_mockConversations);
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    _initializeMockData();
    await Future.delayed(const Duration(milliseconds: 400));

    return _mockMessages
        .where((message) => message.conversationId == conversationId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<MessageModel?> sendMessage(String receiverId, String content) async {
    _initializeMockData();
    await Future.delayed(const Duration(milliseconds: 600));

    final newMessage = MessageModel(
      id: 'message_${_mockMessages.length + 1}',
      senderId: currentUserId,
      conversationId: 'conv_1', // Simplified for mock
      content: content,
      createdAt: DateTime.now(),
      sender: _mockUsers.firstWhere((user) => user.id == currentUserId),
    );

    _mockMessages.add(newMessage);
    return newMessage;
  }

  // Notifications
  Future<List<NotificationModel>> getNotifications() async {
    _initializeMockData();
    await Future.delayed(const Duration(milliseconds: 400));

    return _mockNotifications
        .where((notification) => notification.userId == currentUserId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
