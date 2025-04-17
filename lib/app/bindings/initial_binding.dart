import 'package:get/get.dart';
import 'package:splitmitra/app/data/datasources/remote/supabase_service.dart';
import 'package:splitmitra/app/data/repositories/auth_repository.dart';
import 'package:splitmitra/app/data/repositories/group_repository.dart';
import 'package:splitmitra/app/data/repositories/expense_repository.dart';
import 'package:splitmitra/app/modules/auth/controller/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.put<SupabaseService>(SupabaseService(), permanent: true);

    // Repositories
    Get.put<AuthRepository>(AuthRepository(), permanent: true);
    Get.lazyPut<GroupRepository>(() => GroupRepository());
    Get.lazyPut<ExpenseRepository>(() => ExpenseRepository());

    // Controllers
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}
