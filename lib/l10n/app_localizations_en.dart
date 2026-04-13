// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Bahaar';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get reset => 'Reset';

  @override
  String get save => 'Save';

  @override
  String get welcomeToBahaar => 'Welcome to Bahaar';

  @override
  String get fishingMap => 'Fishing Map';

  @override
  String get fishingMapSubtitle => 'Interactive map with depth colors';

  @override
  String get weather => 'Weather';

  @override
  String get weatherSubtitle => 'Check marine weather';

  @override
  String get fishRecognition => 'Fish Recognition';

  @override
  String get fishRecognitionSubtitle => 'Identify fish species';

  @override
  String get marinerHarvest => 'Mariner Harvest';

  @override
  String get marinerHarvestSubtitle => 'Buy & sell fresh fish';

  @override
  String get signOut => 'Sign Out';

  @override
  String get loadingRecognitionModel => 'Loading recognition model...';

  @override
  String get takePhotoOfFish => 'Take a photo of fish or shrimp';

  @override
  String get systemWillIdentify =>
      'The system will identify the species automatically';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get newImage => 'New Image';

  @override
  String get supportedSpecies => 'Supported Species';

  @override
  String get confidence => 'Confidence';

  @override
  String get tryTakingClearerPhoto =>
      'Try taking a clearer photo for better results';

  @override
  String get failedToLoadModel => 'Failed to load recognition model';

  @override
  String get failedToOpenCamera => 'Failed to open camera';

  @override
  String get failedToSelectImage => 'Failed to select image';

  @override
  String get modelNotReady => 'Model not ready';

  @override
  String get classificationFailed => 'Classification failed';

  @override
  String get hourlyForecast => 'Next 24 Hours';

  @override
  String get dailyForecast => 'Day Forecast';

  @override
  String get wind => 'Wind';

  @override
  String get uvIndex => 'UV Index';

  @override
  String get feelsLike => 'Feels Like';

  @override
  String get humidity => 'Humidity';

  @override
  String get visibility => 'Visibility';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get sunset => 'Sunset';

  @override
  String get unableToLoadWeather => 'Unable to load weather';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get account => 'Account';

  @override
  String get notifications => 'Notifications';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get navigationReady => 'Navigation Ready';

  @override
  String get calculatingRoute => 'Calculating route...';

  @override
  String get portNavigation => 'Port Navigation';

  @override
  String get selectPortInstruction =>
      '1. Select a port (anchor icon)\n2. Tap sea destination on map';

  @override
  String get tapSeaDestination => '2. Tap sea destination on map';

  @override
  String get pleaseSelectWaterDestination =>
      'Please select a water destination';

  @override
  String get seaDestinationSet =>
      'Sea destination set. Select a port to start from.';

  @override
  String get portSelected => 'Port selected';

  @override
  String get locationNotAvailable => 'Location not available';

  @override
  String get couldNotFindRoute => 'Could not find a route';

  @override
  String get errorCalculatingRoute => 'Error calculating route';

  @override
  String get couldNotFindLandRoute => 'Could not find land route to port';

  @override
  String get couldNotFindMarineRoute => 'Could not find marine route from port';

  @override
  String get routeCalculated => 'Route calculated';

  @override
  String get navigationStarted => 'Navigation started';

  @override
  String get failedToStartNavigation => 'Failed to start navigation';

  @override
  String get resetMask => 'Reset Mask?';

  @override
  String get resetMaskConfirmation =>
      'This will discard all your changes and restore the original mask.';

  @override
  String get maskSavedSuccessfully => 'Mask saved successfully';

  @override
  String get failedToSaveMask => 'Failed to save mask';

  @override
  String get maskResetToOriginal => 'Mask reset to original';

  @override
  String get failedToResetMask => 'Failed to reset mask';

  @override
  String get selectBothPortAndDestination =>
      'Please select both port and sea destination';

  @override
  String get currentLocationNotAvailable => 'Current location not available';

  @override
  String get chooseNavType => 'Choose Navigation Type';

  @override
  String get landToSea => 'Land → Port → Sea';

  @override
  String get landToSeaSubtitle => 'Drive to a port, then navigate to a sea destination';

  @override
  String get seaToSea => 'Sea → Sea';

  @override
  String get seaToSeaSubtitle => 'Navigate directly between two sea points';

  @override
  String get returnSeaToLand => 'Return: Sea → Port → Land';

  @override
  String get returnSeaToLandSubtitle => 'Return from sea, dock at a port, navigate home';

  @override
  String get tapSeaDeparture => 'Tap your departure point on the sea';

  @override
  String get stepTapSeaDeparture => '1. Tap your departure point on the sea';

  @override
  String get stepTapSeaDestination => '2. Tap your sea destination';

  @override
  String get stepTapPort => '1. Tap a port (anchor icon)\n2. Tap sea destination\n(Tap land to change your start location)';

  @override
  String get stepTapPortDock => '2. Tap a port (anchor icon) to dock at';

  @override
  String get stepTapLandDestination => '3. Tap your land destination';

  @override
  String get customOriginSet => 'Custom origin set';

  @override
  String get departureSet => 'Departure set';

  @override
  String get seaDepartureSet => 'Sea departure set';

  @override
  String get portLabel => 'Port';

  @override
  String get lastPort => 'Last port';

  @override
  String get landDestinationSet => 'Land destination set';

  @override
  String get offlineMapCached => 'Offline — map tiles cached';

  @override
  String get logCatch => 'Log Catch';

  @override
  String get outsideTerritorialWaters => 'Outside territorial waters — tap on the sea';

  @override
  String get tapOnSea => 'Tap on the sea, not on land';

  @override
  String get currentLocationOnLandRequired => 'Current location not available or not on land. Tap the map to set a custom land origin.';

  @override
  String get tripDetailTitle => 'Trip Detail';

  @override
  String get tripStart => 'Start';

  @override
  String get tripEnd => 'End';

  @override
  String get totalWeight => 'Total weight';

  @override
  String get noCatchesLogged => 'No catches logged.';

  @override
  String get deleteCatch => 'Delete catch?';

  @override
  String removeCatchConfirm(String species) {
    return 'Remove \"$species\" from this trip?';
  }

  @override
  String get editCatch => 'Edit Catch';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get speciesName => 'Species *';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get pinOnMap => 'Pin on Map';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get locationPinned => 'Location pinned on map.';

  @override
  String get ongoing => 'Ongoing';

  @override
  String get pickCatchTime => 'Pick catch time';

  @override
  String get quickSpeciesHamour => 'Hamour';

  @override
  String get quickSpeciesSafi => 'Safi';

  @override
  String get quickSpeciesSobaity => 'Sobaity';

  @override
  String get quickSpeciesChanad => 'Chanad';

  @override
  String get quickSpeciesZubaidi => 'Zubaidi';

  @override
  String get quickSpeciesShrimp => 'Shrimp';

  @override
  String get quickSpeciesCrab => 'Crab';

  @override
  String get fishingLog => 'Fishing Log';

  @override
  String get tripAlreadyActive => 'A trip is already active — end it first.';

  @override
  String get endActiveTripFirst => 'End the active trip first.';

  @override
  String get endButtonLabel => 'End';

  @override
  String get editTripTitle => 'Edit Title';

  @override
  String get tripNameHint => 'Trip name';

  @override
  String get editTitleTooltip => 'Edit title';

  @override
  String get deleteTripTooltip => 'Delete trip';

  @override
  String get signInToTrack => 'Sign in to track your trips and catches.';

  @override
  String get forgotPasswordHint => 'Enter your email to receive a password reset link.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetLinkSent => 'Reset link sent.';

  @override
  String get resetLinkFailed => 'Failed to send reset link.';

  @override
  String get signInToSell => 'Sign in to sell your catch.';

  @override
  String get marketplace => 'Marketplace';

  @override
  String get sellFish => 'Sell Fish';

  @override
  String get myOrders => 'My Orders';

  @override
  String get searchFishSellerLocation => 'Search fish, seller, location...';

  @override
  String get type => 'Type';

  @override
  String get condition => 'Condition';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get filtersActive => 'filters active';

  @override
  String get filterByFishType => 'Filter by Fish Type';

  @override
  String get allTypes => 'All Types';

  @override
  String get filterByCondition => 'Filter by Condition';

  @override
  String get allConditions => 'All Conditions';

  @override
  String get noFishListingsFound => 'No fish listings found';

  @override
  String get tryAdjustingFilters => 'Try adjusting your filters';

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get ordersWillAppearHere => 'Orders from buyers will appear here';

  @override
  String get orderPlaced => 'Order Placed!';

  @override
  String get youHaveOrdered => 'You have ordered';

  @override
  String get weight => 'Weight';

  @override
  String get total => 'Total';

  @override
  String get payment => 'Payment';

  @override
  String get waitingForSeller => 'Waiting for seller to accept your order.';

  @override
  String get yourFishListingPosted => 'Your fish listing has been posted!';

  @override
  String get orderAccepted => 'Order accepted!';

  @override
  String get orderRejected => 'Order rejected';

  @override
  String get orderCompleted => 'Order marked as completed!';

  @override
  String get rejectOrder => 'Reject Order';

  @override
  String get areYouSureRejectOrder =>
      'Are you sure you want to reject this order?';

  @override
  String get reasonOptional => 'Reason (optional)';

  @override
  String get reject => 'Reject';

  @override
  String get accept => 'Accept';

  @override
  String get markAsCompleted => 'Mark as Completed';

  @override
  String get buyer => 'Buyer';

  @override
  String get paymentProof => 'Payment Proof';

  @override
  String get tapToViewFullImage => 'Tap to view full image';

  @override
  String get sellerInformation => 'Seller Information';

  @override
  String get description => 'Description';

  @override
  String get yourInformation => 'Your Information';

  @override
  String get selectPaymentMethod => 'Select Payment Method';

  @override
  String get buyNow => 'Buy Now';

  @override
  String get contactSeller => 'Contact Seller';

  @override
  String get yourName => 'Your Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get deliveryLocationOptional => 'Delivery Location (optional)';

  @override
  String get pleaseEnterYourName => 'Please enter your name';

  @override
  String get pleaseEnterPhoneNumber => 'Please enter your phone number';

  @override
  String get uploadPaymentProof => 'Upload Payment Proof';

  @override
  String get required => 'Required';

  @override
  String get pleaseUploadPaymentScreenshot =>
      'Please upload a screenshot of your Benefit Pay payment';

  @override
  String get tapToUploadScreenshot => 'Tap to upload screenshot';

  @override
  String get paymentProofUploaded => 'Payment proof uploaded';

  @override
  String get pleaseUploadPaymentProofScreenshot =>
      'Please upload your payment proof screenshot';

  @override
  String get pricePerKg => 'Price per kg';

  @override
  String get totalPrice => 'Total Price';

  @override
  String get catchLocation => 'Catch Location';

  @override
  String get catchDate => 'Catch Date';

  @override
  String get cash => 'Cash';

  @override
  String get benefitPay => 'Benefit Pay';

  @override
  String get payWithCashOnDelivery => 'Pay with cash on delivery';

  @override
  String get payInstantlyViaBenefitPay => 'Pay instantly via Benefit Pay';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get location => 'Location';

  @override
  String get sales => 'sales';

  @override
  String get fishPhotos => 'Fish Photos';

  @override
  String get addPhotosOfFish => 'Add photos of your fish (optional)';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get fishDetails => 'Fish Details';

  @override
  String get fishType => 'Fish Type';

  @override
  String get customFishName => 'Custom Fish Name';

  @override
  String get pleaseEnterFishName => 'Please enter the fish name';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get pricePerKgBD => 'Price per kg (BD)';

  @override
  String get catchLocationOptional => 'Catch Location (optional)';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get selectAcceptedPaymentMethods => 'Select accepted payment methods:';

  @override
  String get acceptCashPayment => 'Accept cash payment';

  @override
  String get acceptBenefitPay => 'Accept Benefit Pay';

  @override
  String get benefitPayQRCode => 'Benefit Pay QR Code / Payment Info';

  @override
  String get uploadBenefitPayQRCode => 'Upload Benefit Pay QR Code';

  @override
  String get buyersWillSeeThis =>
      'Buyers will see this when they select Benefit Pay';

  @override
  String get postListing => 'Post Listing';

  @override
  String get yourLocation => 'Your Location (optional)';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get guest => 'Guest';

  @override
  String get signedIn => 'Signed in';

  @override
  String get guestMode => 'Guest mode';

  @override
  String get areYouSureSignOut => 'Are you sure you want to sign out?';

  @override
  String get fresh => 'Fresh';

  @override
  String get frozen => 'Frozen';

  @override
  String get live => 'Live';

  @override
  String get pending => 'Pending';

  @override
  String get accepted => 'Accepted';

  @override
  String get rejected => 'Rejected';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get minAgo => 'min ago';

  @override
  String get hoursAgo => 'hours ago';

  @override
  String get daysAgo => 'days ago';

  @override
  String get fishingLog => 'Fishing Log';

  @override
  String get emergency => 'Emergency';

  @override
  String get emergencyComingSoon => 'Emergency SOS feature coming soon.';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get contactInformation => 'Contact Information';

  @override
  String get username => 'Username';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get tripAlreadyActive => 'A trip is already active';

  @override
  String get endActiveTripFirst => 'Please end the active trip first';

  @override
  String get tripResumed => 'Trip resumed';

  @override
  String get endTrip => 'End Trip';

  @override
  String get endCurrentTrip => 'End current trip?';

  @override
  String get endButtonLabel => 'End';

  @override
  String get tripEndedAndSaved => 'Trip ended and saved';

  @override
  String get logCatch => 'Log Catch';

  @override
  String get deleteTrip => 'Delete Trip';

  @override
  String deleteTripConfirmFinished(String tripName) => 'Are you sure you want to delete "$tripName"?';

  @override
  String get delete => 'Delete';

  @override
  String get deleteActiveTrip => 'Delete Active Trip';

  @override
  String get deleteTripConfirm => 'Are you sure you want to delete this trip?';

  @override
  String get tripDeleted => 'Trip deleted';

  @override
  String get editTripTitle => 'Edit Trip';

  @override
  String get tripNameHint => 'Enter trip name';

  @override
  String get signInToSell => 'Sign in to sell your catch';

  @override
  String get logIn => 'Log In';

  @override
  String get resumeTrip => 'Resume Trip';

  @override
  String get startTrip => 'Start Trip';

  @override
  String get tripInProgress => 'Trip in Progress';

  @override
  String get catchWord => 'Catch';

  @override
  String get catches => 'Catches';

  @override
  String get editTitleTooltip => 'Edit title';

  @override
  String get deleteTripTooltip => 'Delete trip';

  @override
  String get noTripsYet => 'No trips yet';

  @override
  String get tapStartTrip => 'Tap "Start Trip" to begin logging your fishing trip';

  @override
  String get outsideTerritorialWaters => 'Outside territorial waters';

  @override
  String get tapOnSea => 'Tap on a sea area within Bahrain territorial waters';

  @override
  String get departureSet => 'Departure point set';

  @override
  String get seaDepartureSet => 'Sea departure point set';

  @override
  String get customOriginSet => 'Custom origin set';

  @override
  String get stepTapPort => 'Step 1: Tap a port to set departure';

  @override
  String get currentLocationOnLandRequired => 'Current location must be on land';

  @override
  String get chooseNavType => 'Choose Navigation Type';

  @override
  String get landToSea => 'Land to Sea';

  @override
  String get landToSeaSubtitle => 'Start from land, navigate to sea destination';

  @override
  String get seaToSea => 'Sea to Sea';

  @override
  String get seaToSeaSubtitle => 'Navigate between two sea points';

  @override
  String get returnSeaToLand => 'Return to Land';

  @override
  String get returnSeaToLandSubtitle => 'Navigate from sea back to a port';

  @override
  String get tapSeaDeparture => 'Tap a sea point to set departure';

  @override
  String get stepTapSeaDeparture => 'Step 1: Tap a sea point to set departure';

  @override
  String get stepTapSeaDestination => 'Step 2: Tap a sea point to set destination';

  @override
  String get stepTapPortDock => 'Step 2: Tap a port to dock at';

  @override
  String get stepTapLandDestination => 'Step 2: Tap a land point to set destination';

  @override
  String get portLabel => 'Port';

  @override
  String get lastPort => 'Last Port';

  @override
  String get landDestinationSet => 'Land destination set';

  @override
  String get offlineMapCached => 'Offline map cached';

  @override
  String get pleaseLoginToOrder => 'Please log in to place an order';

  @override
  String get orderPlacedTitle => 'Order Placed!';

  @override
  String youHaveOrderedFish(String fish) => 'You have ordered $fish';

  @override
  String get kgUnit => 'kg';

  @override
  String get bdUnit => 'BD';

  @override
  String get waitingForSellerToAccept => 'Waiting for seller to accept your order.';

  @override
  String get done => 'Done';

  @override
  String get listingDeleted => 'Listing deleted';

  @override
  String get depthVisualization => 'Depth Visualization';

  @override
  String get protectedExclusionZones => 'Protected & Exclusion Zones';

  @override
  String get fishingSpotSuggestions => 'Fishing Spot Suggestions';

  @override
  String get mapLayers => 'Map Layers';

  @override
  String get showDepthLayer => 'Show Depth Layer';

  @override
  String get visualizationType => 'Visualization Type';

  @override
  String get opacityLabel => 'Opacity';

  @override
  String get protectedZones => 'Protected Zones';

  @override
  String featuresLoaded(int count) => '$count features loaded';

  @override
  String get marineReservesReefs => 'Marine Reserves & Reefs';

  @override
  String get selectLocationFirst => 'Please select a location first';

  @override
  String get unexpectedError => 'An unexpected error occurred';

  @override
  String get probExcellent => 'Excellent';

  @override
  String get probVeryGood => 'Very Good';

  @override
  String get probModerate => 'Moderate';

  @override
  String get probWeak => 'Weak';

  @override
  String get probNotSuitable => 'Not Suitable';

  @override
  String get predictionTitle => 'Fishing Prediction';

  @override
  String get hideMap => 'Hide Map';

  @override
  String get selectFromMap => 'Select from Map';

  @override
  String get tapMapToSelect => 'Tap on the map to select a location';

  @override
  String get chooseSpecies => 'Choose Species';

  @override
  String get getPrediction => 'Get Prediction';

  @override
  String get retry => 'Retry';

  @override
  String get insideProtectedZone => 'Inside protected zone';

  @override
  String get factorSeason => 'Season';

  @override
  String get factorWeather => 'Weather';

  @override
  String get factorReports => 'Reports';

  @override
  String get factorProximity => 'Proximity';

  @override
  String get nearbyFishingSpots => 'Nearby Fishing Spots';

  @override
  String get pickCatchTime => 'Pick Catch Time';

  @override
  String get deleteCatch => 'Delete Catch';

  @override
  String removeCatchConfirm(String species) => 'Remove $species from this trip?';

  @override
  String get ongoing => 'Ongoing';

  @override
  String get addCatch => 'Add Catch';

  @override
  String get tripStart => 'Trip Start';

  @override
  String get tripEnd => 'Trip End';

  @override
  String get totalWeight => 'Total Weight';

  @override
  String get noCatchesLogged => 'No catches logged yet';

  @override
  String get quickSpeciesHamour => 'Hamour';

  @override
  String get weatherDewPoint => 'Dew Point';

  @override
  String get weatherNow => 'Now';

  @override
  String get weatherToday => 'Today';

  @override
  String get weatherGusts => 'Gusts';

  @override
  String get illuminated => 'Illuminated';

  @override
  String get weatherTodayTides => "Today's Tides";

  @override
  String get weatherTideUnavailable => 'Tide data unavailable';

  @override
  String get weatherHighTide => 'High Tide';

  @override
  String get weatherLowTide => 'Low Tide';

  @override
  String get dayMon => 'Mon';

  @override
  String get quickSpeciesSafi => 'Safi';

  @override
  String get quickSpeciesSobaity => 'Sobaity';

  @override
  String get quickSpeciesChanad => 'Chanad';

  @override
  String get quickSpeciesZubaidi => 'Zubaidi';

  @override
  String get quickSpeciesShrimp => 'Shrimp';

  @override
  String get phoneEightDigits => 'Phone number must be 8 digits';

  @override
  String get selectLocationFirst => 'Please select a location first';

  @override
  String get unexpectedError => 'An unexpected error occurred';

  @override
  String get probExcellent => 'Excellent';

  @override
  String get probVeryGood => 'Very Good';

  @override
  String get probModerate => 'Moderate';

  @override
  String get probWeak => 'Weak';

  @override
  String get probNotSuitable => 'Not Suitable';

  @override
  String get predictionTitle => 'Catch Prediction';

  @override
  String get hideMap => 'Hide Map';

  @override
  String get selectFromMap => 'Select from Map';

  @override
  String get tapMapToSelect => 'Tap the map to select a location';

  @override
  String get chooseSpecies => 'Choose Species';

  @override
  String get getPrediction => 'Get Prediction';

  @override
  String get retry => 'Retry';

  @override
  String get insideProtectedZone => 'Inside protected zone';

  @override
  String get factorSeason => 'Season';

  @override
  String get factorWeather => 'Weather';

  @override
  String get factorReports => 'Reports';

  @override
  String get factorProximity => 'Proximity to Spots';

  @override
  String get nearbyFishingSpots => 'Nearby Fishing Spots';

  @override
  String get kmUnit => 'km';

  @override
  String get tripResumed => 'Trip resumed';

  @override
  String get endTrip => 'End Trip';

  @override
  String get endCurrentTrip => 'Are you sure you want to end this trip?';

  @override
  String get tripEndedAndSaved => 'Trip ended and saved';

  @override
  String get deleteTrip => 'Delete Trip';

  @override
  String deleteTripConfirmFinished(String name) {
    return 'Delete the trip \'$name\'?';
  }

  @override
  String get delete => 'Delete';

  @override
  String get deleteActiveTrip => 'Delete Active Trip';

  @override
  String get deleteTripConfirm => 'This trip is still active. Are you sure you want to delete it?';

  @override
  String get tripDeleted => 'Trip deleted';

  @override
  String get noTripsYet => 'No trips yet';

  @override
  String get tapStartTrip => 'Tap the button below to start your first trip';

  @override
  String get resumeTrip => 'Resume Trip';

  @override
  String get startTrip => 'Start Trip';

  @override
  String get tripInProgress => 'Trip in progress';

  @override
  String get catchWord => 'catch';

  @override
  String get catches => 'catches';

  @override
  String get addCatch => 'Add Catch';

  @override
  String get logCatchTitle => 'Log a Catch';

  @override
  String get catchDetails => 'Catch Details';

  @override
  String get speciesNameLabel => 'Species Name';

  @override
  String get speciesRequired => 'Species is required';

  @override
  String get notesOptionalLabel => 'Notes (Optional)';

  @override
  String get catchLocationLabel => 'Catch Location';

  @override
  String get pinnedOnMap => 'Pinned on map';

  @override
  String get gpsLocationLabel => 'GPS location';

  @override
  String get locationNotSet => 'Location not set';

  @override
  String get mapLabel => 'Map';

  @override
  String get tripActiveLabel => 'Active';

  @override
  String get tripStartedLabel => 'Started';

  @override
  String get tripDurationLabel => 'Duration';

  @override
  String get tripCatchesLabel => 'Catches';

  @override
  String get mapLayers => 'Map Layers';

  @override
  String get depthVisualization => 'Depth Visualization';

  @override
  String get showDepthLayer => 'Show depth layer';

  @override
  String get visualizationType => 'Visualization Type';

  @override
  String get opacityLabel => 'Opacity';

  @override
  String get protectedExclusionZones => 'Protected & Exclusion Zones';

  @override
  String get protectedZones => 'Protected Zones';

  @override
  String featuresLoaded(int count) {
    return '$count features loaded';
  }

  @override
  String get marineReservesReefs => 'Marine Reserves & Reefs';

  @override
  String get mpaRestrictedArea => 'MPA / Restricted Area';

  @override
  String get oilGasExclusion => 'Oil & Gas Exclusion';

  @override
  String get safetyBuffersVisible => 'Safety buffers visible';

  @override
  String get safetyRulesApplyWhenHidden => 'Safety rules apply when hidden';

  @override
  String get fishingSpotSuggestions => 'Fishing Spot Suggestions';

  @override
  String get showFishingSpots => 'Show fishing spots';

  @override
  String get zonesMpasLocations => 'Zones, MPAs & locations';

  @override
  String get highConfidenceSpot => 'High confidence spot';

  @override
  String get mediumConfidenceSpot => 'Medium confidence spot';

  @override
  String get fishingZone => 'Fishing zone';

  @override
  String get fishingPrediction => 'Fishing Prediction';

  @override
  String get aiCatchProbability => 'AI catch probability';

  @override
  String get celestialAlmanac => 'Celestial Almanac';

  @override
  String get solarNoon => 'Solar Noon';

  @override
  String get emergency => 'Emergency';

  @override
  String get emergencyComingSoon => 'Emergency features are coming soon.';

  @override
  String get emergencyContacts => 'Emergency Contacts';

  @override
  String get coastGuard => 'Coast Guard';

  @override
  String get marineRescue => 'Marine Rescue';

  @override
  String get police => 'Police';

  @override
  String get ambulance => 'Ambulance';

  @override
  String get fishingRules => 'Fishing Rules';

  @override
  String get sosLongPressHint => 'Long-press 3 seconds to activate SOS';

  @override
  String get emergencyChannelHint => 'Emergency VHF Channel 16';

  @override
  String get rule1Title => 'Fishing Licence';

  @override
  String get rule1Body => 'All fishers must hold a valid fishing licence issued by the Ministry of Works, Municipalities Affairs & Urban Planning.';

  @override
  String get rule2Title => 'Protected Areas';

  @override
  String get rule2Body => 'Fishing is strictly prohibited within designated marine protected areas and restricted military zones shown on the map.';

  @override
  String get rule3Title => 'Equipment';

  @override
  String get rule3Body => 'Use of explosives, poisons, or electric shocks to catch fish is illegal and punishable by law.';

  @override
  String get rule4Title => 'Protected Species';

  @override
  String get rule4Body => 'Catching, trading, or possessing protected species (hawksbill turtle, dugong, whale shark) is prohibited.';

  @override
  String get rule5Title => 'Night Fishing';

  @override
  String get rule5Body => 'Night fishing requires proper navigation lights and is restricted in certain zones. Check local regulations.';

  @override
  String get rule6Title => 'Vessel Safety';

  @override
  String get rule6Body => 'Life jackets are mandatory for all passengers. Vessels must carry a working VHF radio and flares.';
}
