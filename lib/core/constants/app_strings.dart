class AppStrings {
  const AppStrings._();

  static const appName = 'GaSplit';
  static const tagline = 'Split the ride, not the friendship';

  static const authTitle = 'Driver Login';
  static const authGoogleButton = 'Continue with Google';
  static const authEmailButton = 'Sign in with Email/Password';
  static const authRecentTripsTitle = 'Recent Trips';
  static const authRecentTripsSubtitle = 'Last 3 completed trips';

  static const homeGreeting = 'Good day, Driver';
  static const homeStartTripButton = 'Start a new trip';
  static const homeHistoryTitle = 'Trip History';
  static const homeHistoryCta = 'View all';
  static const homeEmptyState = 'No trips yet. Start your first trip today.';

  static const startTripTitle = 'Start Journey';
  static const startTripMapTitle = 'Current location';
  static const startTripMapHint = 'Map preview and live GPS pin appear here.';
  static const startTripVehicleDetails = 'Vehicle details';
  static const startTripFuelLabel = 'Fuel efficiency (km/L)';
  static const startTripGasPriceLabel = 'Gas price (PHP/L)';
  static const startTripPassengersTitle = 'Number of passengers';
  static const startTripCustomPassengersLabel = 'Exact passenger count';
  static const startTripButton = 'Start Trip';
  static const startTripValidationFuel =
      'Fuel efficiency must be greater than 0.';
  static const startTripValidationGas = 'Gas price must be greater than 0.';
  static const startTripValidationPassengers =
      'Select passenger count before starting.';
  static const startTripValidationCustomPassengers =
      'Enter a valid passenger count.';

  static const liveMeterTitle = 'Live Trip Meter';
  static const liveMeterMapHint = 'Route map and live markers appear here.';
  static const liveMeterLiveLabel = 'Live';
  static const liveMeterStartedLabel = 'Started';
  static const liveMeterTotalCostLabel = 'Total gas cost';
  static const liveMeterFormulaHint = 'tap to view formula';
  static const liveMeterDistanceLabel = 'Distance';
  static const liveMeterSpeedLabel = 'Speed';
  static const liveMeterDurationLabel = 'Duration';
  static const liveMeterPerPersonTitle = 'Per-person share';
  static const liveMeterPassengersSuffix = 'passengers';
  static const liveMeterDriverLabel = 'You';
  static const liveMeterPassengerLabel = 'Passenger';
  static const liveMeterEndTripButton = 'End Trip';
  static const liveMeterEndDialogTitle = 'End this trip?';
  static const liveMeterEndDialogMessage =
      'This will stop live updates and open the trip summary.';
  static const liveMeterFormulaTitle = 'Gas Formula';
  static const liveMeterFormulaGasUsed = 'Gas used';
  static const liveMeterFormulaFuel = 'Fuel efficiency';
  static const liveMeterFormulaGasPrice = 'Gas price';
  static const liveMeterFormulaPassengerCount = 'Passengers';
  static const liveMeterFormulaTotal = 'Total cost';
  static const liveMeterFormulaPerPerson = 'Per-person share';

  static const tripSummaryTitle = 'Trip Summary';
  static const tripSummaryCompletedLabel = 'Trip completed';
  static const tripSummaryDetailsTitle = 'Trip details';
  static const tripSummaryPassengerBreakdownTitle = 'Per-passenger breakdown';
  static const tripSummaryDistanceLabel = 'Distance';
  static const tripSummaryDurationLabel = 'Duration';
  static const tripSummaryGasUsedLabel = 'Gas used';
  static const tripSummaryFuelReferenceLabel = 'Fuel & gas price';
  static const tripSummaryShareButton = 'Share Breakdown';
  static const tripSummarySaveButton = 'Save to History';
  static const tripSummarySavedButton = 'Saved to History';
  static const tripSummarySavedSnack = 'Trip saved to history.';
  static const tripSummarySharePreviewTitle = 'Share trip summary';
  static const tripSummaryShareNowButton = 'Share now';
  static const tripSummaryCopyButton = 'Copy text';
  static const tripSummaryCopiedSnack = 'Summary text copied.';
  static const tripSummaryShareUnavailableSnack =
      'Unable to open share options on this device.';
  static const tripSummaryRouteFallback = 'Route unavailable';
  static const tripSummaryPoweredBy = 'Powered by GaSplit';

  static const commonCancel = 'Cancel';
  static const commonClose = 'Close';

  static const historyTitle = 'Trip History';
  static const historySearchHint = 'Search by date or route';
  static const historyEmptyFiltered = 'No trips match your search.';
  static const historyEmptyAll = 'No trips saved yet.';
  static const historyPassengersLabel = 'Passengers';
  static const historyDistanceLabel = 'Distance';
  static const historyDurationLabel = 'Duration';
  static const historyTotalLabel = 'Total';
  static const historyPerPersonLabel = 'Per person';
}
