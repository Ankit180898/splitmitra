import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class SupabaseService extends GetxService {
  static SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    try {
      final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final String supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
        throw Exception('Supabase credentials not found in .env file');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
        debug: kDebugMode,
      );

      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      rethrow;
    }
  }

  // AUTH METHODS

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('Error signing in with email: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('Error signing up with email: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      // Better platform detection
      final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;
      final bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
      final bool isMobile = isIOS || isAndroid;

      // Get redirect URL from env, or use default deep link
      final String? redirectUrl =
          kIsWeb
              ? null
              : dotenv.env['GOOGLE_OAUTH_REDIRECT_URL'] ??
                  'io.supabase.splitmitra://login-callback/';

      debugPrint('Platform: ${defaultTargetPlatform.toString()}');
      debugPrint('Using redirect URL for Google Sign-In: $redirectUrl');

      // Use platform-specific approach
      if (isIOS) {
        await client.auth.signInWithOAuth(
          OAuthProvider.google,
          // On iOS, Supabase handles redirect internally
        );
      } else {
        await client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: isMobile ? redirectUrl : null,
        );
      }
    } catch (e) {
      debugPrint('Detailed Google Sign-In error: ${e.toString()}');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => client.auth.currentUser;

  // Get session
  Session? get currentSession => client.auth.currentSession;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Update user profile
  Future<UserResponse> updateUserProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final response = await client.auth.updateUser(
        UserAttributes(
          data: {
            if (displayName != null) 'display_name': displayName,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          },
        ),
      );
      return response;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // DATABASE METHODS

  // Enable realtime subscription for a table
  Future<void> enableRealtimeForTable(String tableName) async {
    try {
      client.channel(tableName).subscribe();
    } catch (e) {
      debugPrint('Error enabling realtime for $tableName: $e');
      rethrow;
    }
  }

  // USER-SPECIFIC METHODS

  // Get current user profile from users table
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      if (currentUser == null) return null;

      final data =
          await client
              .from('users')
              .select()
              .eq('id', currentUser!.id)
              .single();

      return data;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      rethrow;
    }
  }

  // GROUP METHODS

  // Get groups where user is a member
  Future<List<Map<String, dynamic>>> getUserGroups() async {
    try {
      if (currentUser == null) return [];

      final data = await client
          .from('group_members')
          .select('group:groups(*)')
          .eq('userId', currentUser!.id);

      List<Map<String, dynamic>> groups = [];
      for (var item in data) {
        if (item['group'] != null) {
          groups.add(item['group'] as Map<String, dynamic>);
        }
      }

      return groups;
    } catch (e) {
      debugPrint('Error getting user groups: $e');
      rethrow;
    }
  }

  // Create a new group
  Future<Map<String, dynamic>> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create the group
      final groupData =
          await client
              .from('groups')
              .insert({
                'name': name,
                'description': description,
                'created_by': currentUser!.id,
                'created_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      // Add the creator as a member
      await client.from('group_members').insert({
        'group_id': groupData['id'],
        'user_id': currentUser!.id,
        'joined_at': DateTime.now().toIso8601String(),
      });

      return groupData;
    } catch (e) {
      debugPrint('Error creating group: $e');
      rethrow;
    }
  }

  // Add member to group
  Future<void> addGroupMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      await client.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error adding group member: $e');
      rethrow;
    }
  }

  // EXPENSE METHODS

  // Create a new expense
  Future<Map<String, dynamic>> createExpense({
    required String groupId,
    required String title,
    required double amount,
    required Map<String, double> shares,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create the expense
      final expenseData =
          await client
              .from('expenses')
              .insert({
                'group_id': groupId,
                'title': title,
                'amount': amount,
                'paid_by': currentUser!.id,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
                if (metadata != null) 'metadata': metadata,
              })
              .select()
              .single();

      // Add expense shares
      for (final entry in shares.entries) {
        await client.from('expense_shares').insert({
          'expense_id': expenseData['id'],
          'user_id': entry.key,
          'amount': entry.value,
        });
      }

      return expenseData;
    } catch (e) {
      debugPrint('Error creating expense: $e');
      rethrow;
    }
  }

  // Get expenses for a group
  Future<List<Map<String, dynamic>>> getGroupExpenses(String groupId) async {
    try {
      final data = await client
          .from('expenses')
          .select('*, expense_shares(*)')
          .eq('group_id', groupId)
          .order('created_at', ascending: false);

      return data;
    } catch (e) {
      debugPrint('Error getting group expenses: $e');
      rethrow;
    }
  }

  // Get total balance for current user in a group
  Future<double> getUserBalanceInGroup(String groupId) async {
    try {
      if (currentUser == null) return 0;

      // Get expenses paid by current user
      final paidExpenses = await client
          .from('expenses')
          .select('amount')
          .eq('group_id', groupId)
          .eq('paid_by', currentUser!.id);

      double paidTotal = 0;
      for (var expense in paidExpenses) {
        paidTotal += (expense['amount'] as num).toDouble();
      }

      // Get shares owed by current user
      final shares = await client
          .from('expense_shares')
          .select('amount, expense:expenses(group_id)')
          .eq('user_id', currentUser!.id);

      double owedTotal = 0;
      for (var share in shares) {
        if (share['expense'] != null &&
            share['expense']['group_id'] == groupId) {
          owedTotal += (share['amount'] as num).toDouble();
        }
      }

      return paidTotal - owedTotal;
    } catch (e) {
      debugPrint('Error calculating user balance: $e');
      rethrow;
    }
  }

  // Refresh the session if it's about to expire
  Future<void> refreshSessionIfNeeded() async {
    try {
      final session = currentSession;
      if (session == null) return;

      // If session expires in the next 5 minutes (300 seconds), refresh it
      final expiresAt = session.expiresAt;
      if (expiresAt == null) return;

      final now = DateTime.now();
      // Convert expiresAt from Unix timestamp (seconds since epoch) to DateTime
      final expiresAtDateTime = DateTime.fromMillisecondsSinceEpoch(
        expiresAt * 1000,
      );
      final expiresIn = expiresAtDateTime.difference(now).inSeconds;

      if (expiresIn < 300) {
        debugPrint('Session expires soon, refreshing...');
        await client.auth.refreshSession();
        debugPrint('Session refreshed successfully');
      }
    } catch (e) {
      debugPrint('Error refreshing session: $e');
      rethrow;
    }
  }

  // Ensure the current user exists in the users table
  Future<void> ensureUserInDatabase() async {
    try {
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if user already exists
      final existingUser =
          await client
              .from('users')
              .select()
              .eq('id', currentUser!.id)
              .maybeSingle();

      if (existingUser == null) {
        // User doesn't exist in our users table, create them
        debugPrint('Creating user record in users table...');

        await client.from('users').upsert({
          'id': currentUser!.id,
          'email': currentUser!.email ?? '',
          'display_name':
              currentUser!.userMetadata?['display_name'] ??
              currentUser!.userMetadata?['full_name'] ??
              currentUser!.email?.split('@').first ??
              'User',
          'avatar_url':
              currentUser!.userMetadata?['avatar_url'] ??
              currentUser!.userMetadata?['picture'] ??
              '',
          'created_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');

        debugPrint('User record created successfully');
      } else {
        debugPrint('User already exists in users table');
      }
    } catch (e) {
      debugPrint('Error ensuring user in database: $e');
      rethrow;
    }
  }

  // Sync authenticated user after sign-in
  Future<void> syncAuthenticatedUserToDatabase() async {
    try {
      await refreshSessionIfNeeded();
      await ensureUserInDatabase();
      debugPrint('User synchronized to database');
    } catch (e) {
      debugPrint('Error syncing user to database: $e');
      rethrow;
    }
  }
}
