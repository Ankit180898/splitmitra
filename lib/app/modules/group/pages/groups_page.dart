// lib/app/modules/group/pages/groups_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splitmitra/app/core/theme/app_text_styles.dart';
import 'package:splitmitra/app/core/theme/color_schemes.dart';
import 'package:splitmitra/app/core/utils/responsive.dart';
import 'package:splitmitra/app/core/widgets/custom_button.dart';
import 'package:splitmitra/app/core/widgets/loading_widget.dart';
import 'package:splitmitra/app/modules/group/controller/group_controller.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GroupController>();

    return Scaffold(
      backgroundColor:
          Get.isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('My Groups', style: AppTextStyles.headline5),
        backgroundColor:
            Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => controller.fetchUserGroups(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.groups.isEmpty) {
          return const LoadingWidget(message: 'Loading your groups...');
        }
        if (controller.groups.isEmpty) {
          return _buildEmptyState(context, controller);
        }
        return _buildGroupList(context, controller);
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.showCreateGroupDialog(),
        backgroundColor: AppColors.primary,
        tooltip: 'Create Group',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, GroupController controller) {
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
          Text('No Groups Yet', style: AppTextStyles.headline4),
          const SizedBox(height: 8),
          Text(
            'Create a group to start splitting expenses with friends',
            style: AppTextStyles.subtitle1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Create a Group',
            onPressed: () => controller.showCreateGroupDialog(),
            buttonType: ButtonType.filled,
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList(BuildContext context, GroupController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.fetchUserGroups(),
      child: ListView.builder(
        padding: Responsive.getScreenPadding(context),
        itemCount: controller.groups.length,
        itemBuilder: (context, index) {
          final group = controller.groups[index];
          return AnimatedOpacity(
            opacity: 1,
            duration: Duration(milliseconds: 300 + index * 100),
            child: Card(
              color:
                  Get.isDarkMode
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => controller.navigateToGroupDetails(group),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: _getGroupColor(index),
                            child: Text(
                              group.name[0].toUpperCase(),
                              style: AppTextStyles.headline5.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: AppTextStyles.groupTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (group.description?.isNotEmpty == true)
                                  Text(
                                    group.description!,
                                    style: AppTextStyles.groupDescription,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Members: ${group.members?.length ?? 1}',
                            style: AppTextStyles.subtitle2,
                          ),
                          Text(
                            'Created: ${_formatDate(group.createdAt)}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getGroupColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.foodDrink,
      AppColors.shopping,
      AppColors.travel,
      AppColors.entertainment,
      AppColors.utilities,
    ];
    return colors[index % colors.length];
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays < 1) return 'Today';
    if (difference.inDays < 2) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return DateFormat('MMM d, yyyy').format(date);
  }
}
