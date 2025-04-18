import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splitmitra/app/core/theme/app_text_styles.dart';
import 'package:splitmitra/app/core/theme/color_schemes.dart';
import 'package:splitmitra/app/data/models/notification_model.dart';
import 'package:splitmitra/app/modules/notifications/controllers/notifications_controller.dart';

class NotificationPage extends StatelessWidget {
  NotificationPage({super.key});
  
  final controller = Get.find<NotificationsController>();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: Obx(() => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : _buildNotificationsList(controller)),
    );
  }
  
  Widget _buildNotificationsList(NotificationsController controller) {
    if (controller.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text('No notifications yet', style: AppTextStyles.subtitle1),
              const SizedBox(height: 8),
              Text(
                'You\'ll see your notifications here',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        controller.refreshNotifications();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: controller.notifications.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final notification = controller.notifications[index];
          
          return ListTile(
            onTap: () {
              controller.markAsRead(notification.id);
              // Handle navigation based on notification type
              if (notification.data != null && notification.data!['type'] == 'group_member_added') {
                final groupId = notification.data!['group_id'] as String?;
                if (groupId != null) {
                  Get.toNamed('/group-detail', arguments: groupId);
                  return;
                }
              }
            },
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(
                _getNotificationIcon(notification),
                color: Colors.white,
              ),
            ),
            title: Text(
              notification.title,
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Text(
              notification.body,
              style: AppTextStyles.caption,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTimeAgo(notification.createdAt),
                  style: AppTextStyles.caption,
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  IconData _getNotificationIcon(NotificationModel notification) {
    if (notification.data != null) {
      final type = notification.data!['type'] as String?;
      switch (type) {
        case 'group_member_added':
          return Icons.group_add;
        case 'expense_added':
          return Icons.receipt_long_outlined;
        default:
          return Icons.notifications;
      }
    }
    return Icons.notifications;
  }
  
  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}