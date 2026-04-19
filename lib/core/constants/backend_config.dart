const bool kUseFirebaseBackend = bool.fromEnvironment(
  'USE_FIREBASE_BACKEND',
  defaultValue: false,
);

const bool kUseRealGpsStream = bool.fromEnvironment(
  'USE_REAL_GPS_STREAM',
  defaultValue: false,
);

const String kActiveTripDriverId = String.fromEnvironment(
  'ACTIVE_TRIP_DRIVER_ID',
  defaultValue: 'dev_driver',
);

const String kTripsCollectionPath = String.fromEnvironment(
  'TRIPS_COLLECTION_PATH',
  defaultValue: 'trips',
);
