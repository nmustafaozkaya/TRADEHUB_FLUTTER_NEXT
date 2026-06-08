import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/home/controllers/home_controller.dart';
import 'features/auth/views/login_screen.dart';
import 'features/home/views/home_screen.dart';
import 'theme/tradehub_theme.dart';

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
        Get.put(HomeController(), permanent: true);
      }),
      theme: buildTradeHubTheme(),
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
        // Matches native splash (flutter_native_splash) while session restores.
        return Scaffold(
          backgroundColor: const Color(0xFF2D8A8A),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Image.asset(
                'assets/icons/TradeHub-story.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      }
      if (authController.isLoggedIn.value) {
        return const HomeScreen();
      }
      return const LoginScreen();
    });
  }
}
