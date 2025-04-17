import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splitmitra/app/core/theme/app_text_styles.dart';
import 'package:splitmitra/app/core/theme/color_schemes.dart';
import 'package:splitmitra/app/core/utils/helpers.dart';
import 'package:splitmitra/app/core/utils/responsive.dart';
import 'package:splitmitra/app/core/widgets/custom_button.dart';
import 'package:splitmitra/app/core/widgets/loading_widget.dart';
import 'package:splitmitra/app/data/models/expense_model.dart';
import 'package:splitmitra/app/modules/expense/controller/expense_controller.dart';
import 'package:splitmitra/app/modules/group/controller/group_controller.dart';

class GroupDetailPage extends StatefulWidget {
  const GroupDetailPage({super.key});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RxInt _currentTabIndex = 0.obs;
  late GroupController _groupController;
  late ExpenseController _expenseController;
  final RxBool _isLoadingMembers = true.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _groupController = Get.find<GroupController>();
    _expenseController = Get.find<ExpenseController>();
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _currentTabIndex.value = _tabController.index;
      }
    });

    final String groupId = Get.arguments as String;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isLoadingMembers.value = true;
      _groupController.getGroupDetails(groupId).then((_) {
        _isLoadingMembers.value = false;
      }).catchError((e) {
        _isLoadingMembers.value = false;
        showErrorSnackBar(message: 'Failed to load group details: $e');
      });
      _expenseController.loadGroupExpenses(groupId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Obx(() => Text(
              _groupController.getSelectedGroupName(),
              style: AppTextStyles.headline5,
            )),
        backgroundColor: Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showGroupOptions(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor:
              Get.isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          labelStyle: AppTextStyles.subtitle1,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Members'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExpensesTab(),
          _buildMembersTab(),
          _buildSummaryTab(),
        ],
      ),
      floatingActionButton: Obx(() => _buildFloatingActionButton(context)),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return AnimatedScale(
      scale: _currentTabIndex.value == 2 ? 0 : 1,
      duration: const Duration(milliseconds: 200),
      child: FloatingActionButton(
        onPressed: _currentTabIndex.value == 0
            ? () => _expenseController.showAddExpenseForm(context)
            : () => _showAddMemberDialog(),
        backgroundColor: AppColors.primary,
        tooltip: _currentTabIndex.value == 0 ? 'Add Expense' : 'Add Member',
        child: Icon(_currentTabIndex.value == 0 ? Icons.add : Icons.person_add),
      ),
    );
  }

  Widget _buildExpensesTab() {
    return Obx(() {
      if (_expenseController.isLoading.value && _expenseController.expenses.isEmpty) {
        return const LoadingWidget(message: 'Loading expenses...');
      }
      if (_expenseController.expenses.isEmpty) {
        return _buildEmptyExpenseState();
      }
      return _buildExpensesList();
    });
  }

  Widget _buildEmptyExpenseState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text('No Expenses Yet', style: AppTextStyles.headline4),
          const SizedBox(height: 8),
          Text(
            'Add your first expense to start tracking',
            style: AppTextStyles.subtitle1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Add Expense',
            onPressed: () => _expenseController.showAddExpenseForm(context),
            buttonType: ButtonType.filled,
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList() {
    return RefreshIndicator(
      onRefresh: () => _expenseController.loadGroupExpenses(
        _groupController.selectedGroup.value!.id,
      ),
      child: ListView.separated(
        padding: Responsive.getScreenPadding(context),
        itemCount: _expenseController.expenses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final expense = _expenseController.expenses[index];
          return _buildExpenseCard(expense);
        },
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense) {
    final isPaidByCurrentUser = _expenseController.isExpensePaidByCurrentUser(expense);
    final lowerTitle = expense.title.toLowerCase();
    IconData icon = Icons.receipt_long;
    Color backgroundColor = AppColors.primary;
    if (lowerTitle.contains('food') || lowerTitle.contains('lunch') || lowerTitle.contains('dinner')) {
      icon = Icons.fastfood;
      backgroundColor = AppColors.foodDrink;
    } else if (lowerTitle.contains('shop') || lowerTitle.contains('buy')) {
      icon = Icons.shopping_bag;
      backgroundColor = AppColors.shopping;
    } else if (lowerTitle.contains('trip') || lowerTitle.contains('travel')) {
      icon = Icons.directions_car;
      backgroundColor = AppColors.travel;
    } else if (lowerTitle.contains('movie') || lowerTitle.contains('entertainment')) {
      icon = Icons.movie;
      backgroundColor = AppColors.entertainment;
    } else if (lowerTitle.contains('bill') || lowerTitle.contains('utility')) {
      icon = Icons.receipt;
      backgroundColor = AppColors.utilities;
    }

    return Card(
      color: Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _expenseController.navigateToExpenseDetails(expense),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: backgroundColor,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.title, style: AppTextStyles.expenseTitle),
                    Text(
                      'Paid by ${isPaidByCurrentUser ? 'You' : (expense.paidByUser?.displayName ?? 'Unknown')}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${expense.amount.toStringAsFixed(2)}',
                    style: AppTextStyles.amount.copyWith(
                      color: isPaidByCurrentUser ? AppColors.success : AppColors.primary,
                    ),
                  ),
                  Text(
                    _formatDate(expense.createdAt),
                    style: AppTextStyles.expenseDate,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    return Obx(() {
      if (_isLoadingMembers.value) {
        return const LoadingWidget(message: 'Loading members...');
      }
      final group = _groupController.selectedGroup.value;
      if (group == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: AppColors.error.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text('Failed to Load Group', style: AppTextStyles.headline4),
              const SizedBox(height: 8),
              Text(
                'Please try again later',
                style: AppTextStyles.subtitle1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Retry',
                onPressed: () {
                  final String groupId = Get.arguments as String;
                  _isLoadingMembers.value = true;
                  _groupController.getGroupDetails(groupId).then((_) {
                    _isLoadingMembers.value = false;
                  }).catchError((e) {
                    _isLoadingMembers.value = false;
                    showErrorSnackBar(message: 'Failed to load group details: $e');
                  });
                },
                buttonType: ButtonType.filled,
                icon: Icons.refresh,
              ),
            ],
          ),
        );
      }
      final members = group.members ?? [];
      if (members.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.group_outlined,
                size: 80,
                color: AppColors.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text('No Members Yet', style: AppTextStyles.headline4),
              const SizedBox(height: 8),
              Text(
                'Add members to start sharing expenses',
                style: AppTextStyles.subtitle1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Add Member',
                onPressed: _showAddMemberDialog,
                buttonType: ButtonType.filled,
                icon: Icons.person_add,
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          _isLoadingMembers.value = true;
          await _groupController.getGroupDetails(group.id);
          _isLoadingMembers.value = false;
        },
        child: ListView.builder(
          padding: Responsive.getScreenPadding(context),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            final isCreator = member.id == group.createdBy;
            return AnimatedOpacity(
              opacity: 1,
              duration: Duration(milliseconds: 300 + index * 100),
              child: Card(
                color: Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCreator ? AppColors.primary : AppColors.accent,
                    backgroundImage: member.avatarUrl != null && _isValidImageUrl(member.avatarUrl)
                        ? NetworkImage(member.avatarUrl!)
                        : null,
                    child: member.avatarUrl == null || !_isValidImageUrl(member.avatarUrl)
                        ? Text(
                            _getInitials(member.displayName ?? member.email),
                            style: AppTextStyles.subtitle1.copyWith(color: Colors.white),
                          )
                        : null,
                  ),
                  title: Text(
                    member.displayName ?? 'No Name',
                    style: AppTextStyles.memberName,
                  ),
                  subtitle: Text(member.email, style: AppTextStyles.memberEmail),
                  trailing: isCreator
                      ? Chip(
                          label: Text(
                            'Creator',
                            style: AppTextStyles.caption.copyWith(color: Colors.white),
                          ),
                          backgroundColor: AppColors.primary,
                        )
                      : null,
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: Responsive.getScreenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          Obx(() {
            final group = _groupController.selectedGroup.value;
            if (group == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: AppColors.error.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text('Failed to Load Group', style: AppTextStyles.headline4),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again later',
                      style: AppTextStyles.subtitle1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Retry',
                      onPressed: () {
                        final String groupId = Get.arguments as String;
                        _groupController.getGroupDetails(groupId);
                      },
                      buttonType: ButtonType.filled,
                      icon: Icons.refresh,
                    ),
                  ],
                ),
              );
            }
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: FutureBuilder<double>(
                future: _expenseController.getUserBalance(group.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    print('Balance error: ${snapshot.error}'); // Debug log
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Balance', style: AppTextStyles.headline6),
                          const SizedBox(height: 16),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 40,
                                  color: AppColors.error,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load balance',
                                  style: AppTextStyles.subtitle1,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                CustomButton(
                                  text: 'Retry',
                                  onPressed: () {
                                    setState(() {}); // Force FutureBuilder to retry
                                  },
                                  buttonType: ButtonType.outlined,
                                  icon: Icons.refresh,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final balance = snapshot.data ?? 0.0;
                  print('Balance fetched: $balance'); // Debug log
                  final isPositive = balance >= 0;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: isPositive ? AppColors.successGradient : AppColors.errorGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Balance',
                          style: AppTextStyles.headline6.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '\$${balance.abs().toStringAsFixed(2)}',
                                    style: AppTextStyles.amount.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isPositive ? 'You are owed this amount' : 'You owe this amount',
                                style: AppTextStyles.caption.copyWith(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 24),

          // Group Info
          Text('Group Information', style: AppTextStyles.headline6),
          const SizedBox(height: 16),
          Obx(() {
            final group = _groupController.selectedGroup.value;
            if (group == null) {
              return const SizedBox.shrink();
            }
            return Card(
              color: Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.group, color: AppColors.primary),
                    title: Text('Group Name', style: AppTextStyles.subtitle2),
                    subtitle: Text(group.name, style: AppTextStyles.bodyText1),
                  ),
                  if (group.description != null && group.description!.isNotEmpty)
                    ListTile(
                      leading: Icon(Icons.description, color: AppColors.primary),
                      title: Text('Description', style: AppTextStyles.subtitle2),
                      subtitle: Text(group.description!, style: AppTextStyles.bodyText1),
                    ),
                  ListTile(
                    leading: Icon(Icons.calendar_today, color: AppColors.primary),
                    title: Text('Created On', style: AppTextStyles.subtitle2),
                    subtitle: Text(
                      _formatDateFull(group.createdAt ?? DateTime.now()),
                      style: AppTextStyles.bodyText1,
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.people, color: AppColors.primary),
                    title: Text('Total Members', style: AppTextStyles.subtitle2),
                    subtitle: Text(
                      '${group.members?.length ?? 0} members',
                      style: AppTextStyles.bodyText1,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Leave Group',
                  onPressed: _showLeaveGroupConfirmation,
                  buttonType: ButtonType.outlined,
                  icon: Icons.exit_to_app,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: 'Add Member',
                  onPressed: _showAddMemberDialog,
                  buttonType: ButtonType.filled,
                  icon: Icons.person_add,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGroupOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.refresh, color: AppColors.primary),
                title: Text('Refresh', style: AppTextStyles.subtitle1),
                onTap: () {
                  Get.back();
                  final group = _groupController.selectedGroup.value;
                  if (group != null) {
                    _groupController.getGroupDetails(group.id);
                    _expenseController.loadGroupExpenses(group.id);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.person_add, color: AppColors.primary),
                title: Text('Add Member', style: AppTextStyles.subtitle1),
                onTap: () {
                  Get.back();
                  _showAddMemberDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app, color: AppColors.error),
                title: Text(
                  'Leave Group',
                  style: AppTextStyles.subtitle1.copyWith(color: AppColors.error),
                ),
                onTap: () {
                  Get.back();
                  _showLeaveGroupConfirmation();
                },
              ),
              Obx(() {
                final group = _groupController.selectedGroup.value;
                if (group != null && group.createdBy == _expenseController.currentUser?.id) {
                  return ListTile(
                    leading: Icon(Icons.delete_forever, color: AppColors.error),
                    title: Text(
                      'Delete Group',
                      style: AppTextStyles.subtitle1.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Get.back();
                      _showDeleteGroupConfirmation();
                    },
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        );
      },
    );
  }

  void _showAddMemberDialog() {
    final TextEditingController emailController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text('Add Member', style: AppTextStyles.headline6),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Enter Email Address',
            hintText: 'example@email.com',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Get.isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
          ),
          keyboardType: TextInputType.emailAddress,
          style: AppTextStyles.bodyText1,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: AppTextStyles.subtitle2),
          ),
          TextButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                _groupController.addMemberByEmail(emailController.text.trim());
                Get.back();
              } else {
                showErrorSnackBar(message: 'Please enter an email address');
              }
            },
            child: Text(
              'Add',
              style: AppTextStyles.subtitle2.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupConfirmation() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text('Leave Group', style: AppTextStyles.headline6),
        content: Text(
          'Are you sure you want to leave this group? You will no longer have access to the group expenses.',
          style: AppTextStyles.bodyText2,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: AppTextStyles.subtitle2),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _groupController.leaveGroup();
            },
            child: Text(
              'Leave',
              style: AppTextStyles.subtitle2.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteGroupConfirmation() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text('Delete Group', style: AppTextStyles.headline6),
        content: Text(
          'Are you sure you want to delete this group? This will delete all expenses and cannot be undone.',
          style: AppTextStyles.bodyText2,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: AppTextStyles.subtitle2),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              final group = _groupController.selectedGroup.value;
              if (group != null) {
                _groupController.deleteGroup(group.id);
              }
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
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays < 1) return 'Today';
    if (difference.inDays < 2) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatDateFull(DateTime? date) {
    return DateFormat('MMM d, yyyy').format(date ?? DateTime.now());
  }

  String _getInitials(String text) {
    if (text.isEmpty) return '?';
    if (text.contains('@')) return text[0].toUpperCase();
    final parts = text.split(' ');
    if (parts.length > 1) return parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
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