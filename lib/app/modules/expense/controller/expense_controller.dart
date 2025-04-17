import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitmitra/app/data/models/expense_model.dart';
import 'package:splitmitra/app/data/models/group_model.dart';
import 'package:splitmitra/app/data/models/user_model.dart';
import 'package:splitmitra/app/data/repositories/expense_repository.dart';
import 'package:splitmitra/app/data/repositories/group_repository.dart';
import 'package:splitmitra/app/core/utils/helpers.dart';
import 'package:splitmitra/app/modules/auth/controller/auth_controller.dart';
import 'package:splitmitra/app/routes/app_routes.dart';
import 'package:splitmitra/app/modules/home/controller/home_controller.dart';

class ExpenseController extends GetxController {
  final ExpenseRepository _expenseRepository = Get.find<ExpenseRepository>();
  final GroupRepository _groupRepository = Get.find<GroupRepository>();
  final AuthController _authController = Get.find<AuthController>();

  // State variables
  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Selected group (for expenses in a group)
  final Rx<GroupModel?> selectedGroup = Rx<GroupModel?>(null);

  // New expense variables
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final RxMap<String, double> shares = <String, double>{}.obs;
  final RxBool splitEqually = true.obs;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    titleController.dispose();
    amountController.dispose();
    super.onClose();
  }

  // Load group details and expenses
  Future<void> loadGroupExpenses(String groupId) async {
    if (isLoading.value) return; // Prevent concurrent loading
    
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Get group details
      final group = await _groupRepository.getGroupWithMembers(groupId);
      if (group == null) {
        throw Exception('Group not found');
      }
      
      selectedGroup.value = group;

      // Get expenses for the group
      final groupExpenses = await _expenseRepository.getGroupExpenses(groupId);
      expenses.value = groupExpenses;
      print('loadGroupExpenses: Loaded ${groupExpenses.length} expenses for group $groupId');
    } catch (e) {
      errorMessage.value = e.toString();
      showErrorSnackBar(message: 'Failed to load expenses: $e');
      throw Exception('Failed to load expenses: $e'); // Propagate error
    } finally {
      isLoading.value = false;
    }
  }

  // Get user balance in a group
  Future<double> getUserBalance(String groupId) async {
    final currentUser = _authController.currentUser.value;
    if (currentUser == null) {
      print('getUserBalance: No current user authenticated');
      throw Exception('User not authenticated');
    }

    try {
      // Fetch expenses for the group
      final expenses = await _expenseRepository.getGroupExpenses(groupId);
      print('getUserBalance: Fetched ${expenses.length} expenses for group $groupId');

      double balance = 0.0;

      for (var expense in expenses) {
        // Skip settlement expenses to avoid double-counting
        if (expense.title.startsWith('Settlement for:')) {
          print('getUserBalance: Skipping settlement expense ${expense.id}');
          continue;
        }

        // Case 1: User paid the expense
        if (expense.paidBy == currentUser.id) {
          balance += expense.amount; // User is owed the full amount
          print('getUserBalance: Expense ${expense.id} paid by user, added ${expense.amount}');
        }

        // Case 2: User owes a share of the expense
        if (expense.shares != null) {
          final userShare = expense.shares!.firstWhereOrNull(
            (share) => share.userId == currentUser.id,
          );
          if (userShare != null && userShare.amount > 0) {
            balance -= userShare.amount; // Subtract user's share
            print('getUserBalance: Expense ${expense.id} share for user, subtracted ${userShare.amount}');
          }
        }
      }

      print('getUserBalance: Final balance for group $groupId: $balance');
      return balance;
    } catch (e) {
      print('getUserBalance error: $e');
      errorMessage.value = e.toString();
      throw Exception('Failed to calculate balance: $e');
    }
  }

  // Validate expense input
  bool _validateExpenseInput() {
    if (titleController.text.trim().isEmpty) {
      errorMessage.value = 'Title is required';
      showErrorSnackBar(message: 'Title is required');
      return false;
    }
    
    if (amountController.text.isEmpty) {
      errorMessage.value = 'Amount is required';
      showErrorSnackBar(message: 'Amount is required');
      return false;
    }
    
    double? amount;
    try {
      amount = double.parse(amountController.text);
      if (amount <= 0) {
        errorMessage.value = 'Amount must be greater than zero';
        showErrorSnackBar(message: 'Amount must be greater than zero');
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Invalid amount format';
      showErrorSnackBar(message: 'Invalid amount format');
      return false;
    }
    
    if (selectedGroup.value == null) {
      errorMessage.value = 'No group selected';
      showErrorSnackBar(message: 'No group selected');
      return false;
    }

    if (selectedGroup.value?.members == null || selectedGroup.value!.members!.isEmpty) {
      errorMessage.value = 'Group has no members';
      showErrorSnackBar(message: 'Group has no members');
      return false;
    }
    
    return true;
  }
  
  // Calculate shares for equal splitting
  void _calculateEqualShares(double amount) {
    if (selectedGroup.value?.members == null || selectedGroup.value!.members!.isEmpty) {
      return;
    }
    
    final int memberCount = selectedGroup.value!.members!.length;
    if (memberCount == 0) return;
    
    // Calculate exact share amount first (unrounded)
    final double exactShareAmount = amount / memberCount;
    // Round to 2 decimal places for display
    final double shareAmount = double.parse(exactShareAmount.toStringAsFixed(2));
    
    shares.clear();
    // Distribute shares to all members
    for (var member in selectedGroup.value!.members!) {
      shares[member.id] = shareAmount;
    }
    
    // Handle rounding errors by adjusting the last member's share if needed
    double totalShares = shares.values.fold(0, (sum, value) => sum + value);
    if ((totalShares - amount).abs() > 0.001 && selectedGroup.value!.members!.isNotEmpty) {
      String lastMemberId = selectedGroup.value!.members!.last.id;
      double currentLastShare = shares[lastMemberId] ?? 0;
      double adjustment = double.parse((amount - totalShares).toStringAsFixed(2));
      shares[lastMemberId] = double.parse((currentLastShare + adjustment).toStringAsFixed(2));
      
      // Double-check the correction
      totalShares = shares.values.fold(0, (sum, value) => sum + value);
      if ((totalShares - amount).abs() > 0.01) {
        print('Warning: Share calculation still has rounding errors.');
      }
    }
  }

  // Create a new expense
  Future<void> createExpense() async {
    if (!_validateExpenseInput()) return;
    
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Make sure we have a logged-in user
      if (_authController.currentUser.value == null) {
        throw Exception('User not authenticated');
      }

      // Parse amount
      final double amount = double.parse(amountController.text);

      // If split equally, calculate shares for all members
      if (splitEqually.value) {
        _calculateEqualShares(amount);
      }
      
      // Validate that shares add up to the total amount
      final double totalShares = shares.values.fold(0, (sum, value) => sum + value);
      if ((totalShares - amount).abs() > 0.01) {
        errorMessage.value = 'Shares do not add up to the total amount';
        showErrorSnackBar(message: 'Shares do not add up to the total amount (${totalShares.toStringAsFixed(2)} vs ${amount.toStringAsFixed(2)})');
        isLoading.value = false;
        return;
      }

      // Make sure shares exist for at least one group member
      bool hasValidShares = false;
      for (var member in selectedGroup.value!.members!) {
        if (shares.containsKey(member.id) && shares[member.id]! > 0) {
          hasValidShares = true;
          break;
        }
      }
      
      if (!hasValidShares) {
        errorMessage.value = 'No valid shares defined for any group member';
        showErrorSnackBar(message: 'No valid shares defined for any group member');
        isLoading.value = false;
        return;
      }

      await _expenseRepository.createExpense(
        groupId: selectedGroup.value!.id,
        title: titleController.text.trim(),
        amount: amount,
        shares: shares,
      );

      clearControllers();

      // Refresh expenses
      await loadGroupExpenses(selectedGroup.value!.id);

      // Also refresh home dashboard data
      _refreshDashboard();

      Get.back(); // Close dialog or screen
      showSuccessSnackBar(message: 'Expense added successfully');
    } catch (e) {
      errorMessage.value = e.toString();
      showErrorSnackBar(message: 'Failed to create expense: $e');
      throw Exception('Failed to create expense: $e'); // Propagate error
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to refresh dashboard
  void _refreshDashboard() {
    try {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.loadDashboardData();
      }
    } catch (e) {
      print('Could not refresh dashboard: $e');
    }
  }

  // Update share amount for a user
  void updateShareAmount(String userId, double amount) {
    // Validate input
    if (amount < 0) {
      showErrorSnackBar(message: 'Share amount cannot be negative');
      return;
    }
    
    shares[userId] = amount;

    // Set split equally to false when manually adjusting shares
    if (splitEqually.value) {
      splitEqually.value = false;
    }
    
    // Notify listeners
    shares.refresh();
  }

  // Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Check if user is authenticated
      if (_authController.currentUser.value == null) {
        throw Exception('User not authenticated');
      }
      
      // Find the expense in the list
      final expense = expenses.firstWhereOrNull((exp) => exp.id == expenseId);
      if (expense == null) {
        throw Exception('Expense not found');
      }
      
      // Check if this expense has settlements
      final hasSettlements = await _expenseRepository.hasSettlements(expenseId);
      if (hasSettlements) {
        throw Exception('Cannot delete an expense that has been settled');
      }
      
      await _expenseRepository.deleteExpense(expenseId);

      // Remove expense from list
      expenses.removeWhere((expense) => expense.id == expenseId);
      
      // Refresh dashboard
      _refreshDashboard();

      showSuccessSnackBar(message: 'Expense deleted successfully');
    } catch (e) {
      errorMessage.value = e.toString();
      showErrorSnackBar(message: 'Failed to delete expense: $e');
      throw Exception('Failed to delete expense: $e'); // Propagate error
    } finally {
      isLoading.value = false;
    }
  }

  // Clear form controllers
  void clearControllers() {
    titleController.clear();
    amountController.clear();
    shares.clear();
    splitEqually.value = true;
  }

  // Get current user
  UserModel? get currentUser => _authController.currentUser.value;

  // Check if the current user paid for an expense
  bool isExpensePaidByCurrentUser(ExpenseModel expense) {
    return expense.paidBy == currentUser?.id;
  }

  // Navigate to expense details
  void navigateToExpenseDetails(ExpenseModel expense) {
    if (expense.id.isEmpty) {
      showErrorSnackBar(message: 'Invalid expense ID');
      return;
    }
    
    // Schedule navigation for next frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.toNamed(Routes.expenseDetail, arguments: expense.id);
    });
  }

  // Show add expense form
  void showAddExpenseForm(BuildContext context) {
    if (selectedGroup.value == null || selectedGroup.value!.members == null) {
      showErrorSnackBar(message: 'Please select a group first');
      return;
    }
    
    if (selectedGroup.value!.members!.isEmpty) {
      showErrorSnackBar(message: 'Group has no members');
      return;
    }

    // Clear any previous expense data
    clearControllers();

    // Schedule navigation for next frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.toNamed(Routes.createExpense, arguments: selectedGroup.value!.id);
    });
  }

  // Get expense by ID
  Future<ExpenseModel?> getExpenseById(String expenseId) async {
    if (expenseId.isEmpty) {
      errorMessage.value = 'Invalid expense ID';
      return null;
    }
    
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // First check if it exists in the current list
      final expense = expenses.firstWhereOrNull((e) => e.id == expenseId);
      if (expense != null) {
        isLoading.value = false;
        return expense;
      }

      // If not found, fetch it from the repository
      final fetchedExpense = await _expenseRepository.getExpenseById(expenseId);
      isLoading.value = false;
      return fetchedExpense;
    } catch (e) {
      errorMessage.value = e.toString();
      showErrorSnackBar(message: 'Failed to get expense: $e');
      isLoading.value = false;
      throw Exception('Failed to get expense: $e'); // Propagate error
    }
  }

  // Prepare expense for editing
  Future<void> prepareExpenseForEditing(ExpenseModel expense) async {
    if (expense.id.isEmpty) {
      showErrorSnackBar(message: 'Invalid expense ID');
      return;
    }
    
    isLoading.value = true;
    
    try {
      // Make sure we have a logged-in user
      if (_authController.currentUser.value == null) {
        throw Exception('User not authenticated');
      }
      
      // Set the selected group
      if (selectedGroup.value == null ||
          selectedGroup.value!.id != expense.groupId) {
        // Load the group first
        final group = await _groupRepository.getGroupWithMembers(expense.groupId);
        if (group == null) {
          throw Exception('Group not found');
        }
        selectedGroup.value = group;
      }
      
      // Check if this is a settlement expense
      if (expense.title.startsWith('Settlement for:')) {
        throw Exception('Settlement expenses cannot be edited');
      }
      
      // Set form values
      titleController.text = expense.title;
      amountController.text = expense.amount.toString();

      // Set shares
      shares.clear();
      if (expense.shares != null) {
        for (var share in expense.shares!) {
          shares[share.userId] = share.amount;
        }
      }

      // Determine if split is equal
      splitEqually.value = _isEqualSplit(expense.shares);

      // Navigate to edit page
      Get.toNamed(
        Routes.createExpense,
        arguments: {
          'groupId': expense.groupId,
          'expenseId': expense.id,
          'isEditing': true,
        },
      );
    } catch (e) {
      errorMessage.value = 'Failed to prepare expense for editing: $e';
      showErrorSnackBar(
        message: 'Failed to prepare expense for editing: $e',
      );
      throw Exception('Failed to prepare expense for editing: $e'); // Propagate error
    } finally {
      isLoading.value = false;
    }
  }

  // Update an existing expense
  Future<void> updateExpense(String expenseId) async {
    if (expenseId.isEmpty) {
      showErrorSnackBar(message: 'Invalid expense ID');
      return;
    }
    
    if (!_validateExpenseInput()) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Make sure we have a logged-in user
      if (_authController.currentUser.value == null) {
        throw Exception('User not authenticated');
      }
      
      // Check if this is a settlement expense
      final expense = await getExpenseById(expenseId);
      if (expense == null) {
        throw Exception('Expense not found');
      }
      
      if (expense.title.startsWith('Settlement for:')) {
        throw Exception('Settlement expenses cannot be edited');
      }
      
      // Check if this expense has settlements
      final hasSettlements = await _expenseRepository.hasSettlements(expenseId);
      if (hasSettlements) {
        throw Exception('Cannot edit an expense that has been settled');
      }

      // Parse amount
      final double amount = double.parse(amountController.text);

      // If split equally, calculate shares for all members
      if (splitEqually.value) {
        _calculateEqualShares(amount);
      }
      
      // Validate that shares add up to the total amount
      final double totalShares = shares.values.fold(0, (sum, value) => sum + value);
      if ((totalShares - amount).abs() > 0.01) {
        errorMessage.value = 'Shares do not add up to the total amount';
        showErrorSnackBar(message: 'Shares do not add up to the total amount (${totalShares.toStringAsFixed(2)} vs ${amount.toStringAsFixed(2)})');
        isLoading.value = false;
        return;
      }

      // Make sure shares exist for at least one group member
      bool hasValidShares = false;
      for (var member in selectedGroup.value!.members!) {
        if (shares.containsKey(member.id) && shares[member.id]! > 0) {
          hasValidShares = true;
          break;
        }
      }
      
      if (!hasValidShares) {
        errorMessage.value = 'No valid shares defined for any group member';
        showErrorSnackBar(message: 'No valid shares defined for any group member');
        isLoading.value = false;
        return;
      }

      await _expenseRepository.updateExpense(
        expenseId: expenseId,
        title: titleController.text.trim(),
        amount: amount,
        shares: shares,
      );

      clearControllers();

      // Refresh expenses
      await loadGroupExpenses(selectedGroup.value!.id);

      // Also refresh home dashboard data
      _refreshDashboard();

      Get.back(); // Close dialog or screen
      showSuccessSnackBar(message: 'Expense updated successfully');
    } catch (e) {
      errorMessage.value = e.toString();
      showErrorSnackBar(message: 'Failed to update expense: $e');
      throw Exception('Failed to update expense: $e'); // Propagate error
    } finally {
      isLoading.value = false;
    }
  }

  // Check if shares are split equally
  bool _isEqualSplit(List<ExpenseShare>? shares) {
    if (shares == null || shares.isEmpty) return true;
    if (shares.length == 1) return true;

    final firstAmount = shares.first.amount;
    // Use a small epsilon for floating point comparison
    return shares.every((share) => (share.amount - firstAmount).abs() < 0.01);
  }

  // Mark expense as settled
  Future<void> settleExpense(ExpenseModel expense) async {
    if (expense.id.isEmpty) {
      showErrorSnackBar(message: 'Invalid expense ID');
      return;
    }
    
    isLoading.value = true;
    errorMessage.value = '';
    
    final currentUserId = currentUser?.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      errorMessage.value = 'User not authenticated';
      showErrorSnackBar(message: 'User not authenticated');
      isLoading.value = false;
      return;
    }

    try {
      // Check if this is already a settlement expense to prevent duplicate payments
      if (expense.title.startsWith('Settlement for:')) {
        throw Exception('This is already a settlement payment');
      }

      // Prevent settling your own expense
      if (expense.paidBy == currentUserId) {
        throw Exception('You cannot settle your own expense');
      }

      // Determine the amount the current user owes for this expense
      double amountOwed = 0;
      String paidToUserId = expense.paidBy;
      
      if (paidToUserId.isEmpty) {
        throw Exception('Invalid payer information');
      }

      // Find the user's share
      if (expense.shares != null) {
        final userShare = expense.shares!.firstWhereOrNull(
          (share) => share.userId == currentUserId,
        );
        if (userShare != null) {
          amountOwed = userShare.amount;
        }
      }

      if (amountOwed <= 0) {
        throw Exception('No amount to settle');
      }

      // Check if the user has already settled this expense
      final existingSettlements = await _expenseRepository
          .checkSettlementExists(expense.id, currentUserId);

      if (existingSettlements) {
        throw Exception('You have already settled this expense');
      }

      // Create a settlement expense (payment)
      final settlementTitle = 'Settlement for: ${expense.title}';

      // Create shares for settlement (only between current user and the person who paid)
      final Map<String, double> settlementShares = {
        paidToUserId: amountOwed, // The person who paid gets the full amount
      };

      // Add reference to original expense
      final Map<String, dynamic> metadata = {
        'settles_expense_id': expense.id,
        'settled_by': currentUserId,
      };

      await _expenseRepository.createExpense(
        groupId: expense.groupId,
        title: settlementTitle,
        amount: amountOwed,
        shares: settlementShares,
        metadata: metadata,
      );

      // Refresh expenses
      await loadGroupExpenses(expense.groupId);

      // Also refresh home dashboard data
      _refreshDashboard();

      showSuccessSnackBar(message: 'Payment recorded successfully');
      Get.back(); // Go back to the previous screen
    } catch (e) {
      errorMessage.value = e.toString();
      showErrorSnackBar(message: 'Failed to settle expense: $e');
      throw Exception('Failed to settle expense: $e'); // Propagate error
    } finally {
      isLoading.value = false;
    }
  }
}