import 'user_model.dart';

class CommunityModel {
  final String id;
  final String name;
  final String description;
  final String? bannerImageUrl;
  final String? profileImageUrl;
  final String creatorId;
  final DateTime createdAt;
  final int membersCount;
  final List<String> members;
  final List<String> moderators;
  final List<String> rules;
  final bool isPrivate;
  final bool isVerified;
  final String category;
  final List<String> tags;
  final UserModel? creator;
  
  CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    this.bannerImageUrl,
    this.profileImageUrl,
    required this.creatorId,
    required this.createdAt,
    this.membersCount = 0,
    this.members = const [],
    this.moderators = const [],
    this.rules = const [],
    this.isPrivate = false,
    this.isVerified = false,
    this.category = 'General',
    this.tags = const [],
    this.creator,
  });
  
  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      bannerImageUrl: json['bannerImageUrl'],
      profileImageUrl: json['profileImageUrl'],
      creatorId: json['creatorId'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      membersCount: json['membersCount'] ?? 0,
      members: List<String>.from(json['members'] ?? []),
      moderators: List<String>.from(json['moderators'] ?? []),
      rules: List<String>.from(json['rules'] ?? []),
      isPrivate: json['isPrivate'] ?? false,
      isVerified: json['isVerified'] ?? false,
      category: json['category'] ?? 'General',
      tags: List<String>.from(json['tags'] ?? []),
      creator: json['creator'] != null 
          ? UserModel.fromJson(json['creator'])
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'bannerImageUrl': bannerImageUrl,
      'profileImageUrl': profileImageUrl,
      'creatorId': creatorId,
      'createdAt': createdAt.toIso8601String(),
      'membersCount': membersCount,
      'members': members,
      'moderators': moderators,
      'rules': rules,
      'isPrivate': isPrivate,
      'isVerified': isVerified,
      'category': category,
      'tags': tags,
      'creator': creator?.toJson(),
    };
  }
  
  CommunityModel copyWith({
    String? id,
    String? name,
    String? description,
    String? bannerImageUrl,
    String? profileImageUrl,
    String? creatorId,
    DateTime? createdAt,
    int? membersCount,
    List<String>? members,
    List<String>? moderators,
    List<String>? rules,
    bool? isPrivate,
    bool? isVerified,
    String? category,
    List<String>? tags,
    UserModel? creator,
  }) {
    return CommunityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      membersCount: membersCount ?? this.membersCount,
      members: members ?? this.members,
      moderators: moderators ?? this.moderators,
      rules: rules ?? this.rules,
      isPrivate: isPrivate ?? this.isPrivate,
      isVerified: isVerified ?? this.isVerified,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      creator: creator ?? this.creator,
    );
  }
}