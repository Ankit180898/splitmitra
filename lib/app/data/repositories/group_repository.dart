import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:splitmitra/app/data/datasources/remote/notification_service.dart';
import 'package:splitmitra/app/data/datasources/remote/supabase_service.dart';
import 'package:splitmitra/app/data/models/group_model.dart';
import 'package:splitmitra/app/data/models/user_model.dart';

class GroupRepository {
  final SupabaseService supabaseService = Get.find<SupabaseService>();
NotificationService get _notificationService => Get.find<NotificationService>();

  Future<List<GroupModel>> getUserGroups() async {
  try {
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) return [];

    // Use joins to get groups the user is a member of
    final response = await SupabaseService.client
        .from('group_members')
        .select('group:groups(*)')
        .eq('user_id', currentUser.id);

    return response.map((json) => GroupModel.fromJson(json['group'])).toList();
  } catch (e) {
    debugPrint('Error getting user groups: $e');
    return [];
  }
}

  Future<bool> verifyGroupMembership(String groupId) async {
    try {
      final currentUser = supabaseService.currentUser;
      if (currentUser == null) return false;

      final data =
          await SupabaseService.client
              .from('group_members')
              .select()
              .eq('group_id', groupId)
              .eq('user_id', currentUser.id)
              .maybeSingle();

      return data != null;
    } catch (e) {
      debugPrint('Error verifying group membership: $e');
      return false;
    }
  }

  Future<GroupModel> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      final currentUser = supabaseService.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      final groupData =
          await SupabaseService.client
              .from('groups')
              .insert({
                'name': name,
                'description': description,
                'created_by': currentUser.id,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      // Add creator as member
      await SupabaseService.client.from('group_members').insert({
        'group_id': groupData['id'],
        'user_id': currentUser.id,
        'joined_at': DateTime.now().toIso8601String(),
      });

      return GroupModel.fromJson(groupData);
    } catch (e) {
      debugPrint('Error creating group: $e');
      rethrow;
    }
  }

  Future<void> addGroupMember({
  required String groupId,
  required String userId,
}) async {
  try {
    final currentUser = supabaseService.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Check if current user is the group creator (has permission to add members)
    final groupData = await SupabaseService.client
        .from('groups')
        .select('created_by')
        .eq('id', groupId)
        .single();
    
    final isCreator = groupData['created_by'] == currentUser.id;
    
    if (!isCreator) {
      throw Exception('Only group creators can add members');
    }

    // Check if user is already a member
    final existingMember = await SupabaseService.client
        .from('group_members')
        .select()
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existingMember != null) {
      debugPrint('User already a member');
      return;
    }

    // Add member
    await SupabaseService.client.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'joined_at': DateTime.now().toIso8601String(),
    });
     // Fetch group details for notification
      final groupsData =
          await SupabaseService.client
              .from('groups')
              .select('name, created_by')
              .eq('id', groupId)
              .single();

      // Get creator name for better notification
      final creatorData =
          await SupabaseService.client
              .from('users')
              .select('display_name')
              .eq('id', groupData['created_by'])
              .single();

      // Send notification with richer data
      await _notificationService.sendNotificationToUser(
        playerId: userId,
        title: 'You\'ve been added to a group!',
        body:
            'You are now a member of "${groupsData['name']}" by ${creatorData['full_name']}.',
        data: {
          'type': 'group_member_added',
          'group_id': groupId,
          'group_name': groupData['name'],
        },
      );
  } catch (e) {
    debugPrint('Error adding group member: $e');
    rethrow;
  }
}

Future<GroupModel> getGroupWithMembers(String groupId) async {
  try {
    // Get group
    final group = await SupabaseService.client
        .from('groups')
        .select()
        .eq('id', groupId)
        .single();
    
    // Get member IDs
    final memberRows = await SupabaseService.client
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId);
    
    final memberIds = memberRows.map((row) => row['user_id'] as String).toList();
    
    // Get user details if there are members
    List<UserModel> members = [];
    if (memberIds.isNotEmpty) {
      // Alternative approach using a more explicit filter
      final usersData = await SupabaseService.client
          .from('users')
          .select()
          .filter('id', 'in', memberIds);
          
      members = usersData.map((json) => UserModel.fromJson(json)).toList();
    }

    return GroupModel.fromJson(group).copyWith(members: members);
  } catch (e) {
    debugPrint('Error getting group with members: $e');
    rethrow;
  }
}
  Future<List<UserModel>> searchUsersByEmail(String email) async {
    try {
      final data = await SupabaseService.client
          .from('users')
          .select()
          .ilike('email', '$email%');

      return data.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error searching users by email: $e');
      return [];
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await SupabaseService.client.from('groups').delete().eq('id', groupId);
    } catch (e) {
      debugPrint('Error deleting group: $e');
      rethrow;
    }
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      final currentUser = supabaseService.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      await SupabaseService.client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', currentUser.id);
    } catch (e) {
      debugPrint('Error leaving group: $e');
      rethrow;
    }
  }
}
