import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitmitra/app/core/theme/app_text_styles.dart';
import 'package:splitmitra/app/core/theme/color_schemes.dart';
import 'package:splitmitra/app/modules/auth/controller/auth_controller.dart';
import 'package:splitmitra/app/modules/auth/pages/profile_page.dart';
import 'package:splitmitra/app/modules/group/pages/groups_page.dart';
import 'package:splitmitra/app/modules/home/controller/home_controller.dart';
import 'package:splitmitra/app/routes/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
        final HomeController controller = Get.put(HomeController());

    return Scaffold(
      body: PageView(
        controller: controller.pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          // Dashboard/Home Tab
          DashboardTab(),
          // Groups Tab
          GroupsPage(),
          // Profile Tab
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        currentIndex: controller.currentIndex.value,
        onTap: controller.changeTab,
        backgroundColor:
            Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor:
            Get.isDarkMode
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      )),
    );
  }

  Widget _buildBottomNavigationBar(HomeController controller) {
    return BottomNavigationBar(
      currentIndex: controller.currentIndex.value,
      onTap: controller.changeTab,
      backgroundColor:
          Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor:
          Get.isDarkMode
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group_outlined),
          activeIcon: Icon(Icons.group),
          label: 'Groups',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final homeController = Get.find<HomeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Get.toNamed(Routes.notifications),
          ),
        ],
      ),
      body: Obx(() {
        if (authController.currentUser.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (homeController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text(
                'Welcome, ${authController.currentUser.value?.displayName ?? 'User'}',
                style: AppTextStyles.headline3,
              ),
              const SizedBox(height: 8),
              Text(
                'Here\'s your expense summary',
                style: AppTextStyles.subtitle1,
              ),
              const SizedBox(height: 24),

              // Summary Cards
              Obx(() => _buildSummaryCards(homeController)),
              const SizedBox(height: 24),

              // Recent Activity Section
              Text('Recent Activity', style: AppTextStyles.headline5),
              const SizedBox(height: 16),
              _buildRecentActivityList(homeController),
              const SizedBox(height: 24),

              // Quick Actions
              Text('Quick Actions', style: AppTextStyles.headline5),
              const SizedBox(height: 16),
              _buildQuickActions(homeController),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCards(HomeController controller) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Spent',
            amount: controller.formatCurrency(controller.totalSpent.value),
            icon: Icons.arrow_upward,
            iconColor: AppColors.error,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Received',
            amount: controller.formatCurrency(controller.totalReceived.value),
            icon: Icons.arrow_downward,
            iconColor: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: AppTextStyles.subtitle2),
                const Spacer(),
                Icon(icon, color: iconColor, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(amount, style: AppTextStyles.amount),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(HomeController controller) {
    if (controller.recentExpenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text('No expenses yet', style: AppTextStyles.subtitle1),
              const SizedBox(height: 8),
              Text(
                'Create your first expense to see it here',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.recentExpenses.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final expense = controller.recentExpenses[index];

        IconData icon = Icons.receipt_long_outlined;
        Color backgroundColor = AppColors.primary;

        final lowerTitle = expense.title.toLowerCase();
        if (lowerTitle.contains('food') ||
            lowerTitle.contains('lunch') ||
            lowerTitle.contains('dinner')) {
          icon = Icons.fastfood;
          backgroundColor = AppColors.foodDrink;
        } else if (lowerTitle.contains('shop') || lowerTitle.contains('buy')) {
          icon = Icons.shopping_bag;
          backgroundColor = AppColors.shopping;
        } else if (lowerTitle.contains('trip') ||
            lowerTitle.contains('travel')) {
          icon = Icons.directions_car;
          backgroundColor = AppColors.travel;
        } else if (lowerTitle.contains('movie') ||
            lowerTitle.contains('entertainment')) {
          icon = Icons.movie;
          backgroundColor = AppColors.entertainment;
        } else if (lowerTitle.contains('bill') ||
            lowerTitle.contains('utility')) {
          icon = Icons.receipt;
          backgroundColor = AppColors.utilities;
        }

        return ListTile(
          onTap: () {
            Get.toNamed(Routes.expenseDetail, arguments: expense.id);
          },
          leading: CircleAvatar(
            backgroundColor: backgroundColor,
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(expense.title, style: AppTextStyles.expenseTitle),
          subtitle: Text(
            'Group: ${controller.getGroupName(expense.groupId)}',
            style: AppTextStyles.expenseCategory,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                controller.formatCurrency(expense.amount),
                style: AppTextStyles.subtitle2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatDate(expense.createdAt),
                style: AppTextStyles.expenseDate,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(HomeController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          icon: Icons.add_circle_outline,
          label: 'New Expense',
          onTap: () => controller.navigateToCreateExpense(),
        ),
        _buildActionButton(
          icon: Icons.group_add_outlined,
          label: 'New Group',
          onTap: () => controller.navigateToCreateGroup(),
        ),
        _buildActionButton(
          icon: Icons.refresh,
          label: 'Refresh Data',
          onTap: () => controller.forceRefreshAll(),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
