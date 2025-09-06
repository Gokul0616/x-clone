import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../providers/story_provider.dart';
import '../../models/story_model.dart';
import '../../constants/app_colors.dart';
import '../../widgets/story/text_story_creator.dart';

class StoryCreatorScreen extends StatefulWidget {
  const StoryCreatorScreen({Key? key}) : super(key: key);

  @override
  State<StoryCreatorScreen> createState() => _StoryCreatorScreenState();
}

class _StoryCreatorScreenState extends State<StoryCreatorScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  bool _isFlashOn = false;
  bool _isRearCamera = true;
  final ImagePicker _imagePicker = ImagePicker();

  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: true,
        );
        
        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isCameraReady = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final currentCamera = _cameraController!.description;
    CameraDescription newCamera;

    if (_isRearCamera) {
      newCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras![0],
      );
    } else {
      newCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras![0],
      );
    }

    await _cameraController!.dispose();
    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await _cameraController!.initialize();
      setState(() {
        _isRearCamera = !_isRearCamera;
      });
    } catch (e) {
      print('Error switching camera: $e');
    }
  }

  Future<void> _toggleFlash() async {
    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (!_isCameraReady) return;

    try {
      _buttonAnimationController.forward().then((_) {
        _buttonAnimationController.reverse();
      });

      final XFile photo = await _cameraController!.takePicture();
      await _uploadStory(StoryType.image, photo.path);
    } catch (e) {
      print('Error capturing photo: $e');
      _showErrorSnackBar('Failed to capture photo');
    }
  }

  Future<void> _recordVideo() async {
    if (!_isCameraReady) return;

    try {
      await _cameraController!.startVideoRecording();
      // For demo purposes, auto-stop after 15 seconds
      // In a real app, you'd have start/stop recording controls
      await Future.delayed(const Duration(seconds: 15));
      final XFile video = await _cameraController!.stopVideoRecording();
      await _uploadStory(StoryType.video, video.path);
    } catch (e) {
      print('Error recording video: $e');
      _showErrorSnackBar('Failed to record video');
    }
  }

  Future<void> _pickFromGallery(StoryType type) async {
    try {
      XFile? file;
      
      if (type == StoryType.image) {
        file = await _imagePicker.pickImage(source: ImageSource.gallery);
      } else {
        file = await _imagePicker.pickVideo(source: ImageSource.gallery);
      }

      if (file != null) {
        await _uploadStory(type, file.path);
      }
    } catch (e) {
      print('Error picking from gallery: $e');
      _showErrorSnackBar('Failed to pick from gallery');
    }
  }

  Future<void> _uploadStory(StoryType type, String filePath) async {
    final storyProvider = Provider.of<StoryProvider>(context, listen: false);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    final success = await storyProvider.uploadStory(
      type: type,
      mediaPath: filePath,
      privacy: StoryPrivacy.everyone,
    );

    Navigator.of(context).pop(); // Close loading dialog

    if (success) {
      Navigator.of(context).pop(); // Close story creator
      _showSuccessSnackBar('Story uploaded successfully!');
    } else {
      _showErrorSnackBar('Failed to upload story');
    }
  }

  void _createTextStory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TextStoryCreator(),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isCameraReady)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Top controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                // Flash toggle
                if (_isRearCamera)
                  GestureDetector(
                    onTap: _toggleFlash,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                // Camera switch
                GestureDetector(
                  onTap: _switchCamera,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: const Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Story type selector
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStoryTypeButton(
                        'Text',
                        Icons.text_fields,
                        _createTextStory,
                      ),
                      _buildStoryTypeButton(
                        'Photo',
                        Icons.photo_library,
                        () => _pickFromGallery(StoryType.image),
                      ),
                      _buildStoryTypeButton(
                        'Video',
                        Icons.video_library,
                        () => _pickFromGallery(StoryType.video),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // Capture controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery shortcut
                    GestureDetector(
                      onTap: () => _pickFromGallery(StoryType.image),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    // Capture button
                    AnimatedBuilder(
                      animation: _buttonScaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _buttonScaleAnimation.value,
                          child: GestureDetector(
                            onTap: _capturePhoto,
                            onLongPressStart: (_) => _recordVideo(),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 4,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Text story shortcut
                    GestureDetector(
                      onTap: _createTextStory,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.text_fields,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryTypeButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}