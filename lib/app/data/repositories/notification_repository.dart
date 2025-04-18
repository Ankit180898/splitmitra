import 'package:splitmitra/app/data/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> saveNotification(NotificationModel notification) async {
    try {
      await _supabase.from('notifications').insert(notification.toJson());
    } catch (e) {
      throw Exception('Failed to save notification: $e');
    }
  }

  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }
}