import 'package:flutter/material.dart';

class FishingLogLocalizations {
  const FishingLogLocalizations._(this._locale);
  final Locale _locale;
  bool get _isAr => _locale.languageCode == 'ar';

  static FishingLogLocalizations of(BuildContext context) =>
      FishingLogLocalizations._(Localizations.localeOf(context));

  String get localeName => _locale.languageCode;

  String get fishingLog => _isAr ? 'سجل الصيد' : 'Fishing Log';
  String get tripDetailTitle => _isAr ? 'تفاصيل الرحلة' : 'Trip Detail';
  String get tripStart => _isAr ? 'البداية' : 'Start';
  String get tripEnd => _isAr ? 'النهاية' : 'End';
  String get totalWeight => _isAr ? 'الوزن الإجمالي' : 'Total weight';
  String get noCatchesLogged => _isAr ? 'لا توجد مصطادات مسجلة.' : 'No catches logged.';
  String get deleteCatch => _isAr ? 'حذف المصيد؟' : 'Delete catch?';
  String removeCatchConfirm(String species) => _isAr
      ? 'حذف "$species" من هذه الرحلة؟'
      : 'Remove "$species" from this trip?';
  String get editCatch => _isAr ? 'تعديل المصيد' : 'Edit Catch';
  String get saveChanges => _isAr ? 'حفظ التغييرات' : 'Save Changes';
  String get speciesName => _isAr ? 'اسم النوع *' : 'Species *';
  String get notesOptional => _isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)';
  String get pinOnMap => _isAr ? 'تثبيت على الخريطة' : 'Pin on Map';
  String get latitude => _isAr ? 'خط العرض' : 'Latitude';
  String get longitude => _isAr ? 'خط الطول' : 'Longitude';
  String get locationPinned => _isAr ? 'تم تثبيت الموقع على الخريطة.' : 'Location pinned on map.';
  String get ongoing => _isAr ? 'جارية' : 'Ongoing';
  String get pickCatchTime => _isAr ? 'اختر وقت الصيد' : 'Pick catch time';
  String get quickSpeciesHamour => _isAr ? 'هامور' : 'Hamour';
  String get quickSpeciesSafi => _isAr ? 'صافي' : 'Safi';
  String get quickSpeciesSobaity => _isAr ? 'صبيطي' : 'Sobaity';
  String get quickSpeciesChanad => _isAr ? 'شعور' : 'Chanad';
  String get quickSpeciesZubaidi => _isAr ? 'زبيدي' : 'Zubaidi';
  String get quickSpeciesShrimp => _isAr ? 'جمبري' : 'Shrimp';
  String get quickSpeciesCrab => _isAr ? 'سرطان البحر' : 'Crab';
  String get tripAlreadyActive => _isAr ? 'رحلة نشطة بالفعل — أنهها أولاً.' : 'A trip is already active — end it first.';
  String get endActiveTripFirst => _isAr ? 'أنهِ الرحلة النشطة أولاً.' : 'End the active trip first.';
  String get endButtonLabel => _isAr ? 'إنهاء' : 'End';
  String get editTripTitle => _isAr ? 'تعديل العنوان' : 'Edit Title';
  String get tripNameHint => _isAr ? 'اسم الرحلة' : 'Trip name';
  String get editTitleTooltip => _isAr ? 'تعديل العنوان' : 'Edit title';
  String get deleteTripTooltip => _isAr ? 'حذف الرحلة' : 'Delete trip';
  String get signInToTrack => _isAr ? 'سجّل الدخول لتتبع رحلاتك ومصطاداتك.' : 'Sign in to track your trips and catches.';
  String get tripResumed => _isAr ? 'استُؤنفت الرحلة' : 'Trip resumed';
  String get endTrip => _isAr ? 'إنهاء الرحلة' : 'End Trip';
  String get endCurrentTrip => _isAr ? 'هل أنت متأكد أنك تريد إنهاء هذه الرحلة؟' : 'Are you sure you want to end this trip?';
  String get tripEndedAndSaved => _isAr ? 'انتهت الرحلة وتم حفظها' : 'Trip ended and saved';
  String get deleteTrip => _isAr ? 'حذف الرحلة' : 'Delete Trip';
  String deleteTripConfirmFinished(String name) => _isAr
      ? 'حذف الرحلة \'$name\'؟'
      : "Delete the trip '$name'?";
  String get delete => _isAr ? 'حذف' : 'Delete';
  String get deleteActiveTrip => _isAr ? 'حذف الرحلة النشطة' : 'Delete Active Trip';
  String get deleteTripConfirm => _isAr
      ? 'هذه الرحلة لا تزال نشطة. هل أنت متأكد أنك تريد حذفها؟'
      : 'This trip is still active. Are you sure you want to delete it?';
  String get tripDeleted => _isAr ? 'تم حذف الرحلة' : 'Trip deleted';
  String get noTripsYet => _isAr ? 'لا توجد رحلات بعد' : 'No trips yet';
  String get tapStartTrip => _isAr ? 'اضغط على الزر أدناه لبدء أول رحلة' : 'Tap the button below to start your first trip';
  String get resumeTrip => _isAr ? 'استئناف الرحلة' : 'Resume Trip';
  String get startTrip => _isAr ? 'بدء رحلة جديدة' : 'Start New Trip';
  String get tripInProgress => _isAr ? 'رحلة جارية' : 'Trip in progress';
  String get catchWord => _isAr ? 'مصيد' : 'catch';
  String get catches => _isAr ? 'مصطادات' : 'catches';
  String get addCatch => _isAr ? 'إضافة مصيد' : 'Add Catch';
  String get logCatchTitle => _isAr ? 'تسجيل مصيد' : 'Log a Catch';
  String get catchDetails => _isAr ? 'تفاصيل المصيد' : 'Catch Details';
  String get speciesNameLabel => _isAr ? 'اسم النوع' : 'Species Name';
  String get speciesRequired => _isAr ? 'النوع مطلوب' : 'Species is required';
  String get notesOptionalLabel => _isAr ? 'ملاحظات (اختياري)' : 'Notes (Optional)';
  String get catchLocationLabel => _isAr ? 'موقع الصيد' : 'Catch Location';
  String get pinnedOnMap => _isAr ? 'مثبت على الخريطة' : 'Pinned on map';
  String get gpsLocationLabel => _isAr ? 'موقع GPS' : 'GPS location';
  String get locationNotSet => _isAr ? 'الموقع غير محدد' : 'Location not set';
  String get mapLabel => _isAr ? 'خريطة' : 'Map';
  String get tripActiveLabel => _isAr ? 'نشطة' : 'Active';
  String get tripStartedLabel => _isAr ? 'بدأت' : 'Started';
  String get tripDurationLabel => _isAr ? 'المدة' : 'Duration';
  String get tripCatchesLabel => _isAr ? 'المصطادات' : 'Catches';
  String get logCatch => _isAr ? 'تسجيل صيد' : 'Log Catch';
  String get kgUnit => _isAr ? 'كجم' : 'kg';
  String get cancel => _isAr ? 'إلغاء' : 'Cancel';
  String get save => _isAr ? 'حفظ' : 'Save';

  // Prediction screen strings
  String get selectLocationFirst => _isAr ? 'يرجى تحديد موقع أولاً' : 'Please select a location first';
  String get unexpectedError => _isAr ? 'حدث خطأ غير متوقع' : 'An unexpected error occurred';
  String get probExcellent => _isAr ? 'ممتاز' : 'Excellent';
  String get probVeryGood => _isAr ? 'جيد جداً' : 'Very Good';
  String get probModerate => _isAr ? 'متوسط' : 'Moderate';
  String get probWeak => _isAr ? 'ضعيف' : 'Weak';
  String get probNotSuitable => _isAr ? 'غير مناسب' : 'Not Suitable';
  String get predictionTitle => _isAr ? 'توقع الصيد' : 'Fishing Prediction';
  String get hideMap => _isAr ? 'إخفاء الخريطة' : 'Hide Map';
  String get selectFromMap => _isAr ? 'اختر من الخريطة' : 'Select from Map';
  String get tapMapToSelect => _isAr ? 'اضغط على الخريطة لتحديد موقع' : 'Tap the map to select a location';
  String get location => _isAr ? 'الموقع' : 'Location';
  String get chooseSpecies => _isAr ? 'اختر النوع' : 'Choose Species';
  String get getPrediction => _isAr ? 'احصل على التوقع' : 'Get Prediction';
  String get analyzing => _isAr ? 'جاري التحليل...' : 'Analyzing...';
  String get retry => _isAr ? 'إعادة المحاولة' : 'Retry';
  String get insideProtectedZone => _isAr ? 'أنت داخل منطقة محمية' : 'You are inside a protected zone';
  String get factorSeason => _isAr ? 'الموسم' : 'Season';
  String get factorWeather => _isAr ? 'الطقس' : 'Weather';
  String get factorReports => _isAr ? 'التقارير' : 'Reports';
  String get factorProximity => _isAr ? 'القرب' : 'Proximity';
  String get nearbyFishingSpots => _isAr ? 'نقاط صيد قريبة' : 'Nearby Fishing Spots';
  String get kmUnit   => _isAr ? 'كم'           : 'km';
  String get weight        => _isAr ? 'الوزن'                                        : 'Weight';
  String get weightKg     => _isAr ? 'الوزن (كجم)'                                  : 'Weight (kg)';
  String get signInToSell => _isAr ? 'سجّل الدخول لتتبع رحلاتك ومصطاداتك.'         : 'Sign in to track your trips and catches.';
  String get logIn        => _isAr ? 'تسجيل الدخول'                                 : 'Log In';
}
