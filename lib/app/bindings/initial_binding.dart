import 'package:get/get.dart';
import 'package:splitmitra/app/data/datasources/remote/notification_service.dart';
import 'package:splitmitra/app/data/datasources/remote/supabase_service.dart';
import 'package:splitmitra/app/data/repositories/auth_repository.dart';
import 'package:splitmitra/app/data/repositories/group_repository.dart';
import 'package:splitmitra/app/data/repositories/expense_repository.dart';
import 'package:splitmitra/app/data/repositories/notification_repository.dart';
import 'package:splitmitra/app/modules/auth/controller/auth_controller.dart';
import 'package:splitmitra/app/modules/notifications/controllers/notifications_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Register repositories first
    Get.lazyPut(() => NotificationRepository(), fenix: true);
        Get.put<AuthRepository>(AuthRepository(), permanent: true);
    Get.lazyPut<GroupRepository>(() => GroupRepository());
    Get.lazyPut<ExpenseRepository>(() => ExpenseRepository());

    // Then services that depend on repositories
    Get.lazyPut(() => NotificationService(), fenix: true);
    // Services
    Get.put<SupabaseService>(SupabaseService(), permanent: true);

    // Repositories


    // 👈 Switched from lazyPut

    // Controllers
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put(NotificationsController());
  }
}
