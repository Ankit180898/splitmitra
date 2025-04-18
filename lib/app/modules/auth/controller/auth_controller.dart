import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart'; // Add this
import 'package:splitmitra/app/core/utils/helpers.dart';
import 'package:splitmitra/app/routes/app_routes.dart';
import 'package:splitmitra/app/data/repositories/auth_repository.dart';
import 'package:splitmitra/app/data/models/user_model.dart';
import 'package:splitmitra/app/data/datasources/remote/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  // State variables
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;


  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    
    // Simplify initial auth check
    Future.delayed(Duration.zero, () {
      checkAuthState();
    });
    
    // Simplified auth state listener
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      
      if (event == AuthChangeEvent.signedIn) {
        if (data.session != null) {
          _fetchUserData();
          // Set OneSignal external user ID
          if (_supabaseService.currentUser != null) {
            OneSignal.login(_supabaseService.currentUser!.id);
          }
          // Let the session establish itself and only THEN navigate
          Future.delayed(Duration(milliseconds: 100), () {
            Get.offAllNamed(Routes.home);
          });
        }
      } else if (event == AuthChangeEvent.signedOut) {
        currentUser.value = null;
        // Clear OneSignal external user ID
        OneSignal.logout();
        Get.offAllNamed(Routes.login);
        isLoading.value = false;
      }
    });
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    displayNameController.dispose();
    super.onClose();
  }

  // Simplified auth state check
  Future<void> checkAuthState() async {
    isLoading.value = true;
    try {
      final user = _authRepository.getCurrentUser();
      if (user != null) {
        currentUser.value = user;
        // Set OneSignal external user ID
        if (_supabaseService.currentUser != null) {
          OneSignal.login(_supabaseService.currentUser!.id);
        }
        await Get.offAllNamed(Routes.home);
      } else {
        await Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      errorMessage.value = e.toString();
      await Get.offAllNamed(Routes.login);
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch authenticated user data
  Future<void> _fetchUserData() async {
    try {
      final user = _authRepository.getCurrentUser();
      if (user != null) {
        await _supabaseService.syncAuthenticatedUserToDatabase();
        currentUser.value = user;
      }
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  // Login with email and password
   Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      errorMessage.value = 'Please fill in all fields';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _authRepository.signInWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    
      clearControllers();
    } catch (e) {
      errorMessage.value = e.toString();
      isLoading.value = false;
    }
  }

  // Register new user
  Future<void> register() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      errorMessage.value = 'Please fill in all fields';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final user = await _authRepository.signUpWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (user != null) {
        if (displayNameController.text.isNotEmpty) {
          await _authRepository.updateUserProfile(
            displayName: displayNameController.text.trim(),
          );
        }

        await _supabaseService.syncAuthenticatedUserToDatabase();
        currentUser.value = user;
        // Set OneSignal external user ID
        if (_supabaseService.currentUser != null) {
          OneSignal.login(_supabaseService.currentUser!.id);
          print('OneSignal: Set external user ID after registration: ${_supabaseService.currentUser!.id}');
        }
        clearControllers();
      } else {
        errorMessage.value = 'Failed to register. Please try again.';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Google Sign-In
  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await _supabaseService.signInWithGoogle();

      final user = response.user!;
      currentUser.value = UserModel(
        id: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['full_name'] ?? '',
        avatarUrl: user.userMetadata?['avatar_url'] ?? '',
        createdAt: DateTime.now(),
      );

      await _supabaseService.syncAuthenticatedUserToDatabase();
      // Set OneSignal external user ID
      if (_supabaseService.currentUser != null) {
        OneSignal.login(_supabaseService.currentUser!.id);
        print('OneSignal: Set external user ID after Google login: ${_supabaseService.currentUser!.id}');
      }
      showSuccessSnackBar(message: 'Signed in successfully');
    } catch (e) {
      errorMessage.value = e.toString();
      showErrorSnackBar(message: 'Google Sign-In failed: $e');
      print('Google Sign-In error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    isLoading.value = true;

    try {
      await _authRepository.signOut();
      currentUser.value = null;
      // Clear OneSignal external user ID
      OneSignal.logout();
      print('OneSignal: Logged out external user ID');
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final updatedUser = await _authRepository.updateUserProfile(
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

      if (updatedUser != null) {
        currentUser.value = updatedUser;
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Reset loading state
  void resetLoadingState() {
    isLoading.value = false;
    errorMessage.value = '';
  }

  // Clear text controllers
  void clearControllers() {
    emailController.clear();
    passwordController.clear();
    displayNameController.clear();
  }
}