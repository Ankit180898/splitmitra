import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitmitra/app/core/theme/app_text_styles.dart';
import 'package:splitmitra/app/core/theme/color_schemes.dart';
import 'package:splitmitra/app/core/utils/responsive.dart';
import 'package:splitmitra/app/core/widgets/custom_button.dart';
import 'package:splitmitra/app/modules/auth/controller/auth_controller.dart';
import 'package:splitmitra/app/routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  late AuthController controller;

  @override
  void initState() {
    super.initState();
    debugPrint('LoginPage: initState');
    controller = Get.find<AuthController>();
    WidgetsBinding.instance.addObserver(this);

    // Reset loading state when the page appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('LoginPage: post frame callback - resetting loading state');
      controller.resetLoadingState();
    });
  }

  @override
  void dispose() {
    debugPrint('LoginPage: dispose');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('LoginPage: didChangeDependencies');
    // Reset loading state when dependencies change
    controller.resetLoadingState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GetX<AuthController>(
          builder: (controller) {
            return Stack(
              children: [
                _buildLoginForm(context, controller),
                if (controller.isLoading.value)
                  const Center(child: CircularProgressIndicator()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthController controller) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: Responsive.getScreenPadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo and Title
              Image.asset(
                'assets/images/logo.png',
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 60,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome Back',
                style: AppTextStyles.headline1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to manage your expenses and split bills with friends',
                style: AppTextStyles.bodyText1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Error message
              if (controller.errorMessage.value.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    controller.errorMessage.value,
                    style: AppTextStyles.bodyText2.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              if (controller.errorMessage.value.isNotEmpty)
                const SizedBox(height: 16),

              // Email TextField
              TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password TextField
              TextField(
                controller: controller.passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement forgot password
                  },
                  child: Text(
                    'Forgot Password?',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login Button
              CustomButton(
                text: 'Login',
                onPressed:
                    controller.isLoading.value
                        ? null
                        : () => controller.login(),
                buttonType:
                    controller.isLoading.value
                        ? ButtonType.disabled
                        : ButtonType.filled,
                isFullWidth: true,
              ),
              const SizedBox(height: 24),

              // OR Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: AppTextStyles.bodyText2),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              // Google Sign In Button
              CustomButton(
                text: 'Continue with Google',
                onPressed:
                    controller.isLoading.value
                        ? null
                        : () {
                          try {
                            controller.signInWithGoogle();
                          } catch (e) {
                            debugPrint('Failed to start Google Sign-In: $e');
                            controller.errorMessage.value =
                                'Failed to start Google Sign-In: $e';
                            controller.isLoading.value = false;
                          }
                        },
                buttonType:
                    controller.isLoading.value
                        ? ButtonType.disabled
                        : ButtonType.outlined,
                isFullWidth: true,
                icon: Icons.g_mobiledata,
              ),
              const SizedBox(height: 4),
              Text(
                'Using native Google Sign-In',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.grey,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppTextStyles.bodyText2,
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(Routes.signUp),
                    child: Text(
                      'Sign Up',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
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
