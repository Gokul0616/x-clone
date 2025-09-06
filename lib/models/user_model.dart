class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String email;
  final String? bio;
  final String? profileImageUrl;
  final String? bannerImageUrl;
  final String? location;
  final String? website;
  final DateTime joinedDate;
  final int followingCount;
  final int followersCount;
  final int tweetsCount;
  final bool isVerified;
  final bool isPrivate;
  final List<String> following;
  final List<String> followers;
  
  UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    this.bio,
    this.profileImageUrl,
    this.bannerImageUrl,
    this.location,
    this.website,
    required this.joinedDate,
    this.followingCount = 0,
    this.followersCount = 0,
    this.tweetsCount = 0,
    this.isVerified = false,
    this.isPrivate = false,
    this.following = const [],
    this.followers = const [],
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'],
      profileImageUrl: json['profileImageUrl'],
      bannerImageUrl: json['bannerImageUrl'],
      location: json['location'],
      website: json['website'],
      joinedDate: json['joinedDate'] != null 
          ? DateTime.parse(json['joinedDate'])
          : DateTime.now(),
      followingCount: json['followingCount'] ?? 0,
      followersCount: json['followersCount'] ?? 0,
      tweetsCount: json['tweetsCount'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      isPrivate: json['isPrivate'] ?? false,
      following: List<String>.from(json['following'] ?? []),
      followers: List<String>.from(json['followers'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'email': email,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'bannerImageUrl': bannerImageUrl,
      'location': location,
      'website': website,
      'joinedDate': joinedDate.toIso8601String(),
      'followingCount': followingCount,
      'followersCount': followersCount,
      'tweetsCount': tweetsCount,
      'isVerified': isVerified,
      'isPrivate': isPrivate,
      'following': following,
      'followers': followers,
    };
  }
  
  UserModel copyWith({
    String? id,
    String? username,
    String? displayName,
    String? email,
    String? bio,
    String? profileImageUrl,
    String? bannerImageUrl,
    String? location,
    String? website,
    DateTime? joinedDate,
    int? followingCount,
    int? followersCount,
    int? tweetsCount,
    bool? isVerified,
    bool? isPrivate,
    List<String>? following,
    List<String>? followers,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      location: location ?? this.location,
      website: website ?? this.website,
      joinedDate: joinedDate ?? this.joinedDate,
      followingCount: followingCount ?? this.followingCount,
      followersCount: followersCount ?? this.followersCount,
      tweetsCount: tweetsCount ?? this.tweetsCount,
      isVerified: isVerified ?? this.isVerified,
      isPrivate: isPrivate ?? this.isPrivate,
      following: following ?? this.following,
      followers: followers ?? this.followers,
    );
  }
}