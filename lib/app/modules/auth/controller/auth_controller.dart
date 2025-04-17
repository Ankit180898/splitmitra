import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitmitra/app/routes/app_routes.dart';
import 'package:splitmitra/app/data/repositories/auth_repository.dart';
import 'package:splitmitra/app/data/models/user_model.dart';
import 'package:splitmitra/app/data/datasources/remote/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  // State variables
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Flag to prevent duplicate navigation
  bool _isNavigating = false;

  // Form controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    // Make sure loading is reset when controller initializes
    isLoading.value = false;

    // Moved checkAuthState to a delayed call to ensure GetMaterialApp is initialized
    Future.delayed(Duration.zero, () {
      if (!_isNavigating) {
        _isNavigating = true;
        checkAuthState();
      }
    });

    // Listen for auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      if (event == AuthChangeEvent.signedIn) {
        if (data.session != null) {
          _fetchUserData();
          // Avoid navigation during initial setup
          if (_isNavigating) return;
          _isNavigating = true;
          Get.offAllNamed(Routes.home);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        currentUser.value = null;
        // Avoid navigation during initial setup
        if (_isNavigating) return;
        _isNavigating = true;
        Get.offAllNamed(Routes.login);
        // Ensure loading is turned off when signing out
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

  // Check if user is already authenticated
  Future<void> checkAuthState() async {
    isLoading.value = true;
    try {
      final user = _authRepository.getCurrentUser();
      if (user != null) {
        currentUser.value = user;
        // Use offAll to ensure only one page is in the navigation stack
        await Get.offAllNamed(Routes.home);
      } else {
        // Use offAll to ensure only one page is in the navigation stack
        await Get.offAllNamed(Routes.login);
        // Ensure loading is turned off when reaching login screen
        isLoading.value = false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      await Get.offAllNamed(Routes.login);
      // Ensure loading is turned off when reaching login screen
      isLoading.value = false;
    } finally {
      // We only need to set isLoading to false if we haven't navigated away
      if (Get.currentRoute != Routes.home) {
        isLoading.value = false;
      }
    }
  }

  // Fetch authenticated user data
  Future<void> _fetchUserData() async {
    try {
      final user = _authRepository.getCurrentUser();
      if (user != null) {
        // Ensure user exists in the database
        await Get.find<SupabaseService>().syncAuthenticatedUserToDatabase();

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
      final user = await _authRepository.signInWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (user != null) {
        // Ensure user exists in the database
        await Get.find<SupabaseService>().syncAuthenticatedUserToDatabase();

        currentUser.value = user;
        clearControllers();
        Get.offAllNamed(Routes.home);
      } else {
        errorMessage.value = 'Failed to login. Please try again.';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
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
        // Update display name if provided
        if (displayNameController.text.isNotEmpty) {
          await _authRepository.updateUserProfile(
            displayName: displayNameController.text.trim(),
          );
        }

        // Ensure user exists in the database
        await Get.find<SupabaseService>().syncAuthenticatedUserToDatabase();

        currentUser.value = user;
        clearControllers();
        Get.offAllNamed(Routes.home);
      } else {
        errorMessage.value = 'Failed to register. Please try again.';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Google Sign In
  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    errorMessage.value = '';

    // Add a timeout to ensure loading state doesn't get stuck
    Future.delayed(const Duration(seconds: 30), () {
      if (isLoading.value) {
        debugPrint('Google Sign-In timeout - resetting loading state');
        isLoading.value = false;
        errorMessage.value = 'Sign-in process timed out. Please try again.';
      }
    });

    try {
      debugPrint('Starting Google Sign-In process...');

      // Check if we're on iOS (important for configuration)
      final bool isIOS = Theme.of(Get.context!).platform == TargetPlatform.iOS;
      debugPrint('Platform is ${isIOS ? "iOS" : "Android/Other"}');

      // Initialize GoogleSignIn with minimal configuration
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
        // On iOS, the clientId can be important
        // clientId: isIOS ? 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com' : null,
      );

      // A simpler approach - don't forcefully sign out first
      debugPrint('Attempting to sign in with Google');

      // Attempt to sign in with more defensive code
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signIn();
        debugPrint('Google sign-in attempt completed');
      } catch (e) {
        debugPrint('Error during Google sign-in attempt: $e');
        errorMessage.value = 'Failed to connect to Google: ${e.toString()}';
        isLoading.value = false;
        return;
      }

      // Handle canceled sign-in
      if (googleUser == null) {
        debugPrint('Google Sign-In was canceled or returned null');
        errorMessage.value = 'Sign in was canceled';
        isLoading.value = false;
        return;
      }

      debugPrint('Successfully signed in with Google as: ${googleUser.email}');

      // Get authentication tokens - be defensive here
      GoogleSignInAuthentication? googleAuth;
      try {
        googleAuth = await googleUser.authentication;
        debugPrint('Got authentication tokens from Google');
      } catch (e) {
        debugPrint('Failed to get Google authentication tokens: $e');
        errorMessage.value = 'Authentication failed: ${e.toString()}';
        isLoading.value = false;
        return;
      }

      // Make sure we actually have a token
      if (googleAuth.idToken == null) {
        debugPrint('Google auth returned null idToken');
        errorMessage.value = 'Could not get authentication token from Google';
        isLoading.value = false;
        return;
      }

      // Now try Supabase
      try {
        debugPrint('Attempting to authenticate with Supabase');
        final response = await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: googleAuth.idToken!,
        );

        debugPrint('Supabase auth response received');

        if (response.user != null) {
          debugPrint(
            'Successfully signed in to Supabase as: ${response.user!.email}',
          );

          // Ensure user exists in the database
          await Get.find<SupabaseService>().syncAuthenticatedUserToDatabase();

          currentUser.value = UserModel.fromSupabaseUser(response.user!);
          Get.offAllNamed(Routes.home);
        } else {
          debugPrint('Supabase returned null user');
          errorMessage.value = 'Failed to authenticate with Supabase';
          isLoading.value = false;
        }
      } catch (e) {
        debugPrint('Supabase authentication error: $e');
        errorMessage.value = 'Server authentication failed: ${e.toString()}';
        isLoading.value = false;
      }
    } catch (e) {
      // Global catch-all
      debugPrint('Unexpected error in Google Sign-In flow: ${e.toString()}');
      errorMessage.value = 'Sign-in failed: ${e.toString()}';
      isLoading.value = false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    isLoading.value = true;

    try {
      await _authRepository.signOut();
      currentUser.value = null;
      Get.offAllNamed(Routes.login);
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

  // Reset loading state - can be called from UI
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
