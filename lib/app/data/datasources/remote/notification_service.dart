import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:splitmitra/app/data/models/notification_model.dart';
import 'package:splitmitra/app/data/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final NotificationRepository _notificationRepository =
      Get.find<NotificationRepository>();
  final String _oneSignalAppId = dotenv.env['ONE_SIGNAL_APP_ID'] ?? '';

  Future<void> initialize() async {
    // Initialize OneSignal with context
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Initialize with app ID and context
    OneSignal.initialize(_oneSignalAppId);

    // Request permissions
    await OneSignal.Notifications.requestPermission(true);

    // Set up listeners
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      final notification = event.notification;
      _saveNotification(notification);
      event.preventDefault();
      debugPrint(
        'Foreground notification: ${notification.title} - ${notification.body}',
      );
    });

    OneSignal.Notifications.addClickListener((event) {
      final notification = event.notification;
      _handleNotificationTap(notification);
    });

    // Get current user after initialization
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      await OneSignal.User.addAlias('user_id', currentUser.id);
      debugPrint('OneSignal: Set external user ID: ${currentUser.id}');
    }

    final playerId = OneSignal.User.pushSubscription.id;
    debugPrint('OneSignal Player ID: $playerId');
  }

  Future<void> sendNotificationToUser({
    required String playerId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final String oneSignalAppId = dotenv.env['ONE_SIGNAL_APP_ID'] ?? '';
    final String restApiKey = dotenv.env['ONE_SIGNAL_REST_API_KEY'] ?? '';

    if (oneSignalAppId.isEmpty || restApiKey.isEmpty) {
      throw Exception('OneSignal credentials not configured');
    }

    final url = Uri.parse('https://onesignal.com/api/v1/notifications');
    final payload = {
      'app_id': oneSignalAppId,
      'include_player_ids': [playerId],
      'headings': {'en': title},
      'contents': {'en': body},

      'content_available': true, // Ensure it's sent as a push notification

      if (data != null) 'data': data,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Basic $restApiKey', // No base64Encode here
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      print('✅ Notification sent: $title → $playerId');
    } else {
      print('❌ Failed to send notification: ${response.body}');
      throw Exception('Failed to send notification: ${response.statusCode}');
    }
  }

  Future<void> _saveNotification(OSNotification notification) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final notificationModel = NotificationModel(
      id: notification.notificationId,
      title: notification.title ?? 'New Notification',
      body: notification.body ?? '',
      createdAt: DateTime.now(),
      data: notification.additionalData,
      userId: currentUser.id,
    );

    await _notificationRepository.saveNotification(notificationModel);
  }

  void _handleNotificationTap(OSNotification notification) {
    final data = notification.additionalData;
    if (data != null && data['type'] == 'group_member_added') {
      final groupId = data['group_id'] as String?;
      if (groupId != null) {
        Get.toNamed('/group-detail', arguments: groupId);
        return;
      }
    }
    Get.toNamed('/notifications');
  }
}
