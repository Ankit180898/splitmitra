import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitmitra/app/data/models/group_model.dart';
import 'package:splitmitra/app/data/repositories/group_repository.dart';
import 'package:splitmitra/app/core/utils/helpers.dart';
import 'package:splitmitra/app/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupController extends GetxController {
  final GroupRepository _groupRepository = Get.find<GroupRepository>();

  // State variables
  final RxList<GroupModel> groups = <GroupModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Selected group (for group details)
  final Rx<GroupModel?> selectedGroup = Rx<GroupModel?>(null);

  // Form controllers
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupDescriptionController =
      TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchUserGroups();
  }

  @override
  void onClose() {
    groupNameController.dispose();
    groupDescriptionController.dispose();
    super.onClose();
  }

  // Fetch all groups for the current user
  Future<void> fetchUserGroups() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final fetchedGroups = await _groupRepository.getUserGroups();
      groups.value = fetchedGroups;
    } catch (e) {
      errorMessage.value = e.toString();
      showErrorSnackBar(message: 'Failed to load groups: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Create a new group
  Future<void> createGroup() async {
    if (groupNameController.text.isEmpty) {
      errorMessage.value = 'Group name is required';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final group = await _groupRepository.createGroup(
        name: groupNameController.text.trim(),
        description: groupDescriptionController.text.trim(),
      );

      // Directly refresh the groups list instead of just adding to the existing list
      await fetchUserGroups();
      clearControllers();

      Get.back(); // Close dialog or screen
      showSuccessSnackBar(message: 'Group created successfully');
    } catch (e) {
      errorMessage.value = e.toString();
      showErrorSnackBar(message: 'Failed to create group: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Get group details with members
  Future<void> getGroupDetails(String groupId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // First verify membership
      final isMember = await _groupRepository.verifyGroupMembership(groupId);
      if (!isMember) {
        errorMessage.value = 'You are not a member of this group';
        showErrorSnackBar(message: 'You are not a member of this group');
        Get.offAllNamed(Routes.home);
        return;
      }

      final group = await _groupRepository.getGroupWithMembers(groupId);
      selectedGroup.value = group;
    } catch (e) {
      errorMessage.value = e.toString();
      showErrorSnackBar(message: 'Failed to load group details: $e');
      // Navigate back to home if there's an error loading the group
      Get.offAllNamed(Routes.home);
    } finally {
      isLoading.value = false;
    }
  }

  // Add member to group
  Future<void> addMemberToGroup(String userId) async {
    if (selectedGroup.value == null) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _groupRepository.addGroupMember(
        groupId: selectedGroup.value!.id,
        userId: userId,
      );

      // Refresh group details to show the new member
      await getGroupDetails(selectedGroup.value!.id);

      showSuccessSnackBar(message: 'Member added successfully');
    } catch (e) {
      errorMessage.value = e.toString();
      showErrorSnackBar(message: 'Failed to add member: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Leave a group
  Future<void> leaveGroup() async {
    if (selectedGroup.value == null) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final groupId = selectedGroup.value!.id;
      await _groupRepository.leaveGroup(groupId);

      // Remove the group from the list
      groups.removeWhere((group) => group.id == groupId);
      selectedGroup.value = null;

      // Force refresh the groups list
      await fetchUserGroups();

      Get.offAllNamed(Routes.home);
      showSuccessSnackBar(message: 'You left the group');
    } catch (e) {
      errorMessage.value = e.toString();
      showErrorSnackBar(message: 'Failed to leave group: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Delete a group
  Future<void> deleteGroup(String groupId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _groupRepository.deleteGroup(groupId);

      // Remove the group from the list
      groups.removeWhere((group) => group.id == groupId);

      if (selectedGroup.value?.id == groupId) {
        selectedGroup.value = null;
      }

      // Force refresh the groups list
      await fetchUserGroups();

      Get.offAllNamed(Routes.home);
      showSuccessSnackBar(message: 'Group deleted successfully');
    } catch (e) {
      errorMessage.value = e.toString();
      showErrorSnackBar(message: 'Failed to delete group: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Clear text controllers
  void clearControllers() {
    groupNameController.clear();
    groupDescriptionController.clear();
  }

  // Navigate to group details
  void navigateToGroupDetails(GroupModel group) {
    // Cache the group first
    selectedGroup.value = group;

    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.toNamed(Routes.groupDetail, arguments: group.id);
    });
  }

  // Show create group dialog or navigate to create group page
  void showCreateGroupDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Create New Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g. Roommates',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: groupDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g. For our apartment expenses',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              clearControllers();
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          TextButton(onPressed: createGroup, child: const Text('Create')),
        ],
      ),
    );
  }

  // Get current group name safely
  String getSelectedGroupName() {
    return selectedGroup.value?.name ?? 'Group Details';
  }

  // Add a member to the current group by email
  Future<void> addMemberByEmail(String email) async {
  if (selectedGroup.value == null) {
    errorMessage.value = 'No group selected';
    showErrorSnackBar(message: 'Please select a group first');
    return;
  }

  isLoading.value = true;
  errorMessage.value = '';

  try {
    // 1. Search for user
    final users = await _groupRepository.searchUsersByEmail(email);
    if (users.isEmpty) {
      showErrorSnackBar(message: 'No user found with this email');
      return;
    }

    // 2. Add member
    await _groupRepository.addGroupMember(
      groupId: selectedGroup.value!.id,
      userId: users.first.id,
    );

    // 3. Refresh
    await getGroupDetails(selectedGroup.value!.id);
    showSuccessSnackBar(message: 'Member added successfully');
  } catch (e) {
    errorMessage.value = e.toString();
    
    // Improve error messaging
    if (e.toString().contains('Only group creators can add members')) {
      showErrorSnackBar(message: 'Only group creators can add members');
    } else {
      showErrorSnackBar(message: 'Failed to add member: ${e.toString()}');
    }
  } finally {
    isLoading.value = false;
  }
}
}
