import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitmitra/app/data/datasources/remote/supabase_service.dart';
import 'package:splitmitra/app/data/models/notification_model.dart';
import 'package:splitmitra/app/data/repositories/notification_repository.dart';

class NotificationsController extends GetxController {
  final NotificationRepository _notificationRepository = Get.find<NotificationRepository>();
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final isLoading = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadNotifications();
  }
  
  Future<void> _loadNotifications() async {
    try {
      isLoading.value = true;
      
      if (_supabaseService.currentUser == null) {
        return;
      }
      
      final userId = _supabaseService.currentUser!.id;
      final notificationsList = await _notificationRepository.getUserNotifications(userId);
      
      notifications.value = notificationsList;
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  void markAsRead(String notificationId) async {
    try {
      await _notificationRepository.markAsRead(notificationId);
      // Update the local notification
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final updated = notifications[index].copyWith(isRead: true);
        notifications[index] = updated;
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
  
  void refreshNotifications() {
    _loadNotifications();
  }
}