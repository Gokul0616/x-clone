import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/story_provider.dart';
import '../../models/story_model.dart';
import '../../constants/app_colors.dart';

class TextStoryCreator extends StatefulWidget {
  const TextStoryCreator({super.key});

  @override
  State<TextStoryCreator> createState() => _TextStoryCreatorState();
}

class _TextStoryCreatorState extends State<TextStoryCreator> {
  final TextEditingController _textController = TextEditingController();
  Color _backgroundColor = AppColors.primaryBlue;
  Color _textColor = Colors.white;
  double _fontSize = 24.0;
  String _fontFamily = 'Chirp';

  final List<Color> _backgroundColors = [
    AppColors.primaryBlue,
    const Color(0xFFE91E63),
    const Color(0xFF9C27B0),
    const Color(0xFF673AB7),
    const Color(0xFF3F51B5),
    const Color(0xFF2196F3),
    const Color(0xFF03DAC6),
    const Color(0xFF4CAF50),
    const Color(0xFF8BC34A),
    const Color(0xFFCDDC39),
    const Color(0xFFFFEB3B),
    const Color(0xFFFFC107),
    const Color(0xFFFF9800),
    const Color(0xFFFF5722),
  ];

  final List<String> _fontFamilies = [
    'Chirp',
    'Arial',
    'Times New Roman',
    'Courier New',
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _uploadTextStory() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final storyProvider = Provider.of<StoryProvider>(context, listen: false);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    final success = await storyProvider.uploadStory(
      type: StoryType.text,
      textContent: _textController.text.trim(),
      backgroundColor:
          '#${_backgroundColor.value.toRadixString(16).substring(2)}',
      textColor: '#${_textColor.value.toRadixString(16).substring(2)}',
      fontSize: _fontSize,
      fontFamily: _fontFamily,
      privacy: StoryPrivacy.everyone,
    );

    Navigator.of(context).pop(); // Close loading dialog

    if (success) {
      Navigator.of(context).pop(); // Close text story creator
      Navigator.of(context).pop(); // Close story creator screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text story uploaded successfully!'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to upload story'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _uploadTextStory,
            child: const Text(
              'Share',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Text input area
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: TextField(
                  controller: _textController,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: _fontSize,
                    fontFamily: _fontFamily,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Type your story...',
                    hintStyle: TextStyle(
                      color: _textColor.withOpacity(0.7),
                      fontSize: _fontSize,
                      fontFamily: _fontFamily,
                    ),
                    border: InputBorder.none,
                  ),
                  autofocus: true,
                ),
              ),
            ),
          ),

          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Background colors
                const Text(
                  'Background Color',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _backgroundColors.length,
                    itemBuilder: (context, index) {
                      final color = _backgroundColors[index];
                      final isSelected = color == _backgroundColor;

                      return GestureDetector(
                        onTap: () => setState(() => _backgroundColor = color),
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Text customization
                Row(
                  children: [
                    // Text color
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Text Color',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _textColor = Colors.white),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: _textColor == Colors.white
                                        ? Border.all(
                                            color: AppColors.primaryBlue,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _textColor = Colors.black),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                    border: _textColor == Colors.black
                                        ? Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          )
                                        : Border.all(
                                            color: Colors.white54,
                                            width: 1,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Font size
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Font Size',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _fontSize,
                            min: 16.0,
                            max: 48.0,
                            divisions: 16,
                            activeColor: Colors.white,
                            inactiveColor: Colors.white.withOpacity(0.3),
                            onChanged: (value) =>
                                setState(() => _fontSize = value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Font family
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Font',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _fontFamilies.length,
                    itemBuilder: (context, index) {
                      final font = _fontFamilies[index];
                      final isSelected = font == _fontFamily;

                      return GestureDetector(
                        onTap: () => setState(() => _fontFamily = font),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            font,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontFamily: font,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
