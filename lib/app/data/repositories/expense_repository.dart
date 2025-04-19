import 'package:get/get.dart';
import 'package:splitmitra/app/data/datasources/remote/supabase_service.dart';
import 'package:splitmitra/app/data/models/expense_model.dart';
import 'package:splitmitra/app/data/models/user_model.dart';
import 'package:flutter/foundation.dart';

class ExpenseRepository {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  // Enable realtime subscriptions for expenses
  Future<void> enableRealtimeForExpenses() async {
    await _supabaseService.enableRealtimeForTable('expenses');
    await _supabaseService.enableRealtimeForTable('expense_shares');
  }

  // Get all expenses for a group
  Future<List<ExpenseModel>> getGroupExpenses(String groupId) async {
    try {
      final data = await _supabaseService.getGroupExpenses(groupId);
      return data.map((json) => ExpenseModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching group expenses: $e');
      rethrow;
    }
  }

  // Get expense by ID
  // Get expense by ID
  Future<ExpenseModel> getExpenseById(String expenseId) async {
    try {
      final data =
          await SupabaseService.client
              .from('expenses')
              .select(
                '*, expense_shares(*, user:users(*)), paid_by_user:users!paid_by(*)',
              )
              .eq('id', expenseId)
              .single();
      debugPrint('Raw expense data: $data'); // Add this line

      return ExpenseModel.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching expense by ID: $e');
      rethrow;
    }
  }

  // Create a new expense
  Future<ExpenseModel> createExpense({
    required String groupId,
    required String title,
    required double amount,
    required Map<String, double> shares,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate input
      if (title.trim().isEmpty) {
        throw Exception('Title cannot be empty');
      }

      if (amount <= 0) {
        throw Exception('Amount must be greater than zero');
      }

      if (shares.isEmpty) {
        throw Exception('No shares specified');
      }

      final expenseData = await _supabaseService.createExpense(
        groupId: groupId,
        title: title,
        amount: amount,
        shares: shares,
        metadata: metadata,
      );
      return ExpenseModel.fromJson(expenseData);
    } catch (e) {
      debugPrint('Error creating expense: $e');
      rethrow;
    }
  }

  // Update an existing expense
  Future<ExpenseModel> updateExpense({
    required String expenseId,
    required String title,
    required double amount,
    required Map<String, double> shares,
  }) async {
    try {
      // Validate input
      if (title.trim().isEmpty) {
        throw Exception('Title cannot be empty');
      }

      if (amount <= 0) {
        throw Exception('Amount must be greater than zero');
      }

      if (shares.isEmpty) {
        throw Exception('No shares specified');
      }

      try {
        // First update the expense record
        await SupabaseService.client
            .from('expenses')
            .update({
              'title': title,
              'amount': amount,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', expenseId);

        // Delete existing shares
        await SupabaseService.client
            .from('expense_shares')
            .delete()
            .eq('expense_id', expenseId);

        // Create new shares
        final currentUser = _supabaseService.currentUser;
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        // Insert all shares at once for better performance
        final sharesToInsert =
            shares.entries
                .map(
                  (entry) => {
                    'expense_id': expenseId,
                    'user_id': entry.key,
                    'amount': entry.value,
                  },
                )
                .toList();

        await SupabaseService.client
            .from('expense_shares')
            .insert(sharesToInsert);
      } catch (e) {
        rethrow;
      }

      // Fetch the updated expense with shares
      return await getExpenseById(expenseId);
    } catch (e) {
      debugPrint('Error updating expense: $e');
      rethrow;
    }
  }

  // Get balance for current user in a group
  Future<double> getUserBalanceInGroup(String groupId) async {
    try {
      return await _supabaseService.getUserBalanceInGroup(groupId);
    } catch (e) {
      // Log the error but return 0.0 instead of rethrowing to prevent UI crashes
      debugPrint('Error calculating user balance: $e');
      return 0.0;
    }
  }

  // Get expenses for a specific user in a group
  Future<List<ExpenseModel>> getUserExpensesInGroup(
    String groupId,
    String userId,
  ) async {
    try {
      final data = await SupabaseService.client
          .from('expenses')
          .select('*, expense_shares(*)')
          .eq('group_id', groupId)
          .eq('paid_by', userId)
          .order('created_at', ascending: false);

      return data.map((json) => ExpenseModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching user expenses in group: $e');
      rethrow;
    }
  }

  // Get spending stats for a group (total amount spent by each user)
  Future<Map<String, double>> getGroupSpendingStats(String groupId) async {
    try {
      final expenses = await SupabaseService.client
          .from('expenses')
          .select('paid_by, amount')
          .eq('group_id', groupId);

      Map<String, double> stats = {};

      for (final expense in expenses) {
        final paidBy = expense['paid_by'] as String;
        final amount = (expense['amount'] as num).toDouble();

        if (stats.containsKey(paidBy)) {
          stats[paidBy] = stats[paidBy]! + amount;
        } else {
          stats[paidBy] = amount;
        }
      }

      return stats;
    } catch (e) {
      debugPrint('Error calculating group spending stats: $e');
      rethrow;
    }
  }

  // Check if expense has settlements
  Future<bool> hasSettlements(String expenseId) async {
    try {
      // Since we need to add a metadata column, we need to handle
      // this differently to avoid the "column does not exist" error
      // First check if the metadata column exists in the database
      try {
        final settlements = await SupabaseService.client
            .from('expenses')
            .select('id, metadata')
            .not('metadata', 'is', null)
            .eq('id', expenseId);

        // If the metadata column exists and we got results, check it
        if (settlements.isNotEmpty) {
          for (var settlement in settlements) {
            var metadata = settlement['metadata'];
            if (metadata != null &&
                metadata is Map &&
                metadata.containsKey('settles_expense_id') &&
                metadata['settles_expense_id'] == expenseId) {
              return true;
            }
          }
        }
        return false;
      } catch (e) {
        // If metadata column doesn't exist yet, create it
        debugPrint('Metadata column might not exist yet: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking for settlements: $e');
      return false;
    }
  }

  // Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      // Check if there are settlements for this expense
      final hasSettlements = await this.hasSettlements(expenseId);
      if (hasSettlements) {
        throw Exception('Cannot delete an expense that has been settled');
      }

      try {
        // First delete all shares
        await SupabaseService.client
            .from('expense_shares')
            .delete()
            .eq('expense_id', expenseId);

        // Then delete the expense
        await SupabaseService.client
            .from('expenses')
            .delete()
            .eq('id', expenseId);
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      rethrow;
    }
  }

  // Check if a settlement already exists for this expense and user
  Future<bool> checkSettlementExists(
    String originalExpenseId,
    String userId,
  ) async {
    try {
      // Need to handle the case where metadata column might not exist yet
      try {
        // Query expenses table for settlements that reference the original expense
        final data = await SupabaseService.client
            .from('expenses')
            .select('id, metadata')
            .not('metadata', 'is', null);

        // Filter results manually to check if settlement exists
        for (var expense in data) {
          var metadata = expense['metadata'];
          if (metadata != null &&
              metadata is Map &&
              metadata['settles_expense_id'] == originalExpenseId &&
              metadata['settled_by'] == userId) {
            return true;
          }
        }
        return false;
      } catch (e) {
        // If metadata column doesn't exist, no settlements exist
        debugPrint('Metadata column might not exist yet: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking for settlement: $e');
      return false; // Assume no settlement exists if there's an error
    }
  }
}
