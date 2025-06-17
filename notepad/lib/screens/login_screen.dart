import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../utils/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isOfflineMode = false;
  // Platform kontrolü - Web'de offline mode yok
  bool get showOfflineOption => !kIsWeb;
  bool get isWeb => kIsWeb;
  bool get isMobile => !kIsWeb;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo/Title
                        const Icon(
                          Icons.task_alt,
                          size: 64,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Task Manager',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Görevlerinizi takip edin',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Mode Toggle - Sadece mobile'da göster
                        if (showOfflineOption) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isOfflineMode
                                      ? Icons.offline_bolt
                                      : Icons.cloud,
                                  color:
                                      _isOfflineMode
                                          ? AppColors.warning
                                          : AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isOfflineMode
                                        ? 'Offline Mod'
                                        : 'Online Mod',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: _isOfflineMode,
                                  onChanged: (value) {
                                    setState(() {
                                      _isOfflineMode = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          // Web için sadece bilgi mesajı
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.cloud, color: AppColors.primary),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Web sürümünde verileriniz Firebase\'de güvenle saklanır',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ], // Email Field - Web'de her zaman, Mobile'da online modda göster
                        if (isWeb || !_isOfflineMode) ...[
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-posta',
                              prefixIcon: Icon(Icons.email),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'E-posta adresinizi girin';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Geçerli bir e-posta adresi girin';
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
                              labelText: 'Şifre',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
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
                                return 'Şifrenizi girin';
                              }
                              if (value.length < 6) {
                                return 'Şifre en az 6 karakter olmalıdır';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                        ] else if (isMobile && _isOfflineMode) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.warning.withOpacity(0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info, color: AppColors.warning),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Offline modda:\n• İnternet bağlantısı gerekmez\n• Verileriniz sadece bu cihazda saklanır\n• Şifre gerektirmez',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Login Button
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    authProvider.isLoading
                                        ? null
                                        : () => _handleLogin(context),
                                child:
                                    authProvider.isLoading
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : Text(
                                          isWeb
                                              ? 'Giriş Yap'
                                              : (_isOfflineMode
                                                  ? 'Offline Başla'
                                                  : 'Giriş Yap'),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Error Message
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            if (authProvider.errorMessage != null) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.error.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        authProvider.errorMessage!,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        // Sign Up Button - Only show for online mode
                        if (!_isOfflineMode) ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => _handleSignUp(context),
                            child: Text(
                              'Hesabınız yok mu? Kayıt olun',
                              style: TextStyle(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    // Web'de sadece Firebase, Mobile'da offline seçeneği var
    if (isMobile && _isOfflineMode) {
      // Offline mode - sadece mobile'da
      await taskProvider.setOfflineMode(true);
      await taskProvider.initialize(null);
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
      return;
    }

    // Online mode (Web her zaman, Mobile'da seçilirse)
    if (_formKey.currentState!.validate()) {
      authProvider.clearError();

      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Future<void> _handleSignUp(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_formKey.currentState!.validate()) {
      authProvider.clearError();

      final success = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (success && context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }
}
