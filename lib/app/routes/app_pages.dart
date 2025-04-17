import 'package:get/get.dart';
import 'package:splitmitra/app/routes/app_routes.dart';

// Bindings
import 'package:splitmitra/app/bindings/initial_binding.dart';
import 'package:splitmitra/app/modules/auth/bindings/auth_binding.dart';
import 'package:splitmitra/app/modules/home/bindings/home_binding.dart';
import 'package:splitmitra/app/modules/group/bindings/group_binding.dart';
import 'package:splitmitra/app/modules/expense/bindings/expense_binding.dart';

// Pages
import 'package:splitmitra/app/modules/auth/pages/login_page.dart';
import 'package:splitmitra/app/modules/auth/pages/signup_page.dart';
import 'package:splitmitra/app/modules/auth/pages/profile_page.dart';
import 'package:splitmitra/app/modules/home/pages/home_page.dart';
import 'package:splitmitra/app/modules/group/pages/groups_page.dart';
import 'package:splitmitra/app/modules/group/pages/group_detail_page.dart';
import 'package:splitmitra/app/modules/group/pages/create_group_page.dart';
import 'package:splitmitra/app/modules/expense/pages/create_expense_page.dart';
import 'package:splitmitra/app/modules/expense/pages/expense_detail_page.dart';
import 'package:splitmitra/app/modules/auth/pages/splash_page.dart';

class AppPages {
  static final pages = [
    // Splash & Auth
    GetPage(
      name: Routes.splash,
      page: () => const SplashPage(),
      binding: InitialBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.signUp,
      page: () => const SignupPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.profile,
      page: () => const ProfilePage(),
      binding: AuthBinding(),
    ),

    // Main Pages
    GetPage(
      name: Routes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),

    // Group Pages
    GetPage(
      name: Routes.groups,
      page: () => const GroupsPage(),
      binding: GroupBinding(),
    ),
    GetPage(
      name: Routes.groupDetail,
      page: () => const GroupDetailPage(),
      binding: GroupBinding(),
    ),
    GetPage(
      name: Routes.createGroup,
      page: () => const CreateGroupPage(),
      binding: GroupBinding(),
    ),

    // Expense Pages
    GetPage(
      name: Routes.createExpense,
      page: () => const CreateExpensePage(),
      binding: ExpenseBinding(),
    ),
    GetPage(
      name: Routes.expenseDetail,
      page: () => const ExpenseDetailPage(),
      binding: ExpenseBinding(),
    ),
  ];
}
