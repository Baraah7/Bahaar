import 'package:flutter/material.dart';

class MapLocalizations {
  const MapLocalizations._(this._locale);
  final Locale _locale;
  bool get _isAr => _locale.languageCode == 'ar';

  static MapLocalizations of(BuildContext context) =>
      MapLocalizations._(Localizations.localeOf(context));

  String get localeName => _locale.languageCode;

  String get cancel => _isAr ? 'إلغاء' : 'Cancel';
  String get reset => _isAr ? 'إعادة تعيين' : 'Reset';
  String get fishingMap => _isAr ? 'خريطة الصيد' : 'Fishing Map';
  String get mapLayers => _isAr ? 'طبقات الخريطة' : 'Map Layers';
  String get depthVisualization => _isAr ? 'تصور العمق' : 'Depth Visualization';
  String get showDepthLayer => _isAr ? 'عرض طبقة العمق' : 'Show depth layer';
  String get visualizationType => _isAr ? 'نوع التصور' : 'Visualization Type';
  String get opacityLabel => _isAr ? 'الشفافية' : 'Opacity';
  String get protectedExclusionZones => _isAr ? 'المناطق المحمية والمحظورة' : 'Protected & Exclusion Zones';
  String get protectedZones => _isAr ? 'المناطق المحمية' : 'Protected Zones';
  String get marineReservesReefs => _isAr ? 'المحميات البحرية والشعاب' : 'Marine Reserves & Reefs';
  String get mpaRestrictedArea => _isAr ? 'منطقة MPA / مقيدة' : 'MPA / Restricted Area';
  String get oilGasExclusion => _isAr ? 'منطقة النفط والغاز المحظورة' : 'Oil & Gas Exclusion';
  String get safetyBuffersVisible => _isAr ? 'مخازن السلامة مرئية' : 'Safety buffers visible';
  String get safetyRulesApplyWhenHidden => _isAr ? 'قواعد السلامة تُطبق عند الإخفاء' : 'Safety rules apply when hidden';
  String get fishingSpotSuggestions => _isAr ? 'اقتراحات أماكن الصيد' : 'Fishing Spot Suggestions';
  String get showFishingSpots => _isAr ? 'عرض أماكن الصيد' : 'Show fishing spots';
  String get zonesMpasLocations => _isAr ? 'المناطق، MPAs والمواقع' : 'Zones, MPAs & locations';
  String get highConfidenceSpot => _isAr ? 'موقع ثقة عالية' : 'High confidence spot';
  String get mediumConfidenceSpot => _isAr ? 'موقع ثقة متوسطة' : 'Medium confidence spot';
  String get fishingZone => _isAr ? 'منطقة صيد' : 'Fishing zone';
  String get fishingPrediction => _isAr ? 'توقعات الصيد' : 'Fishing Prediction';
  String get aiCatchProbability => _isAr ? 'احتمالية الصيد بالذكاء الاصطناعي' : 'AI catch probability';
  String featuresLoaded(int count) => _isAr ? 'تم تحميل $count عنصر' : '$count features loaded';
  String get navigationReady => _isAr ? 'الملاحة جاهزة' : 'Navigation Ready';
  String get calculatingRoute => _isAr ? 'جاري حساب المسار...' : 'Calculating route...';
  String get portNavigation => _isAr ? 'ملاحة الميناء' : 'Port Navigation';
  String get selectPortInstruction => _isAr
      ? '١. اختر ميناءً (أيقونة المرساة)\n٢. اضغط على وجهتك في البحر'
      : '1. Select a port (anchor icon)\n2. Tap sea destination on map';
  String get tapSeaDestination => _isAr ? '٢. اضغط على وجهة البحر' : '2. Tap sea destination on map';
  String get pleaseSelectWaterDestination => _isAr ? 'يرجى اختيار وجهة مائية' : 'Please select a water destination';
  String get seaDestinationSet => _isAr ? 'تم تحديد وجهة البحر. اختر ميناءً للبداية.' : 'Sea destination set. Select a port to start from.';
  String get portSelected => _isAr ? 'تم اختيار الميناء' : 'Port selected';
  String get locationNotAvailable => _isAr ? 'الموقع غير متاح' : 'Location not available';
  String get couldNotFindRoute => _isAr ? 'تعذر إيجاد مسار' : 'Could not find a route';
  String get errorCalculatingRoute => _isAr ? 'خطأ في حساب المسار' : 'Error calculating route';
  String get routeCalculated => _isAr ? 'تم حساب المسار' : 'Route calculated';
  String get navigationStarted => _isAr ? 'بدأت الملاحة' : 'Navigation started';
  String get failedToStartNavigation => _isAr ? 'فشل بدء الملاحة' : 'Failed to start navigation';
  String get resetMask => _isAr ? 'إعادة ضبط القناع؟' : 'Reset Mask?';
  String get resetMaskConfirmation => _isAr
      ? 'سيؤدي هذا إلى تجاهل جميع تغييراتك واستعادة القناع الأصلي.'
      : 'This will discard all your changes and restore the original mask.';
  String get maskSavedSuccessfully => _isAr ? 'تم حفظ القناع بنجاح' : 'Mask saved successfully';
  String get failedToSaveMask => _isAr ? 'فشل حفظ القناع' : 'Failed to save mask';
  String get maskResetToOriginal => _isAr ? 'تمت إعادة القناع إلى الأصل' : 'Mask reset to original';
  String get failedToResetMask => _isAr ? 'فشل إعادة ضبط القناع' : 'Failed to reset mask';
  String get offlineMapCached => _isAr ? 'غير متصل — بلاطات الخريطة محفوظة' : 'Offline — map tiles cached';
  String get outsideTerritorialWaters => _isAr ? 'خارج المياه الإقليمية — اضغط على البحر' : 'Outside territorial waters — tap on the sea';
  String get tapOnSea => _isAr ? 'اضغط على البحر، لا على اليابسة' : 'Tap on the sea, not on land';
  String get chooseNavType => _isAr ? 'اختر نوع الملاحة' : 'Choose Navigation Type';
  String get landToSea => _isAr ? 'بر ← ميناء ← بحر' : 'Land → Port → Sea';
  String get landToSeaSubtitle => _isAr
      ? 'توجه إلى ميناء، ثم انطلق إلى وجهتك في البحر'
      : 'Drive to a port, then navigate to a sea destination';
  String get seaToSea => _isAr ? 'بحر ← بحر' : 'Sea → Sea';
  String get seaToSeaSubtitle => _isAr ? 'التنقل مباشرة بين نقطتين بحريتين' : 'Navigate directly between two sea points';
  String get returnSeaToLand => _isAr ? 'عودة: بحر ← ميناء ← بر' : 'Return: Sea → Port → Land';
  String get returnSeaToLandSubtitle => _isAr
      ? 'العودة من البحر، الرسو في الميناء، والتوجه إلى المنزل'
      : 'Return from sea, dock at a port, navigate home';

  String get tapSeaDeparture         => _isAr ? 'انقر على نقطة انطلاقك في البحر'         : 'Tap your departure point on the sea';
  String get stepTapSeaDeparture     => _isAr ? '١. انقر على نقطة الانطلاق في البحر'     : '1. Tap your departure point on the sea';
  String get stepTapSeaDestination   => _isAr ? '٢. انقر على وجهتك البحرية'               : '2. Tap your sea destination';
  String get stepTapPort             => _isAr
      ? '١. انقر على ميناء\n٢. انقر على الوجهة البحرية\n(انقر على البر لتغيير نقطة بدايتك)'
      : '1. Tap a port (anchor icon)\n2. Tap sea destination\n(Tap land to change your start location)';
  String get stepTapPortDock         => _isAr ? '٢. انقر على ميناء للرسو'                  : '2. Tap a port (anchor icon) to dock at';
  String get stepTapLandDestination  => _isAr ? '٣. انقر على وجهتك البرية'                : '3. Tap your land destination';
  String get customOriginSet         => _isAr ? 'تم تحديد نقطة الانطلاق'                  : 'Custom origin set';
  String get departureSet            => _isAr ? 'تم تحديد نقطة المغادرة'                  : 'Departure set';
  String get seaDepartureSet         => _isAr ? 'تم تحديد نقطة مغادرة البحر'              : 'Sea departure set';
  String get portLabel               => _isAr ? 'الميناء'                                  : 'Port';
  String get lastPort                => _isAr ? 'آخر ميناء'                               : 'Last port';
  String get landDestinationSet      => _isAr ? 'تم تحديد الوجهة البرية'                  : 'Land destination set';
  String get currentLocationOnLandRequired => _isAr
      ? 'الموقع الحالي غير متاح أو أنت في البحر. انقر على الخريطة لتحديد نقطة انطلاق برية.'
      : 'Current location not available or not on land. Tap the map to set a custom land origin.';
  String get selectBothPortAndDestination => _isAr
      ? 'يرجى اختيار الميناء والوجهة البحرية'
      : 'Please select both port and sea destination';
  String get currentLocationNotAvailable  => _isAr ? 'الموقع الحالي غير متاح'             : 'Current location not available';
  String get couldNotFindLandRoute        => _isAr ? 'تعذر إيجاد مسار بري للميناء'        : 'Could not find land route to port';
  String get couldNotFindMarineRoute      => _isAr ? 'تعذر إيجاد مسار بحري من الميناء'   : 'Could not find marine route from port';
  String get loading                      => _isAr ? 'جاري التحميل...'                    : 'Loading...';
  String get logCatch                     => _isAr ? 'تسجيل صيد'                          : 'Log Catch';
}
