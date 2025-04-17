import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitmitra/app/core/theme/app_text_styles.dart';
import 'package:splitmitra/app/core/theme/color_schemes.dart';
import 'package:splitmitra/app/core/widgets/custom_button.dart';
import 'package:splitmitra/app/modules/auth/controller/auth_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<AuthController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutConfirmation(context, controller),
              ),
            ],
          ),
          body:
              controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : _buildProfileContent(context, controller),
        );
      },
    );
  }

  Widget _buildProfileContent(BuildContext context, AuthController controller) {
    final user = controller.currentUser.value;

    if (user == null) {
      return const Center(child: Text('User data not available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // User Avatar
          CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            backgroundImage:
                user.avatarUrl != null &&
                        user.avatarUrl!.isNotEmpty &&
                        _isValidImageUrl(user.avatarUrl!)
                    ? NetworkImage(user.avatarUrl!)
                    : null,
            child:
                user.avatarUrl == null ||
                        user.avatarUrl!.isEmpty ||
                        !_isValidImageUrl(user.avatarUrl!)
                    ? Icon(Icons.person, size: 60, color: AppColors.primary)
                    : null,
          ),
          const SizedBox(height: 16),

          // User Name
          Text(user.displayName ?? 'No Name', style: AppTextStyles.headline3),
          const SizedBox(height: 8),

          // User Email
          Text(
            user.email,
            style: AppTextStyles.subtitle1.copyWith(
              color:
                  Get.isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Edit Profile Button
          CustomButton(
            text: 'Edit Profile',
            onPressed: () => _showEditProfileDialog(context, controller),
            buttonType: ButtonType.outlined,
            icon: Icons.edit,
          ),
          const SizedBox(height: 32),

          // Settings Section
          _buildSettingsSection(),
          const SizedBox(height: 32),

          // App Info Section
          _buildAppInfoSection(),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings', style: AppTextStyles.headline5),
        const SizedBox(height: 16),
        _buildSettingItem(
          icon: Icons.notifications_outlined,
          title: 'Notification Settings',
          onTap: () {
            // TODO: Navigate to notification settings
          },
        ),
        _buildSettingItem(
          icon: Icons.dark_mode_outlined,
          title: 'Dark Mode',
          trailing: Switch(
            value: Get.isDarkMode,
            onChanged: (value) {
              Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
            activeColor: AppColors.primary,
          ),
          onTap: () {
            Get.changeThemeMode(
              Get.isDarkMode ? ThemeMode.light : ThemeMode.dark,
            );
          },
        ),
        _buildSettingItem(
          icon: Icons.language_outlined,
          title: 'Language',
          subtitle: 'English',
          onTap: () {
            // TODO: Show language selection dialog
          },
        ),
        _buildSettingItem(
          icon: Icons.lock_outline,
          title: 'Privacy Settings',
          onTap: () {
            // TODO: Navigate to privacy settings
          },
        ),
      ],
    );
  }

  Widget _buildAppInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('App Info', style: AppTextStyles.headline5),
        const SizedBox(height: 16),
        _buildSettingItem(
          icon: Icons.info_outline,
          title: 'About SplitMitra',
          onTap: () {
            // TODO: Show app info dialog
          },
        ),
        _buildSettingItem(
          icon: Icons.star_outline,
          title: 'Rate the App',
          onTap: () {
            // TODO: Open app store rating
          },
        ),
        _buildSettingItem(
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () {
            // TODO: Open help center
          },
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: AppTextStyles.subtitle1),
      subtitle:
          subtitle != null
              ? Text(subtitle, style: AppTextStyles.caption)
              : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLogoutConfirmation(
    BuildContext context,
    AuthController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthController controller) {
    final nameController = TextEditingController(
      text: controller.currentUser.value?.displayName ?? '',
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Profile picture coming soon...',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              if (nameController.text.isNotEmpty) {
                controller.updateProfile(displayName: nameController.text);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  bool _isValidImageUrl(String url) {
    // Basic URL validation
    if (url.isEmpty) return false;

    // Check for common URL schemes
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return false;
    }

    // Check that URL doesn't start with file:///
    if (url.startsWith('file:///') && !url.contains('://')) {
      return false;
    }

    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
