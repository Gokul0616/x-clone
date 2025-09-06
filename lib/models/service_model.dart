import 'user_model.dart';

class ServiceModel {
  final String id;
  final String providerId;
  final String title;
  final String description;
  final double? startingPrice;
  final String currency;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String category;
  final String serviceType; // fixed_price, hourly, custom
  final String location;
  final bool isRemote;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isAvailable;
  final bool isFeatured;
  final List<String> tags;
  final List<String> skills;
  final int views;
  final int likes;
  final List<String> likedBy;
  final String? communityId;
  final UserModel? provider;
  final double rating;
  final int reviewsCount;
  final String status; // active, paused, draft
  final String? portfolio;
  final int deliveryDays;
  
  ServiceModel({
    required this.id,
    required this.providerId,
    required this.title,
    required this.description,
    this.startingPrice,
    this.currency = 'USD',
    this.imageUrls = const [],
    this.videoUrls = const [],
    required this.category,
    this.serviceType = 'fixed_price',
    required this.location,
    this.isRemote = false,
    required this.createdAt,
    this.updatedAt,
    this.isAvailable = true,
    this.isFeatured = false,
    this.tags = const [],
    this.skills = const [],
    this.views = 0,
    this.likes = 0,
    this.likedBy = const [],
    this.communityId,
    this.provider,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.status = 'active',
    this.portfolio,
    this.deliveryDays = 7,
  });
  
  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      providerId: json['providerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startingPrice: json['startingPrice']?.toDouble(),
      currency: json['currency'] ?? 'USD',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      videoUrls: List<String>.from(json['videoUrls'] ?? []),
      category: json['category'] ?? '',
      serviceType: json['serviceType'] ?? 'fixed_price',
      location: json['location'] ?? '',
      isRemote: json['isRemote'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : null,
      isAvailable: json['isAvailable'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      skills: List<String>.from(json['skills'] ?? []),
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      communityId: json['communityId'],
      provider: json['provider'] != null 
          ? UserModel.fromJson(json['provider'])
          : null,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewsCount: json['reviewsCount'] ?? 0,
      status: json['status'] ?? 'active',
      portfolio: json['portfolio'],
      deliveryDays: json['deliveryDays'] ?? 7,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'title': title,
      'description': description,
      'startingPrice': startingPrice,
      'currency': currency,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'category': category,
      'serviceType': serviceType,
      'location': location,
      'isRemote': isRemote,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'tags': tags,
      'skills': skills,
      'views': views,
      'likes': likes,
      'likedBy': likedBy,
      'communityId': communityId,
      'provider': provider?.toJson(),
      'rating': rating,
      'reviewsCount': reviewsCount,
      'status': status,
      'portfolio': portfolio,
      'deliveryDays': deliveryDays,
    };
  }
  
  ServiceModel copyWith({
    String? id,
    String? providerId,
    String? title,
    String? description,
    double? startingPrice,
    String? currency,
    List<String>? imageUrls,
    List<String>? videoUrls,
    String? category,
    String? serviceType,
    String? location,
    bool? isRemote,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAvailable,
    bool? isFeatured,
    List<String>? tags,
    List<String>? skills,
    int? views,
    int? likes,
    List<String>? likedBy,
    String? communityId,
    UserModel? provider,
    double? rating,
    int? reviewsCount,
    String? status,
    String? portfolio,
    int? deliveryDays,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      description: description ?? this.description,
      startingPrice: startingPrice ?? this.startingPrice,
      currency: currency ?? this.currency,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      category: category ?? this.category,
      serviceType: serviceType ?? this.serviceType,
      location: location ?? this.location,
      isRemote: isRemote ?? this.isRemote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      tags: tags ?? this.tags,
      skills: skills ?? this.skills,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      communityId: communityId ?? this.communityId,
      provider: provider ?? this.provider,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      status: status ?? this.status,
      portfolio: portfolio ?? this.portfolio,
      deliveryDays: deliveryDays ?? this.deliveryDays,
    );
  }
}