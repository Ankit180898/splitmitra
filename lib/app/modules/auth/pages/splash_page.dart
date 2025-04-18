import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitmitra/app/core/theme/color_schemes.dart';
import 'package:splitmitra/app/core/theme/app_text_styles.dart';
import 'package:splitmitra/app/modules/auth/controller/auth_controller.dart';
import 'package:splitmitra/app/routes/app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 60,
                color: Colors.white, // Changed to white for visibility on primary color background
              ),
              const SizedBox(height: 16),
              Text('SplitMitra', 
                style: AppTextStyles.headline1.copyWith(color: Colors.white)),
              const SizedBox(height: 8),
              Text('Split bills with ease', 
                style: AppTextStyles.subtitle1.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateAfterDelay() async {
    if (_isNavigating) return;
    _isNavigating = true;

    await Future.delayed(const Duration(seconds: 2));

    try {
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        authController.resetLoadingState();

        final isLoggedIn = authController.currentUser.value != null;
        
        // Use offAll with a predicate function to clear the entire stack
        Get.offAllNamed(
          isLoggedIn ? Routes.home : Routes.login,
          predicate: (_) => false,
        );
      } else {
        Get.offAllNamed(Routes.login, predicate: (_) => false);
      }
    } catch (e) {
      print('SplashPage: Error during navigation: $e');
      Get.offAllNamed(Routes.login, predicate: (_) => false);
    }
  }
}