import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// Format date string
String formatDate(DateTime date, {String format = 'MMM dd, yyyy'}) {
  return DateFormat(format).format(date);
}

// Format time string
String formatTime(DateTime time, {String format = 'HH:mm'}) {
  return DateFormat(format).format(time);
}

// Calculate flight duration
String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  twoDigits(duration.inHours.remainder(24));
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  return '${duration.inHours}h ${twoDigitMinutes}m';
}

// Format relative time (e.g., "2 hours ago")
// String timeAgo(DateTime dateTime) {
//   return timeago.format(dateTime);
// }

// Show a snackbar with custom styling
void showCustomSnackBar({
  required String title,
  required String message,
  IconData icon = Icons.info_outline,
  Color backgroundColor = Colors.black87,
  Duration duration = const Duration(seconds: 3),
}) {
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.TOP,
    backgroundColor: backgroundColor,
    colorText: Colors.white,
    icon: Icon(icon, color: Colors.white),
    margin: const EdgeInsets.all(16),
    borderRadius: 8,
    duration: duration,
  );
}

// Show success snackbar
void showSuccessSnackBar({required String message}) {
  showCustomSnackBar(
    title: 'Success',
    message: message,
    icon: Icons.check_circle_outline,
    backgroundColor: Colors.green.shade800,
  );
}

// Show error snackbar
void showErrorSnackBar({required String message}) {
  showCustomSnackBar(
    title: 'Error',
    message: message,
    icon: Icons.error_outline,
    backgroundColor: Colors.red.shade800,
  );
}

// Show warning snackbar
void showWarningSnackBar({required String message}) {
  showCustomSnackBar(
    title: 'Warning',
    message: message,
    icon: Icons.warning_amber_outlined,
    backgroundColor: Colors.amber.shade900,
  );
}