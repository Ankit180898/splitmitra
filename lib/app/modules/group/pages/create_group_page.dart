// lib/app/modules/group/pages/create_group_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitmitra/app/core/theme/app_text_styles.dart';
import 'package:splitmitra/app/core/theme/color_schemes.dart';
import 'package:splitmitra/app/core/utils/responsive.dart';
import 'package:splitmitra/app/core/widgets/custom_button.dart';
import 'package:splitmitra/app/modules/group/controller/group_controller.dart';

class CreateGroupPage extends StatelessWidget {
  const CreateGroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final groupController = Get.find<GroupController>();

    return Scaffold(
      backgroundColor:
          Get.isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('Create Group', style: AppTextStyles.headline5),
        backgroundColor:
            Get.isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: Responsive.getScreenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create a New Group', style: AppTextStyles.headline4),
            const SizedBox(height: 8),
            Text(
              'Enter details to start splitting expenses',
              style: AppTextStyles.subtitle1,
            ),
            const SizedBox(height: 24),

            // Error Message
            Obx(() {
              if (groupController.errorMessage.value.isNotEmpty) {
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
                      groupController.errorMessage.value,
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
                  Get.isDarkMode
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: groupController.groupNameController,
                      decoration: InputDecoration(
                        labelText: 'Group Name',
                        hintText: 'e.g. Roommates',
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
                    TextField(
                      controller: groupController.groupDescriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'e.g. For our apartment expenses',
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Create Button
            Obx(
              () => CustomButton(
                text: 'Create Group',
                onPressed:
                    groupController.isLoading.value
                        ? null
                        : () => groupController.createGroup(),
                buttonType:
                    groupController.isLoading.value
                        ? ButtonType.disabled
                        : ButtonType.filled,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
