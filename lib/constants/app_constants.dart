class AppConstants {
  // API Configuration
  static const bool useMockApi = false; // Set to false for production API
  static const String baseUrl = useMockApi
      ? 'mock_api'
      : 'http://192.168.1.19:3000';
  static const String apiVersion = '/api/v1';

  // App Information
  static const String appName = 'Pulse';
  static const String appVersion = '1.0.0';
  static const bool isWeb = identical(0, 0.0); // True for web, false for mobile
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String tweetsEndpoint = '/tweets';
  static const String usersEndpoint = '/users';
  static const String communitiesEndpoint = '/communities';
  static const String messagesEndpoint = '/messages';
  static const String notificationsEndpoint = '/notifications';
  static const String searchEndpoint = '/search';

  // UI Constants
  static const double borderRadius = 12.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Tweet Configuration
  static const int maxTweetLength = 280;
  static const int maxImagesPerTweet = 4;

  // Pagination
  static const int defaultPageSize = 20;

  // Storage Keys
  static const String themeKey = 'theme_mode';
  static const String userKey = 'current_user';
  static const String tokenKey = 'auth_token';
}
