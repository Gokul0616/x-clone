import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/marketplace_provider.dart';
import '../../models/service_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import 'package:uuid/uuid.dart';

class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _deliveryDaysController = TextEditingController(text: '7');
  
  String _selectedCategory = 'Design';
  String _selectedServiceType = 'fixed_price';
  bool _isRemote = true;
  final List<String> _selectedTags = [];
  final List<String> _selectedSkills = [];
  final List<String> _imageUrls = [];
  
  final List<String> _categories = [
    'Design', 'Development', 'Writing', 'Marketing', 'Video & Animation',
    'Music & Audio', 'Programming', 'Business', 'Lifestyle'
  ];

  final List<String> _serviceTypes = ['fixed_price', 'hourly', 'custom'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _deliveryDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offer a Service'),
        actions: [
          TextButton(
            onPressed: _createService,
            child: Text(
              'Post',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image selection placeholder
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Image picker coming soon!')),
                    );
                  },
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Add Portfolio Images', style: TextStyle(color: Colors.grey)),
                      Text('(Up to 5 images)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Service Title *',
                  hintText: 'I will...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe your service in detail...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Price
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Starting Price (\$) *',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a starting price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Service Type
              DropdownButtonFormField<String>(
                value: _selectedServiceType,
                decoration: const InputDecoration(
                  labelText: 'Service Type *',
                  border: OutlineInputBorder(),
                ),
                items: _serviceTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedServiceType = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Remote work toggle
              SwitchListTile(
                title: const Text('Remote Work Available'),
                subtitle: const Text('Can this service be delivered remotely?'),
                value: _isRemote,
                onChanged: (value) {
                  setState(() {
                    _isRemote = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: _isRemote ? 'Primary Location' : 'Service Location *',
                  hintText: _isRemote ? 'Your base location' : 'Where you provide this service',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (!_isRemote && (value == null || value.isEmpty)) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Delivery Days
              TextFormField(
                controller: _deliveryDaysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Delivery Time (Days) *',
                  hintText: '7',
                  border: OutlineInputBorder(),
                  suffixText: 'days',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter delivery time';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Skills section
              Text(
                'Skills & Technologies',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Add skills (press enter to add)',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty && !_selectedSkills.contains(value)) {
                          setState(() {
                            _selectedSkills.add(value);
                          });
                        }
                      },
                    ),
                    if (_selectedSkills.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _selectedSkills.map((skill) {
                          return Chip(
                            label: Text(skill),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _selectedSkills.remove(skill);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tags section
              Text(
                'Tags (Optional)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Add tags (press enter to add)',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty && !_selectedTags.contains(value)) {
                          setState(() {
                            _selectedTags.add(value);
                          });
                        }
                      },
                    ),
                    if (_selectedTags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _selectedTags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _selectedTags.remove(tag);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Terms and conditions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'By posting this service, you agree to our Terms of Service and acknowledge that you are responsible for delivering quality work as described.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createService() async {
    if (_formKey.currentState!.validate()) {
      final marketplaceProvider = context.read<MarketplaceProvider>();
      
      final service = ServiceModel(
        id: const Uuid().v4(),
        providerId: 'current_user_id', // This should come from AuthProvider
        title: _titleController.text,
        description: _descriptionController.text,
        startingPrice: double.parse(_priceController.text),
        category: _selectedCategory,
        serviceType: _selectedServiceType,
        location: _locationController.text,
        isRemote: _isRemote,
        createdAt: DateTime.now(),
        imageUrls: _imageUrls,
        tags: _selectedTags,
        skills: _selectedSkills,
        deliveryDays: int.parse(_deliveryDaysController.text),
      );
      
      final success = await marketplaceProvider.createService(service);
      
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service posted successfully!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(marketplaceProvider.error ?? 'Failed to post service')),
        );
      }
    }
  }
}