import 'package:get/get.dart';
import 'package:splitmitra/app/data/datasources/remote/supabase_service.dart';
import 'package:splitmitra/app/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  // Get current authenticated user
  UserModel? getCurrentUser() {
    final user = _supabaseService.currentUser;
    if (user == null) return null;
    return UserModel.fromSupabaseUser(user);
  }

  // Check if user is authenticated
  bool isAuthenticated() => _supabaseService.isAuthenticated;

  // Check if session is valid
  bool hasValidSession() {
    return _supabaseService.currentSession != null;
  }

  // Sign in with email
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseService.signInWithEmail(
        email: email,
        password: password,
      );
      if (response.user != null) {
        return UserModel.fromSupabaseUser(response.user!);
      }
      return null;
    } catch (e) {
      debugPrint('Error signing in with email: $e');
      rethrow;
    }
  }

  // Sign up with email
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseService.signUpWithEmail(
        email: email,
        password: password,
      );
      if (response.user != null) {
        return UserModel.fromSupabaseUser(response.user!);
      }
      return null;
    } catch (e) {
      debugPrint('Error signing up with email: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      await _supabaseService.signInWithGoogle();
    } catch (e) {
      debugPrint('Repository Google sign-in error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabaseService.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<UserModel?> updateUserProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      // Check if session exists first
      if (!hasValidSession()) {
        throw Exception('User is not authenticated. Cannot update profile.');
      }

      final user = await _supabaseService.updateUserProfile(
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

      if (user != null) {
        return UserModel.fromSupabaseUser(user);
      }
      return null;
    } catch (e) {
      debugPrint('Error updating user profile in repository: $e');
      rethrow;
    }
  }
}