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

const String kUsersCollectionPath = String.fromEnvironment(
  'USERS_COLLECTION_PATH',
  defaultValue: 'users',
);

const String kActiveTripsPath = String.fromEnvironment(
  'ACTIVE_TRIPS_PATH',
  defaultValue: 'active_trips',
);

const String kTripsCollectionPath = String.fromEnvironment(
  'TRIPS_COLLECTION_PATH',
  defaultValue: 'trips',
);

const String kGoogleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '890593335603-ncg7985g6btecqmoep1i4k37n5ecg9e1.apps.googleusercontent.com',
);
