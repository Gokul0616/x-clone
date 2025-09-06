import 'user_model.dart';

class ProductModel {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final double price;
  final String currency;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String category;
  final String condition; // new, used, refurbished
  final String location;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isAvailable;
  final bool isFeatured;
  final List<String> tags;
  final int views;
  final int likes;
  final List<String> likedBy;
  final String? communityId;
  final UserModel? seller;
  final Map<String, dynamic>? specifications;
  final String status; // active, sold, pending, draft
  
  ProductModel({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    this.currency = 'USD',
    this.imageUrls = const [],
    this.videoUrls = const [],
    required this.category,
    this.condition = 'used',
    required this.location,
    required this.createdAt,
    this.updatedAt,
    this.isAvailable = true,
    this.isFeatured = false,
    this.tags = const [],
    this.views = 0,
    this.likes = 0,
    this.likedBy = const [],
    this.communityId,
    this.seller,
    this.specifications,
    this.status = 'active',
  });
  
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      sellerId: json['sellerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      videoUrls: List<String>.from(json['videoUrls'] ?? []),
      category: json['category'] ?? '',
      condition: json['condition'] ?? 'used',
      location: json['location'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : null,
      isAvailable: json['isAvailable'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      communityId: json['communityId'],
      seller: json['seller'] != null 
          ? UserModel.fromJson(json['seller'])
          : null,
      specifications: json['specifications'],
      status: json['status'] ?? 'active',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'category': category,
      'condition': condition,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'tags': tags,
      'views': views,
      'likes': likes,
      'likedBy': likedBy,
      'communityId': communityId,
      'seller': seller?.toJson(),
      'specifications': specifications,
      'status': status,
    };
  }
  
  ProductModel copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? description,
    double? price,
    String? currency,
    List<String>? imageUrls,
    List<String>? videoUrls,
    String? category,
    String? condition,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAvailable,
    bool? isFeatured,
    List<String>? tags,
    int? views,
    int? likes,
    List<String>? likedBy,
    String? communityId,
    UserModel? seller,
    Map<String, dynamic>? specifications,
    String? status,
  }) {
    return ProductModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      tags: tags ?? this.tags,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      communityId: communityId ?? this.communityId,
      seller: seller ?? this.seller,
      specifications: specifications ?? this.specifications,
      status: status ?? this.status,
    );
  }
}