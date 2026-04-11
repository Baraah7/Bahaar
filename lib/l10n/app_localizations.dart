import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Bahaar'**
  String get appName;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @welcomeToBahaar.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Bahaar'**
  String get welcomeToBahaar;

  /// No description provided for @fishingMap.
  ///
  /// In en, this message translates to:
  /// **'Fishing Map'**
  String get fishingMap;

  /// No description provided for @fishingMapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Interactive map with depth colors'**
  String get fishingMapSubtitle;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @weatherSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check marine weather'**
  String get weatherSubtitle;

  /// No description provided for @fishRecognition.
  ///
  /// In en, this message translates to:
  /// **'Fish Recognition'**
  String get fishRecognition;

  /// No description provided for @fishRecognitionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Identify fish species'**
  String get fishRecognitionSubtitle;

  /// No description provided for @marinerHarvest.
  ///
  /// In en, this message translates to:
  /// **'Mariner Harvest'**
  String get marinerHarvest;

  /// No description provided for @marinerHarvestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Buy & sell fresh fish'**
  String get marinerHarvestSubtitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @loadingRecognitionModel.
  ///
  /// In en, this message translates to:
  /// **'Loading recognition model...'**
  String get loadingRecognitionModel;

  /// No description provided for @takePhotoOfFish.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of fish or shrimp'**
  String get takePhotoOfFish;

  /// No description provided for @systemWillIdentify.
  ///
  /// In en, this message translates to:
  /// **'The system will identify the species automatically'**
  String get systemWillIdentify;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @newImage.
  ///
  /// In en, this message translates to:
  /// **'New Image'**
  String get newImage;

  /// No description provided for @supportedSpecies.
  ///
  /// In en, this message translates to:
  /// **'Supported Species'**
  String get supportedSpecies;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @tryTakingClearerPhoto.
  ///
  /// In en, this message translates to:
  /// **'Try taking a clearer photo for better results'**
  String get tryTakingClearerPhoto;

  /// No description provided for @failedToLoadModel.
  ///
  /// In en, this message translates to:
  /// **'Failed to load recognition model'**
  String get failedToLoadModel;

  /// No description provided for @failedToOpenCamera.
  ///
  /// In en, this message translates to:
  /// **'Failed to open camera'**
  String get failedToOpenCamera;

  /// No description provided for @failedToSelectImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to select image'**
  String get failedToSelectImage;

  /// No description provided for @modelNotReady.
  ///
  /// In en, this message translates to:
  /// **'Model not ready'**
  String get modelNotReady;

  /// No description provided for @classificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Classification failed'**
  String get classificationFailed;

  /// No description provided for @hourlyForecast.
  ///
  /// In en, this message translates to:
  /// **'Next 24 Hours'**
  String get hourlyForecast;

  /// No description provided for @dailyForecast.
  ///
  /// In en, this message translates to:
  /// **'Day Forecast'**
  String get dailyForecast;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @uvIndex.
  ///
  /// In en, this message translates to:
  /// **'UV Index'**
  String get uvIndex;

  /// No description provided for @feelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels Like'**
  String get feelsLike;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @sunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get sunset;

  /// No description provided for @unableToLoadWeather.
  ///
  /// In en, this message translates to:
  /// **'Unable to load weather'**
  String get unableToLoadWeather;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @navigationReady.
  ///
  /// In en, this message translates to:
  /// **'Navigation Ready'**
  String get navigationReady;

  /// No description provided for @calculatingRoute.
  ///
  /// In en, this message translates to:
  /// **'Calculating route...'**
  String get calculatingRoute;

  /// No description provided for @portNavigation.
  ///
  /// In en, this message translates to:
  /// **'Port Navigation'**
  String get portNavigation;

  /// No description provided for @selectPortInstruction.
  ///
  /// In en, this message translates to:
  /// **'1. Select a port (anchor icon)\n2. Tap sea destination on map'**
  String get selectPortInstruction;

  /// No description provided for @tapSeaDestination.
  ///
  /// In en, this message translates to:
  /// **'2. Tap sea destination on map'**
  String get tapSeaDestination;

  /// No description provided for @pleaseSelectWaterDestination.
  ///
  /// In en, this message translates to:
  /// **'Please select a water destination'**
  String get pleaseSelectWaterDestination;

  /// No description provided for @seaDestinationSet.
  ///
  /// In en, this message translates to:
  /// **'Sea destination set. Select a port to start from.'**
  String get seaDestinationSet;

  /// No description provided for @portSelected.
  ///
  /// In en, this message translates to:
  /// **'Port selected'**
  String get portSelected;

  /// No description provided for @locationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Location not available'**
  String get locationNotAvailable;

  /// No description provided for @couldNotFindRoute.
  ///
  /// In en, this message translates to:
  /// **'Could not find a route'**
  String get couldNotFindRoute;

  /// No description provided for @errorCalculatingRoute.
  ///
  /// In en, this message translates to:
  /// **'Error calculating route'**
  String get errorCalculatingRoute;

  /// No description provided for @couldNotFindLandRoute.
  ///
  /// In en, this message translates to:
  /// **'Could not find land route to port'**
  String get couldNotFindLandRoute;

  /// No description provided for @couldNotFindMarineRoute.
  ///
  /// In en, this message translates to:
  /// **'Could not find marine route from port'**
  String get couldNotFindMarineRoute;

  /// No description provided for @routeCalculated.
  ///
  /// In en, this message translates to:
  /// **'Route calculated'**
  String get routeCalculated;

  /// No description provided for @navigationStarted.
  ///
  /// In en, this message translates to:
  /// **'Navigation started'**
  String get navigationStarted;

  /// No description provided for @failedToStartNavigation.
  ///
  /// In en, this message translates to:
  /// **'Failed to start navigation'**
  String get failedToStartNavigation;

  /// No description provided for @resetMask.
  ///
  /// In en, this message translates to:
  /// **'Reset Mask?'**
  String get resetMask;

  /// No description provided for @resetMaskConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This will discard all your changes and restore the original mask.'**
  String get resetMaskConfirmation;

  /// No description provided for @maskSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Mask saved successfully'**
  String get maskSavedSuccessfully;

  /// No description provided for @failedToSaveMask.
  ///
  /// In en, this message translates to:
  /// **'Failed to save mask'**
  String get failedToSaveMask;

  /// No description provided for @maskResetToOriginal.
  ///
  /// In en, this message translates to:
  /// **'Mask reset to original'**
  String get maskResetToOriginal;

  /// No description provided for @failedToResetMask.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset mask'**
  String get failedToResetMask;

  /// No description provided for @selectBothPortAndDestination.
  ///
  /// In en, this message translates to:
  /// **'Please select both port and sea destination'**
  String get selectBothPortAndDestination;

  /// No description provided for @currentLocationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Current location not available'**
  String get currentLocationNotAvailable;

  String get chooseNavType;
  String get landToSea;
  String get landToSeaSubtitle;
  String get seaToSea;
  String get seaToSeaSubtitle;
  String get returnSeaToLand;
  String get returnSeaToLandSubtitle;
  String get tapSeaDeparture;
  String get stepTapSeaDeparture;
  String get stepTapSeaDestination;
  String get stepTapPort;
  String get stepTapPortDock;
  String get stepTapLandDestination;
  String get customOriginSet;
  String get departureSet;
  String get seaDepartureSet;
  String get portLabel;
  String get lastPort;
  String get landDestinationSet;
  String get offlineMapCached;
  String get outsideTerritorialWaters;
  String get tapOnSea;
  String get currentLocationOnLandRequired;
  String get tripDetailTitle;
  String get tripStart;
  String get tripEnd;
  String get totalWeight;
  String get noCatchesLogged;
  String get deleteCatch;
  String removeCatchConfirm(String species);
  String get addCatchLabel;
  String get editCatch;
  String get saveChanges;
  String get speciesName;
  String get notesOptional;
  String get pinOnMap;
  String get latitude;
  String get longitude;
  String get locationPinned;
  String get ongoing;
  String get pickCatchTime;
  String get quickSpeciesHamour;
  String get quickSpeciesSafi;
  String get quickSpeciesSobaity;
  String get quickSpeciesChanad;
  String get quickSpeciesZubaidi;
  String get quickSpeciesShrimp;
  String get quickSpeciesCrab;

  /// No description provided for @fishingLog.
  ///
  /// In en, this message translates to:
  /// **'Fishing Log'**
  String get fishingLog;

  String get tripAlreadyActive;
  String get endActiveTripFirst;
  String get endButtonLabel;
  String get tripNameHint;
  String get editTitleTooltip;
  String get deleteTripTooltip;
  String get signInToTrack;
  String get forgotPasswordHint;
  String get sendResetLink;
  String get resetLinkSent;
  String get resetLinkFailed;
  String get signInToSell;

  /// No description provided for @tripInProgress.
  ///
  /// In en, this message translates to:
  /// **'Trip in progress'**
  String get tripInProgress;

  /// No description provided for @tripResumed.
  ///
  /// In en, this message translates to:
  /// **'Trip resumed.'**
  String get tripResumed;

  /// No description provided for @tripEndedAndSaved.
  ///
  /// In en, this message translates to:
  /// **'Trip ended and saved.'**
  String get tripEndedAndSaved;

  /// No description provided for @catchWord.
  ///
  /// In en, this message translates to:
  /// **'catch'**
  String get catchWord;

  /// No description provided for @catches.
  ///
  /// In en, this message translates to:
  /// **'catches'**
  String get catches;

  /// No description provided for @noTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get noTripsYet;

  /// No description provided for @tapStartTrip.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Start Trip\" to begin logging your catches.'**
  String get tapStartTrip;

  /// No description provided for @endTrip.
  ///
  /// In en, this message translates to:
  /// **'End Trip'**
  String get endTrip;

  /// No description provided for @endCurrentTrip.
  ///
  /// In en, this message translates to:
  /// **'End your current fishing trip?'**
  String get endCurrentTrip;

  /// No description provided for @deleteActiveTrip.
  ///
  /// In en, this message translates to:
  /// **'Delete Active Trip?'**
  String get deleteActiveTrip;

  /// No description provided for @deleteTripConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the current trip and all catches logged so far. This cannot be undone.'**
  String get deleteTripConfirm;

  /// No description provided for @tripDeleted.
  ///
  /// In en, this message translates to:
  /// **'Trip deleted.'**
  String get tripDeleted;

  /// No description provided for @logCatch.
  ///
  /// In en, this message translates to:
  /// **'Log Catch'**
  String get logCatch;

  /// No description provided for @deleteTrip.
  ///
  /// In en, this message translates to:
  /// **'Delete Trip?'**
  String get deleteTrip;

  /// No description provided for @deleteTripConfirmFinished.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete \"{tripTitle}\" and all catches logged. This cannot be undone.'**
  String deleteTripConfirmFinished(Object tripTitle);

  /// No description provided for @cannotStartTrip.
  ///
  /// In en, this message translates to:
  /// **'Cannot start trip: {error}'**
  String cannotStartTrip(Object error);

  /// No description provided for @enterTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter trip title (optional)'**
  String get enterTripTitle;

  /// No description provided for @startTrip.
  ///
  /// In en, this message translates to:
  /// **'Start Trip'**
  String get startTrip;

  /// No description provided for @resumeTrip.
  ///
  /// In en, this message translates to:
  /// **'Resume Trip'**
  String get resumeTrip;

  /// No description provided for @editTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Trip Title'**
  String get editTripTitle;

  /// No description provided for @enterTripTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter trip title'**
  String get enterTripTitleHint;

  /// No description provided for @addCatch.
  ///
  /// In en, this message translates to:
  /// **'Add Catch'**
  String get addCatch;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @sellFish.
  ///
  /// In en, this message translates to:
  /// **'Sell Fish'**
  String get sellFish;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @searchFishSellerLocation.
  ///
  /// In en, this message translates to:
  /// **'Search fish, seller, location...'**
  String get searchFishSellerLocation;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @filterByFishType.
  ///
  /// In en, this message translates to:
  /// **'Filter by Fish Type'**
  String get filterByFishType;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// No description provided for @filterByCondition.
  ///
  /// In en, this message translates to:
  /// **'Filter by Condition'**
  String get filterByCondition;

  /// No description provided for @allConditions.
  ///
  /// In en, this message translates to:
  /// **'All Conditions'**
  String get allConditions;

  /// No description provided for @noFishListingsFound.
  ///
  /// In en, this message translates to:
  /// **'No fish listings found'**
  String get noFishListingsFound;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get tryAdjustingFilters;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @ordersWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Orders from buyers will appear here'**
  String get ordersWillAppearHere;

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order Placed!'**
  String get orderPlaced;

  /// No description provided for @youHaveOrdered.
  ///
  /// In en, this message translates to:
  /// **'You have ordered'**
  String get youHaveOrdered;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @waitingForSeller.
  ///
  /// In en, this message translates to:
  /// **'Waiting for seller to accept your order.'**
  String get waitingForSeller;

  /// No description provided for @yourFishListingPosted.
  ///
  /// In en, this message translates to:
  /// **'Your fish listing has been posted!'**
  String get yourFishListingPosted;

  /// No description provided for @orderAccepted.
  ///
  /// In en, this message translates to:
  /// **'Order accepted!'**
  String get orderAccepted;

  /// No description provided for @orderRejected.
  ///
  /// In en, this message translates to:
  /// **'Order rejected'**
  String get orderRejected;

  /// No description provided for @orderCompleted.
  ///
  /// In en, this message translates to:
  /// **'Order marked as completed!'**
  String get orderCompleted;

  /// No description provided for @rejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Reject Order'**
  String get rejectOrder;

  /// No description provided for @areYouSureRejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this order?'**
  String get areYouSureRejectOrder;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reasonOptional;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markAsCompleted;

  /// No description provided for @buyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get buyer;

  /// No description provided for @paymentProof.
  ///
  /// In en, this message translates to:
  /// **'Payment Proof'**
  String get paymentProof;

  /// No description provided for @tapToViewFullImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to view full image'**
  String get tapToViewFullImage;

  /// No description provided for @sellerInformation.
  ///
  /// In en, this message translates to:
  /// **'Seller Information'**
  String get sellerInformation;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @yourInformation.
  ///
  /// In en, this message translates to:
  /// **'Your Information'**
  String get yourInformation;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @contactSeller.
  ///
  /// In en, this message translates to:
  /// **'Contact Seller'**
  String get contactSeller;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @deliveryLocationOptional.
  ///
  /// In en, this message translates to:
  /// **'Delivery Location (optional)'**
  String get deliveryLocationOptional;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @uploadPaymentProof.
  ///
  /// In en, this message translates to:
  /// **'Upload Payment Proof'**
  String get uploadPaymentProof;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @pleaseUploadPaymentScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Please upload a screenshot of your Benefit Pay payment'**
  String get pleaseUploadPaymentScreenshot;

  /// No description provided for @tapToUploadScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload screenshot'**
  String get tapToUploadScreenshot;

  /// No description provided for @paymentProofUploaded.
  ///
  /// In en, this message translates to:
  /// **'Payment proof uploaded'**
  String get paymentProofUploaded;

  /// No description provided for @pleaseUploadPaymentProofScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Please upload your payment proof screenshot'**
  String get pleaseUploadPaymentProofScreenshot;

  /// No description provided for @pricePerKg.
  ///
  /// In en, this message translates to:
  /// **'Price per kg'**
  String get pricePerKg;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// No description provided for @catchLocation.
  ///
  /// In en, this message translates to:
  /// **'Catch Location'**
  String get catchLocation;

  /// No description provided for @catchDate.
  ///
  /// In en, this message translates to:
  /// **'Catch Date'**
  String get catchDate;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @benefitPay.
  ///
  /// In en, this message translates to:
  /// **'Benefit Pay'**
  String get benefitPay;

  /// No description provided for @payWithCashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Pay with cash on delivery'**
  String get payWithCashOnDelivery;

  /// No description provided for @payInstantlyViaBenefitPay.
  ///
  /// In en, this message translates to:
  /// **'Pay instantly via Benefit Pay'**
  String get payInstantlyViaBenefitPay;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'sales'**
  String get sales;

  /// No description provided for @fishPhotos.
  ///
  /// In en, this message translates to:
  /// **'Fish Photos'**
  String get fishPhotos;

  /// No description provided for @addPhotosOfFish.
  ///
  /// In en, this message translates to:
  /// **'Add photos of your fish (optional)'**
  String get addPhotosOfFish;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @fishDetails.
  ///
  /// In en, this message translates to:
  /// **'Fish Details'**
  String get fishDetails;

  /// No description provided for @fishType.
  ///
  /// In en, this message translates to:
  /// **'Fish Type'**
  String get fishType;

  /// No description provided for @customFishName.
  ///
  /// In en, this message translates to:
  /// **'Custom Fish Name'**
  String get customFishName;

  /// No description provided for @pleaseEnterFishName.
  ///
  /// In en, this message translates to:
  /// **'Please enter the fish name'**
  String get pleaseEnterFishName;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// No description provided for @pricePerKgBD.
  ///
  /// In en, this message translates to:
  /// **'Price per kg (BD)'**
  String get pricePerKgBD;

  /// No description provided for @catchLocationOptional.
  ///
  /// In en, this message translates to:
  /// **'Catch Location (optional)'**
  String get catchLocationOptional;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @selectAcceptedPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Select accepted payment methods:'**
  String get selectAcceptedPaymentMethods;

  /// No description provided for @acceptCashPayment.
  ///
  /// In en, this message translates to:
  /// **'Accept cash payment'**
  String get acceptCashPayment;

  /// No description provided for @acceptBenefitPay.
  ///
  /// In en, this message translates to:
  /// **'Accept Benefit Pay'**
  String get acceptBenefitPay;

  /// No description provided for @benefitPayQRCode.
  ///
  /// In en, this message translates to:
  /// **'Benefit Pay QR Code / Payment Info'**
  String get benefitPayQRCode;

  /// No description provided for @uploadBenefitPayQRCode.
  ///
  /// In en, this message translates to:
  /// **'Upload Benefit Pay QR Code'**
  String get uploadBenefitPayQRCode;

  /// No description provided for @buyersWillSeeThis.
  ///
  /// In en, this message translates to:
  /// **'Buyers will see this when they select Benefit Pay'**
  String get buyersWillSeeThis;

  /// No description provided for @postListing.
  ///
  /// In en, this message translates to:
  /// **'Post Listing'**
  String get postListing;

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your Location (optional)'**
  String get yourLocation;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedIn;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get guestMode;

  /// No description provided for @areYouSureSignOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get areYouSureSignOut;

  /// No description provided for @fresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get fresh;

  /// No description provided for @frozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get frozen;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @minAgo.
  ///
  /// In en, this message translates to:
  /// **'min ago'**
  String get minAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'hours ago'**
  String get hoursAgo;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get daysAgo;

  /// No description provided for @weatherNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get weatherNow;

  /// No description provided for @weatherToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get weatherToday;

  /// No description provided for @weatherGusts.
  ///
  /// In en, this message translates to:
  /// **'Gusts up to'**
  String get weatherGusts;

  /// No description provided for @weatherDewPoint.
  ///
  /// In en, this message translates to:
  /// **'Dew'**
  String get weatherDewPoint;

  /// No description provided for @weatherTodayTides.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Tides'**
  String get weatherTodayTides;

  /// No description provided for @weatherTideUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Tide data unavailable'**
  String get weatherTideUnavailable;

  /// No description provided for @weatherHighTide.
  ///
  /// In en, this message translates to:
  /// **'High Tide'**
  String get weatherHighTide;

  /// No description provided for @weatherLowTide.
  ///
  /// In en, this message translates to:
  /// **'Low Tide'**
  String get weatherLowTide;

  /// No description provided for @moonrise.
  ///
  /// In en, this message translates to:
  /// **'Moonrise'**
  String get moonrise;

  /// No description provided for @moonset.
  ///
  /// In en, this message translates to:
  /// **'Moonset'**
  String get moonset;

  /// No description provided for @illuminated.
  ///
  /// In en, this message translates to:
  /// **'% illuminated'**
  String get illuminated;

  /// No description provided for @uvLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get uvLow;

  /// No description provided for @uvModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get uvModerate;

  /// No description provided for @uvHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get uvHigh;

  /// No description provided for @uvVeryHigh.
  ///
  /// In en, this message translates to:
  /// **'Very High'**
  String get uvVeryHigh;

  /// No description provided for @uvExtreme.
  ///
  /// In en, this message translates to:
  /// **'Extreme'**
  String get uvExtreme;

  /// No description provided for @visibilityClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get visibilityClear;

  /// No description provided for @visibilityGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get visibilityGood;

  /// No description provided for @visibilityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get visibilityLow;

  /// No description provided for @feelsLikeSimilar.
  ///
  /// In en, this message translates to:
  /// **'Similar to actual'**
  String get feelsLikeSimilar;

  /// No description provided for @feelsLikeWarmer.
  ///
  /// In en, this message translates to:
  /// **'Feels warmer'**
  String get feelsLikeWarmer;

  /// No description provided for @feelsLikeCooler.
  ///
  /// In en, this message translates to:
  /// **'Feels cooler'**
  String get feelsLikeCooler;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to continue your journey?\nYour path is right here.'**
  String get loginSubtitle;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @passwordResetComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Password reset coming soon'**
  String get passwordResetComingSoon;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get createYourAccount;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help you reach the peaks\nof fishing. Are you ready?'**
  String get signupSubtitle;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @usernameField.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameField;

  /// No description provided for @confirmPasswordField.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordField;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration successful!'**
  String get registrationSuccessful;

  /// No description provided for @validationEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get validationEnterName;

  /// No description provided for @validationNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get validationNameTooShort;

  /// No description provided for @validationEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get validationEnterEmail;

  /// No description provided for @validationInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get validationInvalidEmail;

  /// No description provided for @validationEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get validationEnterPassword;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get validationPasswordTooShort;

  /// No description provided for @validationEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get validationEnterUsername;

  /// No description provided for @validationUsernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get validationUsernameTooShort;

  /// No description provided for @validationUsernameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Username must be less than 20 characters'**
  String get validationUsernameTooLong;

  /// No description provided for @validationUsernameInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Username can only contain letters, numbers, and underscores'**
  String get validationUsernameInvalidChars;

  /// No description provided for @validationConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get validationConfirmPassword;

  /// No description provided for @validationPasswordsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordsNoMatch;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestUser;

  /// No description provided for @guestAccount.
  ///
  /// In en, this message translates to:
  /// **'Guest Account'**
  String get guestAccount;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get accountStatus;

  /// No description provided for @guestBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your full profile and seller features.'**
  String get guestBannerMessage;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @policyDataCollection.
  ///
  /// In en, this message translates to:
  /// **'Data Collection'**
  String get policyDataCollection;

  /// No description provided for @policyDataCollectionBody.
  ///
  /// In en, this message translates to:
  /// **'Bahaar collects location data, catch logs, and account information solely to provide fishing assistance services. We do not sell your data to third parties.'**
  String get policyDataCollectionBody;

  /// No description provided for @policyLocation.
  ///
  /// In en, this message translates to:
  /// **'Location Usage'**
  String get policyLocation;

  /// No description provided for @policyLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Location data is used for weather forecasts, fishing maps, and navigation features. Location is never stored beyond your active session unless you explicitly save a log.'**
  String get policyLocationBody;

  /// No description provided for @policyFishRecognition.
  ///
  /// In en, this message translates to:
  /// **'Fish Recognition'**
  String get policyFishRecognition;

  /// No description provided for @policyFishRecognitionBody.
  ///
  /// In en, this message translates to:
  /// **'Images submitted for fish identification are processed locally on-device using TensorFlow Lite. Images are not uploaded to any server.'**
  String get policyFishRecognitionBody;

  /// No description provided for @policyAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Account & Authentication'**
  String get policyAuthentication;

  /// No description provided for @policyAuthenticationBody.
  ///
  /// In en, this message translates to:
  /// **'Authentication is handled securely through Firebase. Passwords are never stored in plain text. Guest sessions are anonymous and contain no personally identifiable information.'**
  String get policyAuthenticationBody;

  /// No description provided for @policyRetention.
  ///
  /// In en, this message translates to:
  /// **'Data Retention'**
  String get policyRetention;

  /// No description provided for @policyRetentionBody.
  ///
  /// In en, this message translates to:
  /// **'Your fishing logs and account data are stored in your personal Firebase account. You may delete your data at any time by contacting support or deleting your account.'**
  String get policyRetentionBody;

  /// No description provided for @policyContactSection.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get policyContactSection;

  /// No description provided for @policyContactSectionBody.
  ///
  /// In en, this message translates to:
  /// **'For privacy-related inquiries, please contact the Bahaar development team through the app support channel.'**
  String get policyContactSectionBody;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Login Required'**
  String get loginRequired;

  /// No description provided for @guestAccountLoginMessage.
  ///
  /// In en, this message translates to:
  /// **'You need to sign in to place an order.\nGuest accounts cannot buy or sell fish.'**
  String get guestAccountLoginMessage;

  /// No description provided for @guestAccountSellMessage.
  ///
  /// In en, this message translates to:
  /// **'You need to sign in to post a listing.\nGuest accounts cannot sell fish.'**
  String get guestAccountSellMessage;

  /// No description provided for @phoneNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Phone number copied'**
  String get phoneNumberCopied;

  /// No description provided for @sellingTab.
  ///
  /// In en, this message translates to:
  /// **'Selling ({count})'**
  String sellingTab(int count);

  /// No description provided for @purchasesTab.
  ///
  /// In en, this message translates to:
  /// **'Purchases ({count})'**
  String purchasesTab(int count);

  /// No description provided for @pleaseLoginToViewOrders.
  ///
  /// In en, this message translates to:
  /// **'Please login to view orders'**
  String get pleaseLoginToViewOrders;

  /// No description provided for @noOrdersForListings.
  ///
  /// In en, this message translates to:
  /// **'No orders for your listings yet'**
  String get noOrdersForListings;

  /// No description provided for @noPurchasesYet.
  ///
  /// In en, this message translates to:
  /// **'No purchases yet'**
  String get noPurchasesYet;

  /// No description provided for @whenSomeoneOrdersYourFish.
  ///
  /// In en, this message translates to:
  /// **'When someone orders your fish, it will appear here'**
  String get whenSomeoneOrdersYourFish;

  /// No description provided for @yourPurchasesWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Your purchases will appear here'**
  String get yourPurchasesWillAppear;

  /// No description provided for @fromYourFishingLog.
  ///
  /// In en, this message translates to:
  /// **'From Your Fishing Log'**
  String get fromYourFishingLog;

  /// No description provided for @tapRecentCatchToFill.
  ///
  /// In en, this message translates to:
  /// **'Tap a recent catch to pre-fill the form'**
  String get tapRecentCatchToFill;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @cleaned.
  ///
  /// In en, this message translates to:
  /// **'Cleaned'**
  String get cleaned;

  /// No description provided for @filleted.
  ///
  /// In en, this message translates to:
  /// **'Filleted'**
  String get filleted;

  /// No description provided for @kgUnit.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kgUnit;

  /// No description provided for @bdUnit.
  ///
  /// In en, this message translates to:
  /// **'BD'**
  String get bdUnit;

  /// No description provided for @bdPerKg.
  ///
  /// In en, this message translates to:
  /// **'BD/kg'**
  String get bdPerKg;

  /// No description provided for @sellerLabel.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get sellerLabel;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get rejectionReason;

  /// No description provided for @waitingForSellerToAccept.
  ///
  /// In en, this message translates to:
  /// **'Waiting for seller to accept your order'**
  String get waitingForSellerToAccept;

  /// No description provided for @orderAcceptedContactSeller.
  ///
  /// In en, this message translates to:
  /// **'Order accepted! Contact seller to arrange pickup.'**
  String get orderAcceptedContactSeller;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @confirmCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this order?'**
  String get confirmCancelOrder;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get orderCancelled;

  /// No description provided for @benefitPayIban.
  ///
  /// In en, this message translates to:
  /// **'Benefit Pay IBAN'**
  String get benefitPayIban;

  /// No description provided for @enterIban.
  ///
  /// In en, this message translates to:
  /// **'Enter IBAN number'**
  String get enterIban;

  /// No description provided for @ibanOrQrRequired.
  ///
  /// In en, this message translates to:
  /// **'Please upload QR code or enter IBAN number'**
  String get ibanOrQrRequired;

  /// No description provided for @deleteListing.
  ///
  /// In en, this message translates to:
  /// **'Delete Listing'**
  String get deleteListing;

  /// No description provided for @confirmDeleteListing.
  ///
  /// In en, this message translates to:
  /// **'Remove this listing from the marketplace?'**
  String get confirmDeleteListing;

  /// No description provided for @listingDeleted.
  ///
  /// In en, this message translates to:
  /// **'Listing deleted'**
  String get listingDeleted;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// No description provided for @priceRangeFilter.
  ///
  /// In en, this message translates to:
  /// **'Price: {min}–{max} BD/kg'**
  String priceRangeFilter(String min, String max);

  /// No description provided for @allPrices.
  ///
  /// In en, this message translates to:
  /// **'All Prices'**
  String get allPrices;

  /// No description provided for @orderPlacedTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Placed!'**
  String get orderPlacedTitle;

  /// No description provided for @youHaveOrderedFish.
  ///
  /// In en, this message translates to:
  /// **'You have ordered {fish}'**
  String youHaveOrderedFish(String fish);

  /// No description provided for @pleaseLoginToOrder.
  ///
  /// In en, this message translates to:
  /// **'Please login to place an order'**
  String get pleaseLoginToOrder;

  /// No description provided for @ibanOptional.
  ///
  /// In en, this message translates to:
  /// **'IBAN (optional)'**
  String get ibanOptional;

  /// No description provided for @sellerBenefitNote.
  ///
  /// In en, this message translates to:
  /// **'Buyer will see your Benefit Pay details to complete payment'**
  String get sellerBenefitNote;

  String get phoneEightDigits;

  // Map layer panel
  String get mapLayers;
  String get depthVisualization;
  String get protectedExclusionZones;
  String get fishingSpotSuggestions;
  String get showDepthLayer;
  String get visualizationType;
  String get opacityLabel;
  String get protectedZones;
  String get marineReservesReefs;
  String get mpaRestrictedArea;
  String get oilGasExclusion;
  String get safetyBuffersVisible;
  String get safetyRulesApplyWhenHidden;
  String get showFishingSpots;
  String get zonesMpasLocations;
  String get highConfidenceSpot;
  String get mediumConfidenceSpot;
  String get fishingZone;
  String get fishingPrediction;
  String get aiCatchProbability;
  String featuresLoaded(int count);

  // Main appbar popup
  String get emergency;
  String get emergencyComingSoon;

  // Trip card labels
  String get tripStartedLabel;
  String get tripDurationLabel;
  String get tripCatchesLabel;
  String get tripActiveLabel;

  // Prediction screen
  String get predictionTitle;
  String get selectLocationFirst;
  String get hideMap;
  String get selectFromMap;
  String get tapMapToSelect;
  String get chooseSpecies;
  String get getPrediction;
  String get retry;
  String get insideProtectedZone;
  String get nearbyFishingSpots;
  String get factorSeason;
  String get factorWeather;
  String get factorReports;
  String get factorProximity;
  String get probExcellent;
  String get probVeryGood;
  String get probModerate;
  String get probWeak;
  String get probNotSuitable;
  String get noInternetConnection;
  String get serverError;
  String get unexpectedError;
  String get kmUnit;

  // Celestial almanac
  String get celestialAlmanac;
  String get solarNoon;

  // Catch form
  String get logCatchTitle;
  String get catchDetails;
  String get speciesNameLabel;
  String get speciesRequired;
  String get notesOptionalLabel;
  String get pinnedOnMap;
  String get gpsLocationLabel;
  String get locationNotSet;
  String get catchLocationLabel;
  String get mapLabel;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
