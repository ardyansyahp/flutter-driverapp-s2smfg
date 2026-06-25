import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/controllers/auth_controller.dart';
import 'app/controllers/delivery_controller.dart';
import 'app/controllers/shipping_controller.dart';
import 'app/routes/app_routes.dart';
import 'app/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init ApiService singleton
  ApiService().init();

  runApp(const S2SMFGDriverApp());
}

class S2SMFGDriverApp extends StatelessWidget {
  const S2SMFGDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'S2SMFG Driver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1d4ed8)),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
      ),
      initialRoute: AppRoutes.login,
      getPages: AppRoutes.pages,
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController());
        Get.put(DeliveryController(), permanent: true);
        Get.put(ShippingController(), permanent: true);
      }),
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const _NotFoundScreen(),
      ),
    );
  }
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Halaman Tidak Ditemukan')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Halaman tidak ditemukan',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.offAllNamed(AppRoutes.login),
              child: const Text('Kembali ke Login'),
            ),
          ],
        ),
      ),
    );
  }
}
