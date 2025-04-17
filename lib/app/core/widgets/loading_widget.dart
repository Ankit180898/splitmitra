import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitmitra/app/core/theme/color_schemes.dart';
import '../theme/app_text_styles.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool isFullScreen;

  const LoadingWidget({
    super.key,
    this.message,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final loadingWidget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 3,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: AppTextStyles.subtitle1,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (isFullScreen) {
      return Scaffold(
        body: Center(
          child: loadingWidget,
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 300),
        child: loadingWidget,
      ),
    );
  }
}

class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    Key? key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Get.isDarkMode
            ? AppColors.darkDivider.withOpacity(0.5)
            : AppColors.lightDivider.withOpacity(0.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    LoadingShimmer(width: 80, height: 20),
                    SizedBox(width: 8),
                    LoadingShimmer(width: 60, height: 20),
                  ],
                ),
                const LoadingShimmer(width: 80, height: 24),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    LoadingShimmer(width: 60, height: 24),
                    SizedBox(height: 8),
                    LoadingShimmer(width: 40, height: 20),
                    SizedBox(height: 4),
                    LoadingShimmer(width: 80, height: 16),
                  ],
                ),
                Column(
                  children: const [
                    LoadingShimmer(width: 100, height: 12),
                    SizedBox(height: 8),
                    LoadingShimmer(width: 80, height: 16),
                    SizedBox(height: 4),
                    LoadingShimmer(width: 60, height: 12),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    LoadingShimmer(width: 60, height: 24),
                    SizedBox(height: 8),
                    LoadingShimmer(width: 40, height: 20),
                    SizedBox(height: 4),
                    LoadingShimmer(width: 80, height: 16),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
