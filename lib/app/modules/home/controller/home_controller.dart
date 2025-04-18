import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitmitra/app/data/repositories/auth_repository.dart';
import 'package:splitmitra/app/data/repositories/group_repository.dart';
import 'package:splitmitra/app/data/repositories/expense_repository.dart';
import 'package:splitmitra/app/modules/auth/controller/auth_controller.dart';
import 'package:splitmitra/app/data/models/expense_model.dart';
import 'package:splitmitra/app/data/models/group_model.dart';
import 'package:splitmitra/app/routes/app_routes.dart';
import 'package:splitmitra/app/modules/group/controller/group_controller.dart';

class HomeController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final GroupRepository _groupRepository = Get.find<GroupRepository>();
  final ExpenseRepository _expenseRepository = Get.find<ExpenseRepository>();
  final AuthController _authController = Get.find<AuthController>();

  // State variables
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxDouble totalSpent = 0.0.obs;
  final RxDouble totalReceived = 0.0.obs;
  final RxList<ExpenseModel> recentExpenses = <ExpenseModel>[].obs;
  final RxList<GroupModel> userGroups = <GroupModel>[].obs;

  // Page controller for tab navigation
  late PageController pageController;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);

    // Enable realtime for groups and expenses
    _setupRealtimeSubscriptions();

    // Load dashboard data
    loadDashboardData();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void changeTab(int index) {
    currentIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Force a complete refresh of all data
  Future<void> forceRefreshAll() async {
    isLoading.value = true;

    try {
      // Clear the existing lists first
      userGroups.clear();
      recentExpenses.clear();

      // Reload everything from scratch
      // await _groupRepository.enableRealtimeForGroups();
      await _expenseRepository.enableRealtimeForExpenses();

      // Use Future.wait to load all data in parallel
      await Future.wait([
        fetchUserGroups(),
        fetchRecentExpenses(),
        calculateTotals(),
      ]);

      // Also refresh the group controller if it exists
      try {
        final groupController = Get.find<GroupController>();
        await groupController.fetchUserGroups();
      } catch (e) {
        // Group controller may not be initialized yet, which is fine
        debugPrint('Info: Group controller not available for refresh: $e');
      }
    } catch (e) {
      debugPrint('Error during force refresh: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Setup realtime subscriptions
  Future<void> _setupRealtimeSubscriptions() async {
    try {
      // await _groupRepository.enableRealtimeForGroups();
      await _expenseRepository.enableRealtimeForExpenses();
    } catch (e) {
      debugPrint('Error setting up realtime: $e');
    }
  }

  // Load all dashboard data
  Future<void> loadDashboardData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchUserGroups(),
        fetchRecentExpenses(),
        calculateTotals(),
      ]);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch user groups
  Future<void> fetchUserGroups() async {
    try {
      final groups = await _groupRepository.getUserGroups();
      userGroups.value = groups;
    } catch (e) {
      debugPrint('Error fetching user groups: $e');
    }
  }

  // Fetch recent expenses across all groups
  Future<void> fetchRecentExpenses() async {
    try {
      // First get all user groups
      if (userGroups.isEmpty) {
        await fetchUserGroups();
      }

      List<ExpenseModel> allExpenses = [];

      // For each group, fetch expenses
      for (final group in userGroups) {
        final expenses = await _expenseRepository.getGroupExpenses(group.id);
        allExpenses.addAll(expenses);
      }

      // Sort by date (newest first) and take the 5 most recent
      allExpenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      recentExpenses.value = allExpenses.take(5).toList();
    } catch (e) {
      debugPrint('Error fetching recent expenses: $e');
    }
  }

  // Get group name by ID
  String getGroupName(String groupId) {
    try {
      final group = userGroups.firstWhere((g) => g.id == groupId);
      return group.name;
    } catch (e) {
      return 'Unknown Group';
    }
  }

  // Calculate totals for spent and received
  Future<void> calculateTotals() async {
    try {
      double spent = 0.0;
      double received = 0.0;

      if (userGroups.isEmpty) {
        await fetchUserGroups();
      }

      final currentUserId = _authController.currentUser.value?.id;
      if (currentUserId == null) return;

      // For each group, calculate the final balance considering all expenses and settlements
      for (final group in userGroups) {
        final expenses = await _expenseRepository.getGroupExpenses(group.id);

        for (final expense in expenses) {
          // Skip settlement expenses to avoid double-counting
          if (expense.title.startsWith('Settlement for:')) {
            continue;
          }

          // Case 1: User paid the expense
          if (expense.paidBy == currentUserId) {
            received += expense.amount; // User is owed the full amount
          }

          // Case 2: User owes a share of the expense
          if (expense.shares != null) {
            final userShare = expense.shares!.firstWhereOrNull(
              (share) => share.userId == currentUserId,
            );
            if (userShare != null && userShare.amount > 0) {
              spent += userShare.amount; // Add to user's total spent
            }
          }
        }
      }

      // Update the observable values
      totalSpent.value = spent;
      totalReceived.value = received;

      debugPrint('Calculated totals - Spent: $spent, Received: $received');
    } catch (e) {
      debugPrint('Error calculating totals: $e');
      totalSpent.value = 0.0;
      totalReceived.value = 0.0;
    }
  }

  // Format currency amount
  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // // Change tab
  // void changeTab(int index) {
  //   currentIndex.value = index;
  //   pageController.animateToPage(
  //     index,
  //     duration: const Duration(milliseconds: 300),
  //     curve: Curves.easeInOut,
  //   );

  //   // Refresh data if navigating to the groups tab (index 1)
  //   if (index == 1) {
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       try {
  //         final groupController = Get.find<GroupController>();
  //         groupController.fetchUserGroups();
  //       } catch (e) {
  //         debugPrint('Error refreshing groups: $e');
  //       }
  //     });
  //   }
  // }

  // Navigate to create expense
  void navigateToCreateExpense() {
    if (userGroups.isNotEmpty) {
      Get.toNamed(Routes.createExpense, arguments: userGroups.first.id);
    } else {
      Get.snackbar(
        'No Groups',
        'Create a group first before adding expenses',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Navigate to create group
  void navigateToCreateGroup() {
    Get.find<GroupController>().showCreateGroupDialog();
  }

  // Sign out
  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await _authController.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
