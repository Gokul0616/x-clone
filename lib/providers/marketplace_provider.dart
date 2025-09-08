import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/service_model.dart';
import '../models/user_model.dart';

class MarketplaceProvider with ChangeNotifier {
  List<ProductModel> _products = [];
  List<ServiceModel> _services = [];
  final List<ProductModel> _likedProducts = [];
  final List<ServiceModel> _likedServices = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get products => _products;
  List<ServiceModel> get services => _services;
  List<ProductModel> get likedProducts => _likedProducts;
  List<ServiceModel> get likedServices => _likedServices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load products (mock data for now)
  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      _products = _getMockProducts();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load products: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Load services (mock data for now)
  Future<void> loadServices() async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      _services = _getMockServices();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load services: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Filter products
  List<ProductModel> getFilteredProducts({
    String? query,
    String? category,
    String? location,
  }) {
    List<ProductModel> filtered = _products;

    if (query != null && query.isNotEmpty) {
      filtered = filtered
          .where(
            (product) =>
                product.title.toLowerCase().contains(query.toLowerCase()) ||
                product.description.toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                product.tags.any(
                  (tag) => tag.toLowerCase().contains(query.toLowerCase()),
                ),
          )
          .toList();
    }

    if (category != null && category != 'All') {
      filtered = filtered
          .where((product) => product.category == category)
          .toList();
    }

    if (location != null && location != 'All') {
      // Filter by location logic here
    }

    return filtered;
  }

  // Filter services
  List<ServiceModel> getFilteredServices({
    String? query,
    String? category,
    String? location,
  }) {
    List<ServiceModel> filtered = _services;

    if (query != null && query.isNotEmpty) {
      filtered = filtered
          .where(
            (service) =>
                service.title.toLowerCase().contains(query.toLowerCase()) ||
                service.description.toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                service.tags.any(
                  (tag) => tag.toLowerCase().contains(query.toLowerCase()),
                ),
          )
          .toList();
    }

    if (category != null && category != 'All') {
      filtered = filtered
          .where((service) => service.category == category)
          .toList();
    }

    if (location != null && location != 'All') {
      // Filter by location logic here
    }

    return filtered;
  }

  // Like/Unlike product
  void toggleProductLike(String productId) {
    final product = _products.firstWhere((p) => p.id == productId);
    final isLiked = _likedProducts.any((p) => p.id == productId);

    if (isLiked) {
      _likedProducts.removeWhere((p) => p.id == productId);
    } else {
      _likedProducts.add(product);
    }

    notifyListeners();
  }

  // Like/Unlike service
  void toggleServiceLike(String serviceId) {
    final service = _services.firstWhere((s) => s.id == serviceId);
    final isLiked = _likedServices.any((s) => s.id == serviceId);

    if (isLiked) {
      _likedServices.removeWhere((s) => s.id == serviceId);
    } else {
      _likedServices.add(service);
    }

    notifyListeners();
  }

  // Check if product is liked
  bool isProductLiked(String productId) {
    return _likedProducts.any((p) => p.id == productId);
  }

  // Check if service is liked
  bool isServiceLiked(String serviceId) {
    return _likedServices.any((s) => s.id == serviceId);
  }

  // Create product
  Future<bool> createProduct(ProductModel product) async {
    try {
      _setLoading(true);
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      _products.insert(0, product);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create product: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Create service
  Future<bool> createService(ServiceModel service) async {
    try {
      _setLoading(true);
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      _services.insert(0, service);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create service: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Mock data generators
  List<ProductModel> _getMockProducts() {
    final mockUser = UserModel(
      id: 'seller_1',
      username: 'johndoe',
      displayName: 'John Doe',
      email: 'john@example.com',
      joinedDate: DateTime.now().subtract(const Duration(days: 365)),
    );

    return [
      ProductModel(
        id: 'product_1',
        sellerId: 'seller_1',
        title: 'iPhone 14 Pro Max',
        description:
            'Like new iPhone 14 Pro Max, 256GB, Space Black. Includes original box and accessories.',
        price: 899.99,
        category: 'Electronics',
        condition: 'used',
        location: 'New York, NY',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        imageUrls: ['https://picsum.photos/300/300?random=1'],
        tags: ['iphone', 'apple', 'smartphone'],
        seller: mockUser,
      ),
      ProductModel(
        id: 'product_2',
        sellerId: 'seller_2',
        title: 'MacBook Air M2',
        description:
            'Excellent condition MacBook Air with M2 chip, 16GB RAM, 512GB SSD.',
        price: 1299.99,
        category: 'Electronics',
        condition: 'used',
        location: 'Los Angeles, CA',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        imageUrls: ['https://picsum.photos/300/300?random=2'],
        tags: ['macbook', 'apple', 'laptop'],
        seller: mockUser,
      ),
      ProductModel(
        id: 'product_3',
        sellerId: 'seller_3',
        title: 'Vintage Leather Jacket',
        description:
            'Authentic vintage leather jacket from the 90s. Size M. Great condition.',
        price: 149.99,
        category: 'Fashion',
        condition: 'used',
        location: 'Chicago, IL',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        imageUrls: ['https://picsum.photos/300/300?random=3'],
        tags: ['leather', 'vintage', 'jacket'],
        seller: mockUser,
      ),
    ];
  }

  List<ServiceModel> _getMockServices() {
    final mockProvider = UserModel(
      id: 'provider_1',
      username: 'designpro',
      displayName: 'Design Pro',
      email: 'design@example.com',
      joinedDate: DateTime.now().subtract(const Duration(days: 200)),
    );

    return [
      ServiceModel(
        id: 'service_1',
        providerId: 'provider_1',
        title: 'Professional Logo Design',
        description:
            'I will create a unique and professional logo for your business within 48 hours.',
        startingPrice: 49.99,
        category: 'Design',
        location: 'Remote',
        isRemote: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        imageUrls: ['https://picsum.photos/300/200?random=4'],
        tags: ['logo', 'design', 'branding'],
        skills: ['Adobe Illustrator', 'Photoshop', 'Figma'],
        provider: mockProvider,
        rating: 4.8,
        reviewsCount: 127,
        deliveryDays: 2,
      ),
      ServiceModel(
        id: 'service_2',
        providerId: 'provider_2',
        title: 'Website Development',
        description:
            'Full-stack web development services using modern technologies.',
        startingPrice: 299.99,
        category: 'Development',
        location: 'San Francisco, CA',
        isRemote: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        imageUrls: ['https://picsum.photos/300/200?random=5'],
        tags: ['website', 'development', 'react'],
        skills: ['React', 'Node.js', 'MongoDB'],
        provider: mockProvider,
        rating: 4.9,
        reviewsCount: 89,
        deliveryDays: 7,
      ),
    ];
  }
}
