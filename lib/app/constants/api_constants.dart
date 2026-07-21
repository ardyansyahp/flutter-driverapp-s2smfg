class ApiConstants {
  static const String baseUrl = 'https://s2smfg.madawikri.co.id';

  // Auth
  static const String login = '/api/auth/login';
  static const String loginQr = '/api/auth/login/qr';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';

  // Driver Delivery (legacy)
  static const String deliveries = '/api/driver/deliveries';
  static const String deliveryScan = '/api/driver/delivery/scan';
  static String deliveryLocation(int id) => '/api/driver/delivery/$id/location';
  static String deliveryArrival(int id) => '/api/driver/delivery/$id/arrival';
  static String deliveryFinish(int id) => '/api/driver/delivery/$id/finish';
  static const String incident = '/api/driver/incident';

  // Shipping Plans
  static const String plans = '/api/driver/plans';
  static String planDetail(int id) => '/api/driver/plans/$id';
  static const String customers = '/api/driver/customers';
  static const String gates = '/api/driver/gates';

  // Shipping Trips
  static const String tripActive = '/api/driver/trips/active';
  static const String trips = '/api/driver/trips';
  static String tripDetail(int id) => '/api/driver/trips/$id';
  static String tripFinish(int id) => '/api/driver/trips/$id/finish';
  static String tripIncident(int id) => '/api/driver/trips/$id/incident';
  static String tripLocation(int id) => '/api/driver/trips/$id/location';
  static String tripAddStop(int id) => '/api/driver/trips/$id/stops';
  static String tripStopReorder(int tripId, int stopId) =>
      '/api/driver/trips/$tripId/stops/$stopId/reorder';
  static String tripStopArrive(int tripId, int stopId) =>
      '/api/driver/trips/$tripId/stops/$stopId/arrive';
  static String tripStopDone(int tripId, int stopId) =>
      '/api/driver/trips/$tripId/stops/$stopId/done';
  static String tripStopSkip(int tripId, int stopId) =>
      '/api/driver/trips/$tripId/stops/$stopId/skip';
  static String tripStopAddSj(int tripId, int stopId) =>
      '/api/driver/trips/$tripId/stops/$stopId/surat-jalan';
  static String tripStopDeleteSj(int tripId, int stopId, int sjId) =>
      '/api/driver/trips/$tripId/stops/$stopId/surat-jalan/$sjId';

  // Token storage key
  static const String tokenKey = 's2smfg_driver_token';
  static const String userKey = 's2smfg_driver_user';
  static const String activeDeliveryKey = 's2smfg_active_delivery_id';

  // GPS Background
  static const int gpsIntervalSeconds = 60;
}
