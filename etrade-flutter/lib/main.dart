import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/views/login_screen.dart';
import 'features/home/views/home_screen.dart';

void main() {
  runApp(const EtradeApp());
}

/// App root. Keeps global theme and route entry.
class EtradeApp extends StatelessWidget {
  const EtradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TradeHub',
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController(), permanent: true);
      }),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: const Color(0xFFF8F9FB),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

/// Redirects user to login or home based on saved session.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Obx(() {
      if (!authController.isReady.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (authController.isLoggedIn.value) {
        return const HomeScreen();
      }
      return const LoginScreen();
    });
  }
}
