import 'package:get/get.dart';
import 'package:splitmitra/app/modules/home/controller/home_controller.dart';
import 'package:splitmitra/app/modules/group/controller/group_controller.dart';
import 'package:splitmitra/app/modules/expense/controller/expense_controller.dart';
import 'package:splitmitra/app/data/repositories/group_repository.dart';
import 'package:splitmitra/app/data/repositories/expense_repository.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Register repositories first
    Get.put<GroupRepository>(GroupRepository());
    Get.put<ExpenseRepository>(ExpenseRepository());

    // Then register controllers that depend on repositories
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<GroupController>(() => GroupController());
    Get.lazyPut<ExpenseController>(() => ExpenseController());
  }
}
