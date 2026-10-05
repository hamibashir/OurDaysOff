import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/auth_repository.dart';
import '../providers/auth_notifier.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _handleController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Handle checking state
  Timer? _debounceTimer;
  bool _isCheckingHandle = false;
  bool? _isHandleAvailable;
  String? _handleCheckMessage;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _handleController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onHandleChanged(String val) {
    _debounceTimer?.cancel();
    final clean = val.trim().toLowerCase();

    if (clean.isEmpty) {
      setState(() {
        _isCheckingHandle = false;
        _isHandleAvailable = null;
        _handleCheckMessage = null;
      });
      return;
    }

    if (clean.length < 3) {
      setState(() {
        _isCheckingHandle = false;
        _isHandleAvailable = false;
        _handleCheckMessage = 'Handle must be at least 3 characters';
      });
      return;
    }

    final handleRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!handleRegex.hasMatch(clean)) {
      setState(() {
        _isCheckingHandle = false;
        _isHandleAvailable = false;
        _handleCheckMessage = 'Only letters, numbers, and underscores';
      });
      return;
    }

    setState(() {
      _isCheckingHandle = true;
      _handleCheckMessage = null;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final repo = ref.read(authRepositoryProvider);
      final isAvailable = await repo.checkHandle(clean);
      if (mounted) {
        setState(() {
          _isCheckingHandle = false;
          _isHandleAvailable = isAvailable;
          _handleCheckMessage = isAvailable ? '@$clean is available!' : '@$clean is already taken';
        });
      }
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isHandleAvailable == false) {
      setState(() {
        _errorMessage = 'Please choose an available username handle';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            passwordConfirmation: _confirmPasswordController.text,
            handle: _handleController.text.trim().isNotEmpty
                ? _handleController.text.trim().toLowerCase()
                : null,
          );
      // Navigation is automatically handled by GoRouter's redirect
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo & Heading
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.userPlus,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Create Your Account',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Join Our Days Off to start syncing schedules and finding free days together',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 28),

                    // Error Banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.dangerBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertCircle, size: 18, color: AppColors.danger),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Input Card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'Alice Smith',
                            textInputAction: TextInputAction.next,
                            prefixIcon: LucideIcons.user,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            hint: 'name@example.com',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: LucideIcons.mail,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _handleController,
                            label: 'Unique Handle (Optional)',
                            hint: 'alicesmith',
                            textInputAction: TextInputAction.next,
                            prefixIcon: LucideIcons.atSign,
                            onChanged: _onHandleChanged,
                            suffixIcon: _isCheckingHandle
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : _isHandleAvailable != null
                                    ? Icon(
                                        _isHandleAvailable!
                                            ? LucideIcons.checkCircle2
                                            : LucideIcons.xCircle,
                                        size: 18,
                                        color: _isHandleAvailable!
                                            ? AppColors.statusAvailable
                                            : AppColors.danger,
                                      )
                                    : null,
                          ),
                          if (_handleCheckMessage != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _handleCheckMessage!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isHandleAvailable == true
                                    ? AppColors.statusAvailable
                                    : AppColors.danger,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'At least 8 characters',
                            isPassword: true,
                            textInputAction: TextInputAction.next,
                            prefixIcon: LucideIcons.lock,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (val.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            hint: 'Re-enter your password',
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            prefixIcon: LucideIcons.shieldCheck,
                            onSubmitted: (_) => _handleRegister(),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (val != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            text: 'Create Account',
                            isLoading: _isLoading,
                            onPressed: _handleRegister,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Switch to Login
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
