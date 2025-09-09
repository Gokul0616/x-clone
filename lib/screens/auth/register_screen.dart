import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onToggleAuth;
  final bool isAddingAccount;

  const RegisterScreen({
    super.key, 
    this.onToggleAuth,
    this.isAddingAccount = false,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      
      final success = await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text,
        _usernameController.text.trim(),
        _displayNameController.text.trim(),
        isAddingAccount: widget.isAddingAccount,
      );
      
      if (success) {
        if (widget.isAddingAccount && mounted) {
          // Pop back to main screen when adding account
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created and added successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Registration failed'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo and Title
                          Icon(
                            Icons.electric_bolt_rounded,
                            size: 60,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Join ${AppStrings.appName}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your account to get started',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: isDarkMode 
                                  ? AppColors.textSecondaryDark 
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Display Name Field
                          TextFormField(
                            controller: _displayNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: AppStrings.fullName,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              if (value.length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Username Field
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: AppStrings.username,
                              prefixIcon: const Icon(Icons.alternate_email),
                              helperText: 'This will be your unique handle',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a username';
                              }
                              if (value.length < 3) {
                                return 'Username must be at least 3 characters';
                              }
                              if (value.contains(' ')) {
                                return 'Username cannot contain spaces';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: AppStrings.email,
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: AppStrings.password,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: AppStrings.confirmPassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // Register Button
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _handleRegister,
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(AppStrings.register),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.alreadyHaveAccount,
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: widget.onToggleAuth,
                    child: Text(AppStrings.login),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}