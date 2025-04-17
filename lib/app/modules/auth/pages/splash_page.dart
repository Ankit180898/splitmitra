import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitmitra/app/core/theme/color_schemes.dart';
import 'package:splitmitra/app/core/theme/app_text_styles.dart';
import 'package:splitmitra/app/modules/auth/controller/auth_controller.dart';
import 'package:splitmitra/app/routes/app_routes.dart'; // Import routes

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    print('SplashPage: initState called');

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    // Log animation status
    _animationController.addStatusListener((status) {
      print('SplashPage: Animation status: $status');
    });

    // Start animation
    _animationController.forward().catchError((error) {
      print('SplashPage: Animation error: $error');
    });

    // Navigate after animation completes
    Future.delayed(const Duration(milliseconds: 4000), () {
      print('SplashPage: Navigation triggered');
      try {
        if (Get.isRegistered<AuthController>()) {
          final authController = Get.find<AuthController>();
          authController.resetLoadingState();
          print('SplashPage: AuthController resetLoadingState called');
        } else {
          print('SplashPage: AuthController not registered');
        }
        // Explicitly navigate to the next screen
        if (Get.isRegistered<AuthController>() && Get.find<AuthController>().currentUser.value != null) {
          Get.offNamed(Routes.home); // Navigate to home if logged in
        } else {
          Get.offNamed(Routes.login); // Navigate to login if not logged in
        }
      } catch (e) {
        print('SplashPage: Navigation error: $e');
        // Fallback navigation
        Get.offNamed(Routes.login);
      }
    });
  }

  @override
  void dispose() {
    print('SplashPage: dispose called');
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('SplashPage: build called');
    return Scaffold(
      backgroundColor: AppColors.primary ?? Colors.blue, // Fallback to blue
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            print('SplashPage: AnimatedBuilder - Fade: ${_fadeAnimation.value}, Scale: ${_scaleAnimation.value}');
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: child,
              ),
            );
          },
          
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 60,
                  color: AppColors.primary ?? Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SplitMitra',
                style: AppTextStyles.headline1?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ) ??
                    const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Split bills with friends, easily',
                style: AppTextStyles.subtitle1?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ) ??
                    const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}