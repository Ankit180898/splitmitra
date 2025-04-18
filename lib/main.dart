import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:splitmitra/app/data/datasources/remote/notification_service.dart';
import 'package:splitmitra/app/data/datasources/remote/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase
  await SupabaseService.initialize();
  // Initialize GetX bindings first
  Get.put<SupabaseService>(SupabaseService(), permanent: true);
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  final String oneSignalAppId = dotenv.env['ONE_SIGNAL_APP_ID'] ?? '';

  OneSignal.initialize(oneSignalAppId);
  InitialBinding().dependencies();

  runApp(const SplitMitraApp());
}

class SplitMitraApp extends StatelessWidget {
  const SplitMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "SplitMitra",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: Routes.splash,
      getPages: AppPages.pages,
      initialBinding: InitialBinding(),
      defaultTransition: Transition.fade,
    );
  }
}
