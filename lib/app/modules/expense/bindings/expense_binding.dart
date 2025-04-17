import 'package:get/get.dart';
import 'package:splitmitra/app/modules/expense/controller/expense_controller.dart';

class ExpenseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExpenseController>(() => ExpenseController());
  }
}
