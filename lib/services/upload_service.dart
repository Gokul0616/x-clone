import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_constants.dart';

class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  final String baseUrl = AppConstants.baseUrl;
  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Upload images for tweets
  Future<List<String>?> uploadImages(List<XFile> imageFiles) async {
    if (imageFiles.isEmpty) return null;

    try {
      final uri = Uri.parse('$baseUrl${AppConstants.apiVersion}/upload/images');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll(_headers);

      // Add image files
      for (final imageFile in imageFiles) {
        final file = await http.MultipartFile.fromPath(
          'images',
          imageFile.path,
          filename: imageFile.name,
        );
        request.files.add(file);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['imageUrls']);
      } else {
        print('Image upload error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading images: $e');
      return null;
    }
  }

  // Upload videos for tweets
  Future<List<String>?> uploadVideos(List<XFile> videoFiles) async {
    if (videoFiles.isEmpty) return null;

    try {
      final uri = Uri.parse('$baseUrl${AppConstants.apiVersion}/upload/videos');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll(_headers);

      // Add video files
      for (final videoFile in videoFiles) {
        final file = await http.MultipartFile.fromPath(
          'videos',
          videoFile.path,
          filename: videoFile.name,
        );
        request.files.add(file);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['videoUrls']);
      } else {
        print('Video upload error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading videos: $e');
      return null;
    }
  }

  // Upload profile or banner image
  Future<String?> uploadProfileImage(
    XFile imageFile, 
    String type, // 'profile' or 'banner'
  ) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.apiVersion}/upload/profile');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll(_headers);

      // Add image file
      final file = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: imageFile.name,
      );
      request.files.add(file);

      // Add type field
      request.fields['type'] = type;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['imageUrl'];
      } else {
        print('Profile image upload error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Pick images from gallery or camera
  Future<List<XFile>?> pickImages({
    int maxImages = 4,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      if (source == ImageSource.camera) {
        final XFile? image = await picker.pickImage(source: source);
        return image != null ? [image] : null;
      } else {
        final List<XFile> images = await picker.pickMultiImage();
        return images.length > maxImages ? images.take(maxImages).toList() : images;
      }
    } catch (e) {
      print('Error picking images: $e');
      return null;
    }
  }

  // Pick videos from gallery or camera
  Future<List<XFile>?> pickVideos({
    int maxVideos = 2,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      if (source == ImageSource.camera) {
        final XFile? video = await picker.pickVideo(source: source);
        return video != null ? [video] : null;
      } else {
        // For gallery, we'll use file picker for multiple video selection
        final result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          allowMultiple: true,
        );
        
        if (result != null && result.files.isNotEmpty) {
          final videos = result.files
              .where((file) => file.path != null)
              .map((file) => XFile(file.path!))
              .take(maxVideos)
              .toList();
          return videos.isNotEmpty ? videos : null;
        }
        return null;
      }
    } catch (e) {
      print('Error picking videos: $e');
      return null;
    }
  }

  // Pick single image for profile/banner
  Future<XFile?> pickSingleImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      return await picker.pickImage(source: source);
    } catch (e) {
      print('Error picking single image: $e');
      return null;
    }
  }

  // Get file size in MB
  double getFileSizeInMB(String filePath) {
    final file = File(filePath);
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  // Validate file size
  bool isFileSizeValid(String filePath, {double maxSizeMB = 10.0}) {
    return getFileSizeInMB(filePath) <= maxSizeMB;
  }

  // Delete uploaded file
  Future<bool> deleteFile(String fileUrl) async {
    try {
      // Extract filename and type from URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length < 3) return false;
      
      final type = pathSegments[pathSegments.length - 2]; // 'images' or 'videos'
      final filename = pathSegments.last;
      
      final deleteUri = Uri.parse('$baseUrl${AppConstants.apiVersion}/upload/$type/$filename');
      final response = await http.delete(
        deleteUri,
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
}