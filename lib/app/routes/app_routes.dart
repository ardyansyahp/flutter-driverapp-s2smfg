import 'package:get/get.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/qr_login_screen.dart';
import '../views/delivery/delivery_list_screen.dart';
import '../views/delivery/scan_truck_screen.dart';
import '../views/delivery/active_delivery_screen.dart';
import '../views/delivery/arrival_screen.dart';
import '../views/delivery/incident_screen.dart';
import '../views/delivery/plan_list_screen.dart';
import '../views/delivery/scan_truck_new_screen.dart';
import '../views/delivery/trip_screen.dart';
import '../views/delivery/trip_incident_screen.dart';
import '../models/delivery_model.dart';
import '../models/shipping_model.dart';

class AppRoutes {
  static const login = '/login';
  static const qrLogin = '/login/qr';
  static const deliveryList = '/delivery';
  static const scanTruck = '/delivery/scan';
  static const activeDelivery = '/delivery/active';
  static const arrival = '/delivery/arrival';
  static const incident = '/delivery/incident';

  // New shipping system
  static const planList = '/shipping/plans';
  static const scanTruckNew = '/shipping/scan';
  static const tripActive = '/shipping/trip';
  static const tripIncident = '/shipping/incident';

  static final pages = [
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: qrLogin, page: () => const QrLoginScreen()),
    GetPage(name: deliveryList, page: () => const DeliveryListScreen()),
    GetPage(
      name: scanTruck,
      page: () => ScanTruckScreen(spk: Get.arguments as SpkModel),
    ),
    GetPage(
      name: activeDelivery,
      page: () =>
          ActiveDeliveryScreen(delivery: Get.arguments as DeliveryModel),
    ),
    GetPage(
      name: arrival,
      page: () => ArrivalScreen(delivery: Get.arguments as DeliveryModel),
    ),
    GetPage(
      name: incident,
      page: () => IncidentScreen(delivery: Get.arguments as DeliveryModel),
    ),

    // New shipping system
    GetPage(name: planList, page: () => const PlanListScreen()),
    GetPage(name: scanTruckNew, page: () => const ScanTruckNewScreen()),
    GetPage(name: tripActive, page: () => const TripScreen()),
    GetPage(
      name: tripIncident,
      page: () => TripIncidentScreen(trip: Get.arguments as ShippingTripModel),
    ),
  ];
}
