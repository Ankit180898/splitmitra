import 'package:get/get.dart';
import 'package:splitmitra/app/modules/group/controller/group_controller.dart';
import 'package:splitmitra/app/modules/expense/controller/expense_controller.dart';

class GroupBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<GroupController>()) {
      Get.put<GroupController>(GroupController());
    }

    if (!Get.isRegistered<ExpenseController>()) {
      Get.put<ExpenseController>(ExpenseController());
    }
  }
}
