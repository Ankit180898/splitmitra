// lib/app/modules/expense/pages/create_expense_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:splitmitra/app/core/theme/app_text_styles.dart';
import 'package:splitmitra/app/core/theme/color_schemes.dart';
import 'package:splitmitra/app/core/utils/responsive.dart';
import 'package:splitmitra/app/core/widgets/custom_button.dart';
import 'package:splitmitra/app/data/models/user_model.dart';
import 'package:splitmitra/app/modules/expense/controller/expense_controller.dart';

class CreateExpensePage extends StatelessWidget {
  const CreateExpensePage({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseController = Get.find<ExpenseController>();
    String groupId;
    bool isEditing = false;
    String? expenseId;

    // Handle arguments
    if (Get.arguments is String) {
      groupId = Get.arguments as String;
    } else if (Get.arguments is Map) {
      final args = Get.arguments as Map;
      groupId = args['groupId'] as String;
      expenseId = args['expenseId'] as String?;
      isEditing = args['isEditing'] as bool? ?? false;
    } else {
      Get.back();
      return const SizedBox.shrink();
    }

    // Load group data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      expenseController.loadGroupExpenses(groupId);
    });

    return Scaffold(
      backgroundColor:
          Get.isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Expense' : 'Add Expense',
          style: AppTextStyles.headline5,
        ),
        backgroundColor:
            Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
      ),
      body: Obx(() {
        if (expenseController.isLoading.value &&
            expenseController.selectedGroup.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (expenseController.selectedGroup.value == null) {
          return Center(
            child: Text('Group not found', style: AppTextStyles.subtitle1),
          );
        }
        return _buildForm(context, expenseController, isEditing, expenseId);
      }),
    );
  }

  Widget _buildForm(
    BuildContext context,
    ExpenseController controller,
    bool isEditing,
    String? expenseId,
  ) {
    return SingleChildScrollView(
      padding: Responsive.getScreenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header
          Card(
            color:
                Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      controller.selectedGroup.value!.name
                          .substring(0, 1)
                          .toUpperCase(),
                      style: AppTextStyles.subtitle1.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Group', style: AppTextStyles.caption),
                        Text(
                          controller.selectedGroup.value!.name,
                          style: AppTextStyles.headline5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Error Message
          Obx(() {
            if (controller.errorMessage.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    controller.errorMessage.value,
                    style: AppTextStyles.bodyText2.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Form Card
          Card(
            color:
                Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  TextField(
                    controller: controller.titleController,
                    decoration: InputDecoration(
                      labelText: 'Expense Title',
                      hintText: 'e.g. Dinner at Restaurant',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor:
                          Get.isDarkMode
                              ? AppColors.darkBackground
                              : AppColors.lightBackground,
                    ),
                    style: AppTextStyles.bodyText1,
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextField(
                    controller: controller.amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor:
                          Get.isDarkMode
                              ? AppColors.darkBackground
                              : AppColors.lightBackground,
                    ),
                    style: AppTextStyles.bodyText1,
                  ),
                  const SizedBox(height: 24),

                  // Split Options
                  Text('Split Options', style: AppTextStyles.headline6),
                  const SizedBox(height: 16),
                  Obx(
                    () => SwitchListTile(
                      activeColor: AppColors.primary,
                      title: Text(
                        'Split Equally',
                        style: AppTextStyles.subtitle1,
                      ),
                      subtitle: Text(
                        'Divide the amount equally among all members',
                        style: AppTextStyles.caption,
                      ),
                      value: controller.splitEqually.value,
                      onChanged:
                          (value) => controller.splitEqually.value = value,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Members List
          Card(
            color:
                Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Members', style: AppTextStyles.headline6),
                  const SizedBox(height: 16),
                  Obx(() => _buildMembersList(controller)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Submit Button
          CustomButton(
            text: isEditing ? 'Update Expense' : 'Add Expense',
            onPressed:
                controller.isLoading.value
                    ? null
                    : () {
                      if (isEditing && expenseId != null) {
                        controller.updateExpense(expenseId);
                      } else {
                        controller.createExpense();
                      }
                    },
            buttonType:
                controller.isLoading.value
                    ? ButtonType.disabled
                    : ButtonType.filled,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(ExpenseController controller) {
    final members = controller.selectedGroup.value!.members ?? [];
    final currentUserId = controller.currentUser?.id;

    if (members.isEmpty) {
      return Text('No members to show', style: AppTextStyles.subtitle1);
    }

    double equalShare = 0;
    if (controller.amountController.text.isNotEmpty) {
      try {
        final totalAmount = double.parse(controller.amountController.text);
        equalShare = totalAmount / members.length;
      } catch (_) {}
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final member = members[index];
        final isCurrentUser = member.id == currentUserId;

        if (controller.splitEqually.value) {
          controller.shares[member.id] = equalShare;
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor:
                isCurrentUser ? AppColors.primary : AppColors.accent,
            backgroundImage:
                member.avatarUrl != null && _isValidImageUrl(member.avatarUrl)
                    ? NetworkImage(member.avatarUrl!)
                    : null,
            child:
                member.avatarUrl == null || !_isValidImageUrl(member.avatarUrl)
                    ? Text(
                      _getInitials(member),
                      style: AppTextStyles.subtitle1.copyWith(
                        color: Colors.white,
                      ),
                    )
                    : null,
          ),
          title: Text(
            isCurrentUser ? 'You' : (member.displayName ?? 'No Name'),
            style: AppTextStyles.memberName.copyWith(
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(member.email, style: AppTextStyles.memberEmail),
          trailing: Obx(() {
            if (controller.splitEqually.value) {
              return Text(
                '\$${equalShare.toStringAsFixed(2)}',
                style: AppTextStyles.subtitle1.copyWith(
                  color: isCurrentUser ? AppColors.error : AppColors.lightText,
                ),
              );
            }
            return SizedBox(
              width: 100,
              child: TextField(
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor:
                      Get.isDarkMode
                          ? AppColors.darkBackground
                          : AppColors.lightBackground,
                ),
                onChanged: (value) {
                  final amount = double.tryParse(value) ?? 0;
                  controller.updateShareAmount(member.id, amount);
                },
                controller: TextEditingController(
                  text:
                      controller.shares[member.id]?.toStringAsFixed(2) ??
                      '0.00',
                ),
                style: AppTextStyles.bodyText2,
              ),
            );
          }),
        );
      },
    );
  }

  String _getInitials(UserModel user) {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!.substring(0, 1).toUpperCase();
    } else if (user.email.isNotEmpty) {
      return user.email.substring(0, 1).toUpperCase();
    }
    return '?';
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
