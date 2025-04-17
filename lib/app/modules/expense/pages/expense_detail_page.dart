// lib/app/modules/expense/pages/expense_detail_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splitmitra/app/core/theme/app_text_styles.dart';
import 'package:splitmitra/app/core/theme/color_schemes.dart';
import 'package:splitmitra/app/core/utils/responsive.dart';
import 'package:splitmitra/app/core/widgets/custom_button.dart';
import 'package:splitmitra/app/core/widgets/loading_widget.dart';
import 'package:splitmitra/app/data/models/expense_model.dart';
import 'package:splitmitra/app/modules/expense/controller/expense_controller.dart';

class ExpenseDetailPage extends StatefulWidget {
  const ExpenseDetailPage({super.key});

  @override
  State<ExpenseDetailPage> createState() => _ExpenseDetailPageState();
}

class _ExpenseDetailPageState extends State<ExpenseDetailPage>
    with SingleTickerProviderStateMixin {
  late ExpenseController _expenseController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  ExpenseModel? _expense;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _expenseController = Get.find<ExpenseController>();
    final String expenseId = Get.arguments as String;

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExpenseData(expenseId);
    });
  }

  Future<void> _loadExpenseData(String expenseId) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final expense = await _expenseController.getExpenseById(expenseId);
      if (mounted) {
        setState(() {
          _expense = expense;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Get.isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('Expense Details', style: AppTextStyles.headline5),
        backgroundColor:
            Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
      ),
      body: FadeTransition(opacity: _fadeAnimation, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading expense details...');
    }
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    if (_expense == null) {
      return _buildNotFoundState();
    }
    return _buildExpenseDetails(_expense!);
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.error.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text('Error loading expense', style: AppTextStyles.headline5),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Unknown error',
              style: AppTextStyles.bodyText2,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: AppColors.primary.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text('Expense not found', style: AppTextStyles.headline5),
        ],
      ),
    );
  }

  Widget _buildExpenseDetails(ExpenseModel expense) {
    final isPaidByCurrentUser =
        expense.paidBy == _expenseController.currentUser?.id;
    final formatter = NumberFormat.currency(symbol: '\$');
    final lowerTitle = expense.title.toLowerCase();

    IconData icon = Icons.receipt_long;
    Color backgroundColor = AppColors.primary;
    if (lowerTitle.contains('food') ||
        lowerTitle.contains('lunch') ||
        lowerTitle.contains('dinner')) {
      icon = Icons.fastfood;
      backgroundColor = AppColors.foodDrink;
    } else if (lowerTitle.contains('shop') || lowerTitle.contains('buy')) {
      icon = Icons.shopping_bag;
      backgroundColor = AppColors.shopping;
    } else if (lowerTitle.contains('trip') || lowerTitle.contains('travel')) {
      icon = Icons.directions_car;
      backgroundColor = AppColors.travel;
    } else if (lowerTitle.contains('movie') ||
        lowerTitle.contains('entertainment')) {
      icon = Icons.movie;
      backgroundColor = AppColors.entertainment;
    } else if (lowerTitle.contains('bill') || lowerTitle.contains('utility')) {
      icon = Icons.receipt;
      backgroundColor = AppColors.utilities;
    }

    return SingleChildScrollView(
      padding: Responsive.getScreenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            color:
                Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: backgroundColor,
                        child: Icon(icon, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(expense.title, style: AppTextStyles.headline4),
                            const SizedBox(height: 4),
                            Text(
                              'Paid by ${isPaidByCurrentUser ? 'You' : (expense.paidByUser?.displayName ?? 'Unknown')}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      formatter.format(expense.amount),
                      style: AppTextStyles.amount.copyWith(
                        fontSize: 36,
                        color: backgroundColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _formatDate(expense.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Split Details
          Text('Split Details', style: AppTextStyles.headline6),
          const SizedBox(height: 16),
          expense.shares == null || expense.shares!.isEmpty
              ? Center(
                child: Text(
                  'No split details available',
                  style: AppTextStyles.subtitle1,
                ),
              )
              : _buildSharesList(expense),
          const SizedBox(height: 24),

          // Your Status
          Card(
            color:
                Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Status', style: AppTextStyles.headline6),
                  const SizedBox(height: 16),
                  _buildUserStatusRow(expense),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Actions
          Row(
            children: [
              if (isPaidByCurrentUser)
                Expanded(
                  child: CustomButton(
                    text: 'Edit',
                    onPressed:
                        () => _expenseController.prepareExpenseForEditing(
                          expense,
                        ),
                    buttonType: ButtonType.outlined,
                    icon: Icons.edit,
                  ),
                ),
              if (isPaidByCurrentUser) const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text:
                      expense.title.startsWith('Settlement for:')
                          ? 'Settled'
                          : 'Settle Up',
                  onPressed:
                      expense.title.startsWith('Settlement for:')
                          ? null
                          : () => _expenseController.settleExpense(expense),
                  buttonType:
                      expense.title.startsWith('Settlement for:')
                          ? ButtonType.disabled
                          : ButtonType.filled,
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isPaidByCurrentUser)
            CustomButton(
              text: 'Delete Expense',
              onPressed: _showDeleteConfirmation,
              buttonType: ButtonType.outlined,
              icon: Icons.delete_outline,
              color: AppColors.error,
              isFullWidth: true,
            ),
        ],
      ),
    );
  }

  Widget _buildSharesList(ExpenseModel expense) {
    if (expense.title.startsWith('Settlement for:')) {
      return _buildSettlementDetails(expense);
    }

    final Map<String, ExpenseShare> sharesByUser = {};
    if (expense.shares != null) {
      for (var share in expense.shares!) {
        sharesByUser[share.userId] = share;
      }
    }

    return Card(
      color: Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sharesByUser.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final share = sharesByUser.values.elementAt(index);
          final isCurrentUser =
              share.userId == _expenseController.currentUser?.id;
          final formatter = NumberFormat.currency(symbol: '\$');

          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  isCurrentUser ? AppColors.primary : AppColors.accent,
              backgroundImage:
                  _isValidImageUrl(share.user?.avatarUrl)
                      ? NetworkImage(share.user!.avatarUrl!)
                      : null,
              child:
                  !_isValidImageUrl(share.user?.avatarUrl)
                      ? Text(
                        _getInitials(
                          share.user?.displayName ?? share.user?.email ?? '?',
                        ),
                        style: AppTextStyles.subtitle1.copyWith(
                          color: Colors.white,
                        ),
                      )
                      : null,
            ),
            title: Text(
              isCurrentUser ? 'You' : (share.user?.displayName ?? 'Unknown'),
              style: AppTextStyles.memberName.copyWith(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              share.user?.email ?? '',
              style: AppTextStyles.memberEmail,
            ),
            trailing: Text(
              formatter.format(share.amount),
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? AppColors.error : AppColors.lightText,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettlementDetails(ExpenseModel settlement) {
    final formatter = NumberFormat.currency(symbol: '\$');
    return Card(
      color: AppColors.success.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settlement Payment',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is a payment to settle an expense.',
              style: AppTextStyles.bodyText2,
            ),
            const SizedBox(height: 16),
            if (settlement.shares != null && settlement.shares!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paid to: ${settlement.shares![0].user?.displayName ?? 'Unknown'}',
                    style: AppTextStyles.subtitle2,
                  ),
                  Text(
                    formatter.format(settlement.amount),
                    style: AppTextStyles.subtitle1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatusRow(ExpenseModel expense) {
    final currentUserId = _expenseController.currentUser?.id;
    if (currentUserId == null) return const SizedBox.shrink();

    if (expense.title.startsWith('Settlement for:')) {
      return _buildSettlementStatus(expense);
    }

    final isPaidByCurrentUser = expense.paidBy == currentUserId;
    double userShare = 0;
    if (expense.shares != null) {
      for (var share in expense.shares!) {
        if (share.userId == currentUserId) {
          userShare = share.amount;
          break;
        }
      }
    }

    double netBalance =
        isPaidByCurrentUser ? expense.amount - userShare : -userShare;
    final formatter = NumberFormat.currency(symbol: '\$');
    final isPositive = netBalance >= 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPaidByCurrentUser ? 'You paid' : 'You owe',
              style: AppTextStyles.caption,
            ),
            Text(
              isPaidByCurrentUser
                  ? formatter.format(expense.amount)
                  : formatter.format(userShare),
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isPositive ? 'You are owed' : 'Your share',
              style: AppTextStyles.caption,
            ),
            Text(
              formatter.format(netBalance.abs()),
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
                color: isPositive ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettlementStatus(ExpenseModel settlement) {
    final currentUserId = _expenseController.currentUser?.id;
    final isPaidByCurrentUser = settlement.paidBy == currentUserId;
    final formatter = NumberFormat.currency(symbol: '\$');
    String recipientName =
        settlement.shares?.isNotEmpty == true
            ? settlement.shares![0].user?.displayName ?? 'Unknown'
            : 'Unknown';

    return Center(
      child: Column(
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 36),
          const SizedBox(height: 8),
          Text(
            isPaidByCurrentUser
                ? 'You paid ${formatter.format(settlement.amount)} to $recipientName'
                : 'You received ${formatter.format(settlement.amount)} from the payer',
            style: AppTextStyles.subtitle1.copyWith(color: AppColors.success),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text('This expense has been settled', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        backgroundColor:
            Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text('Delete Expense', style: AppTextStyles.headline6),
        content: Text(
          'Are you sure you want to delete this expense? This action cannot be undone.',
          style: AppTextStyles.bodyText2,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: AppTextStyles.subtitle2),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final String expenseId = Get.arguments as String;
              await _expenseController.deleteExpense(expenseId);
              Get.back();
            },
            child: Text(
              'Delete',
              style: AppTextStyles.subtitle2.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _getInitials(String text) {
    if (text.isEmpty) return '?';
    if (text.contains('@')) return text.substring(0, 1).toUpperCase();
    final parts = text.split(' ');
    if (parts.length > 1)
      return parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
    return text[0].toUpperCase();
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return false;
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
