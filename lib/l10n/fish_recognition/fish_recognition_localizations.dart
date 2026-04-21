import 'package:flutter/material.dart';

class FishRecognitionLocalizations {
  const FishRecognitionLocalizations._(this._locale);
  final Locale _locale;
  bool get _isAr => _locale.languageCode == 'ar';

  static FishRecognitionLocalizations of(BuildContext context) =>
      FishRecognitionLocalizations._(Localizations.localeOf(context));

  String get localeName => _locale.languageCode;

  String get tryAgain => _isAr ? 'حاول مرة أخرى' : 'Try Again';
  String get noDataAvailable => _isAr ? 'لا توجد بيانات' : 'No data available';
  String get fishRecognition => _isAr ? 'التعرف على الأسماك' : 'Fish Recognition';
  String get loadingRecognitionModel => _isAr ? 'جاري تحميل نموذج التعرف...' : 'Loading recognition model...';
  String get takePhotoOfFish => _isAr ? 'التقط صورة للأسماك أو الجمبري' : 'Take a photo of fish or shrimp';
  String get systemWillIdentify => _isAr ? 'سيتعرف النظام على النوع تلقائياً' : 'The system will identify the species automatically';
  String get camera => _isAr ? 'الكاميرا' : 'Camera';
  String get gallery => _isAr ? 'المعرض' : 'Gallery';
  String get analyzing => _isAr ? 'جاري التحليل...' : 'Analyzing...';
  String get newImage => _isAr ? 'صورة جديدة' : 'New Image';
  String get supportedSpecies => _isAr ? 'الأنواع المدعومة' : 'Supported Species';
  String get confidence => _isAr ? 'الثقة' : 'Confidence';
  String get tryTakingClearerPhoto => _isAr ? 'حاول التقاط صورة أوضح للحصول على نتائج أفضل' : 'Try taking a clearer photo for better results';
  String get failedToLoadModel => _isAr ? 'فشل تحميل نموذج التعرف' : 'Failed to load recognition model';
  String get failedToOpenCamera => _isAr ? 'فشل فتح الكاميرا' : 'Failed to open camera';
  String get failedToSelectImage => _isAr ? 'فشل تحديد الصورة' : 'Failed to select image';
  String get modelNotReady => _isAr ? 'النموذج غير جاهز' : 'Model not ready';
  String get classificationFailed => _isAr ? 'فشل التصنيف' : 'Classification failed';
  String get highConfidence => _isAr ? 'ثقة عالية' : 'High Confidence';
  String get lowConfidence  => _isAr ? 'ثقة منخفضة' : 'Low Confidence';
  String get reanalyze      => _isAr ? 'إعادة التحليل' : 'Reanalyze';
  String get fishInfo       => _isAr ? 'معلومات السمكة' : 'Fish Info';
  String get labelHabitat   => _isAr ? 'الموطن' : 'Habitat';
  String get labelSize      => _isAr ? 'الحجم' : 'Size';
  String get labelSeason    => _isAr ? 'أفضل موسم' : 'Best Season';
  String get labelDiet      => _isAr ? 'الغذاء' : 'Diet';
  String get labelFlavor    => _isAr ? 'المذاق' : 'Flavor';
  String get labelPopularIn => _isAr ? 'شائع في' : 'Popular In';
  String get labelNutrition => _isAr ? 'القيمة الغذائية' : 'Nutrition';

  // ── Catch prediction ─────────────────────────────────────────────────────────
  String get selectLocationFirst => _isAr ? 'يرجى اختيار موقع أولاً'        : 'Please select a location first';
  String get unexpectedError     => _isAr ? 'حدث خطأ غير متوقع'             : 'An unexpected error occurred';
  String get retry               => _isAr ? 'إعادة المحاولة'                : 'Retry';
  String get probExcellent       => _isAr ? 'ممتاز'                          : 'Excellent';
  String get probVeryGood        => _isAr ? 'جيد جداً'                       : 'Very Good';
  String get probModerate        => _isAr ? 'معتدل'                          : 'Moderate';
  String get probWeak            => _isAr ? 'ضعيف'                           : 'Weak';
  String get probNotSuitable     => _isAr ? 'غير مناسب'                     : 'Not Suitable';
  String get predictionTitle     => _isAr ? 'توقع الصيد'                    : 'Catch Prediction';
  String get location            => _isAr ? 'الموقع'                         : 'Location';
  String get hideMap             => _isAr ? 'إخفاء الخريطة'                  : 'Hide Map';
  String get selectFromMap       => _isAr ? 'اختر من الخريطة'                : 'Select from Map';
  String get tapMapToSelect      => _isAr ? 'انقر على الخريطة لتحديد موقع'  : 'Tap the map to select a location';
  String get chooseSpecies       => _isAr ? 'اختر نوع السمكة'                : 'Choose Species';
  String get getPrediction       => _isAr ? 'احصل على توقع'                  : 'Get Prediction';
  String get insideProtectedZone => _isAr ? 'داخل منطقة محمية'               : 'Inside protected zone';
  String get factorSeason        => _isAr ? 'الموسم'                         : 'Season';
  String get factorWeather       => _isAr ? 'الطقس'                          : 'Weather';
  String get factorReports       => _isAr ? 'التقارير'                       : 'Reports';
  String get factorProximity     => _isAr ? 'القرب من المناطق'               : 'Proximity to Spots';
  String get nearbyFishingSpots  => _isAr ? 'مناطق الصيد القريبة'            : 'Nearby Fishing Spots';
  String get kmUnit              => _isAr ? 'كم'                             : 'km';
}
