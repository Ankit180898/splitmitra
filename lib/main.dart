import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  await dotenv.load(fileName: ".env");

  runApp(const ExpenseMateApp());
}

class ExpenseMateApp extends StatelessWidget {
  const ExpenseMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "ExpenseMate",
      debugShowCheckedModeBanner: false,
      // theme: AppTheme.darkTheme, // set your dark theme here
      // initialBinding: InitialBinding(),
      // getPages: AppPages.pages,
      // initialRoute: AppPages.initial,
    );
  }
}
