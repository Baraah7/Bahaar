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
  String get takePhotoOfFish => _isAr ? 'التقط صورة للأسماك أو الروبيان' : 'Take a photo of fish or shrimp';
  String get systemWillIdentify => _isAr ? 'سيتعرف النظام على النوع تلقائياً' : 'The system will identify the species automatically';
  String get camera => _isAr ? 'الكاميرا' : 'Camera';
  String get gallery => _isAr ? 'المعرض' : 'Gallery';
  String get analyzing => _isAr ? 'جاري التحليل...' : 'Analyzing...';
  String get newImage => _isAr ? 'صورة جديدة' : 'New Image';
  String get supportedSpecies =>
      _isAr ? 'الأنواع المدعومة' : 'Supported Species';
  String get confidence => _isAr ? 'الثقة' : 'Confidence';
  String get tryTakingClearerPhoto => _isAr
      ? 'حاول التقاط صورة أوضح للحصول على نتائج أفضل'
      : 'Try taking a clearer photo for better results';
  String get failedToLoadModel =>
      _isAr ? 'فشل تحميل نموذج التعرف' : 'Failed to load recognition model';
  String get failedToOpenCamera =>
      _isAr ? 'فشل فتح الكاميرا' : 'Failed to open camera';
  String get failedToSelectImage =>
      _isAr ? 'فشل تحديد الصورة' : 'Failed to select image';
  String get modelNotReady => _isAr ? 'النموذج غير جاهز' : 'Model not ready';
  String get classificationFailed =>
      _isAr ? 'فشل التصنيف' : 'Classification failed';
  String get highConfidence => _isAr ? 'ثقة عالية' : 'High Confidence';
  String get lowConfidence => _isAr ? 'ثقة منخفضة' : 'Low Confidence';
  String get unknownFish => _isAr ? 'لا أعرف' : 'I Don\'t Know';
  String get noFishDetected =>
      _isAr ? 'لم يتم اكتشاف سمكة' : 'No fish detected';
  String get unsupportedSpecies =>
      _isAr ? 'نوع غير مدعوم' : 'Unsupported species';
  String get noFishDetectedHint => _isAr
      ? 'لم يكتشف النظام سمكة في هذه الصورة. جرّب صورة أوضح يظهر فيها السمك بالكامل.'
      : 'No fish was detected in this image. Try another photo with the fish clearly visible.';
  String get unsupportedSpeciesHint => _isAr
      ? 'توجد سمكة في الصورة، لكن الثقة ليست كافية لأحد الأنواع المدعومة.'
      : 'A fish was detected, but it does not match a supported species with enough confidence.';
  String get unknownFishHint => _isAr
      ? 'الثقة منخفضة جداً للتعرف على هذه السمكة. حاول التقاط صورة أوضح وأقرب مع إضاءة جيدة.'
      : 'Confidence is too low to identify this fish. Try a closer, well-lit photo with a clear view of the fish.';
  String get reanalyze => _isAr ? 'إعادة التحليل' : 'Reanalyze';
  String get fishInfo => _isAr ? 'معلومات السمكة' : 'Fish Info';
  String get labelHabitat => _isAr ? 'الموطن' : 'Habitat';
  String get labelSize => _isAr ? 'الحجم' : 'Size';
  String get labelSeason => _isAr ? 'أفضل موسم' : 'Best Season';
  String get labelDiet => _isAr ? 'الغذاء' : 'Diet';
  String get labelFlavor => _isAr ? 'المذاق' : 'Flavor';
  String get labelPopularIn => _isAr ? 'شائع في' : 'Popular In';
  String get labelNutrition => _isAr ? 'القيمة الغذائية' : 'Nutrition';

  // ── Catch prediction ─────────────────────────────────────────────────────────
  String get selectLocationFirst =>
      _isAr ? 'يرجى اختيار موقع أولاً' : 'Please select a location first';
  String get unexpectedError =>
      _isAr ? 'حدث خطأ غير متوقع' : 'An unexpected error occurred';
  String get retry => _isAr ? 'إعادة المحاولة' : 'Retry';
  String get probExcellent => _isAr ? 'ممتاز' : 'Excellent';
  String get probVeryGood => _isAr ? 'جيد جداً' : 'Very Good';
  String get probModerate => _isAr ? 'معتدل' : 'Moderate';
  String get probWeak => _isAr ? 'ضعيف' : 'Weak';
  String get probNotSuitable => _isAr ? 'غير مناسب' : 'Not Suitable';
  String get predictionTitle => _isAr ? 'توقع الصيد' : 'Catch Prediction';
  String get location => _isAr ? 'الموقع' : 'Location';
  String get hideMap => _isAr ? 'إخفاء الخريطة' : 'Hide Map';
  String get selectFromMap => _isAr ? 'اختر من الخريطة' : 'Select from Map';
  String get tapMapToSelect => _isAr
      ? 'انقر على الخريطة لتحديد موقع'
      : 'Tap the map to select a location';
  String get chooseSpecies => _isAr ? 'اختر نوع السمكة' : 'Choose Species';
  String get getPrediction => _isAr ? 'احصل على توقع' : 'Get Prediction';
  String get insideProtectedZone =>
      _isAr ? 'داخل منطقة محمية' : 'Inside protected zone';
  String get factorSeason => _isAr ? 'الموسم' : 'Season';
  String get factorWeather => _isAr ? 'الطقس' : 'Weather';
  String get factorReports => _isAr ? 'التقارير' : 'Reports';
  String get factorProximity =>
      _isAr ? 'القرب من المناطق' : 'Proximity to Spots';
  String get nearbyFishingSpots =>
      _isAr ? 'مناطق الصيد القريبة' : 'Nearby Fishing Spots';
  String get kmUnit => _isAr ? 'كم' : 'km';

  // ── Prediction screen ────────────────────────────────────────────────────────
  String get aiPoweredAnalysis =>
      _isAr ? 'تحليل الصيد بالذكاء الاصطناعي' : 'AI-Powered Catch Analysis';
  String get catchProbability =>
      _isAr ? 'احتمالية الصيد' : 'Catch Probability';

  // ── Fish info data ───────────────────────────────────────────────────────────

  static const _fishInfoEn = <String, Map<String, String>>{
    'Gilt-Head Bream': {
      'scientific': 'Sparus aurata',
      'habitat': 'Coastal waters & lagoons',
      'size': '20 – 50 cm',
      'season': 'Spring & Autumn',
      'diet': 'Mollusks, crustaceans, sea urchins',
      'flavor': 'Mild, delicate white flesh',
      'popular_in': 'Arabian Gulf, Mediterranean Sea, Atlantic Coast',
      'nutrition': 'High in protein, omega-3, vitamins B12 & D',
      'fact':
          'Recognisable by the gold stripe between its eyes — hence the name "gilt-head". Highly prized in Bahraini and Gulf fish markets.',
    },
    'Horse Mackerel': {
      'scientific': 'Trachurus trachurus',
      'habitat': 'Open sea & coastal waters',
      'size': '15 – 30 cm',
      'season': 'Summer',
      'diet': 'Small fish, plankton, crustaceans',
      'flavor': 'Firm, slightly oily flesh',
      'popular_in': 'Arabian Sea, Mediterranean Sea, Eastern Atlantic',
      'nutrition': 'Rich in omega-3 fatty acids, selenium & vitamin B12',
      'fact':
          'Travels in large, fast-moving schools near the surface. One of the most commercially important fish species in the world.',
    },
    'Red Mullet': {
      'scientific': 'Mullus surmuletus',
      'habitat': 'Sandy & muddy seabeds',
      'size': '15 – 40 cm',
      'season': 'Spring & Summer',
      'diet': 'Small invertebrates, worms, crustaceans',
      'flavor': 'Rich, delicate flesh',
      'popular_in': 'Arabian Gulf, Mediterranean Sea, Indian Ocean',
      'nutrition': 'Rich in protein, omega-3, vitamins B6 & B12',
      'fact':
          'Red mullet gets its vivid colour from its diet of crustaceans. One of the most prized fish in Gulf markets, traditionally served whole, grilled or fried.',
    },
    'Sea Bass': {
      'scientific': 'Dicentrarchus labrax',
      'habitat': 'Coastal waters & estuaries',
      'size': '30 – 60 cm',
      'season': 'Spring & Summer',
      'diet': 'Fish, crustaceans, cephalopods',
      'flavor': 'Delicate, mild white flesh',
      'popular_in': 'Arabian Gulf, Mediterranean Sea, European coasts',
      'nutrition': 'Excellent source of lean protein, phosphorus & potassium',
      'fact':
          'A prized game fish known for its fighting spirit when caught. Sea bass can live up to 15 years and are highly valued in Gulf seafood cuisine.',
    },
    'Shrimp': {
      'scientific': 'Various species',
      'habitat': 'Shallow coastal waters & seagrass beds',
      'size': '5 – 20 cm',
      'season': 'Year-round',
      'diet': 'Algae, plankton, organic matter',
      'flavor': 'Sweet, tender',
      'popular_in': 'Arabian Gulf, especially Bahrain & Kuwait',
      'nutrition': 'Low in calories, high in iodine, protein & antioxidants',
      'fact':
          'Bahrain has a centuries-old tradition of shrimping. Gulf shrimp (locally known as روبيان) are considered among the finest in the world and are a staple of Bahraini cuisine.',
    },
  };

  static const _fishInfoAr = <String, Map<String, String>>{
    'Gilt-Head Bream': {
      'scientific': 'Sparus aurata',
      'habitat': 'المياه الساحلية والبحيرات',
      'size': '٢٠ – ٥٠ سم',
      'season': 'الربيع والخريف',
      'diet': 'الرخويات والقشريات وقنافذ البحر',
      'flavor': 'لحم أبيض خفيف ولذيذ',
      'popular_in': 'الخليج العربي، البحر الأبيض المتوسط، الساحل الأطلسي',
      'nutrition': 'غني بالبروتين وأوميغا-3 وفيتامين B12 وD',
      'fact':
          'يُميّز بالشريط الذهبي بين عينيه — ومنه جاء اسمه "ذهبي الرأس". يُعدّ من أكثر الأسماك قيمةً في أسواق الأسماك البحرينية والخليجية.',
    },
    'Horse Mackerel': {
      'scientific': 'Trachurus trachurus',
      'habitat': 'أعالي البحار والمياه الساحلية',
      'size': '١٥ – ٣٠ سم',
      'season': 'الصيف',
      'diet': 'الأسماك الصغيرة والعوالق والقشريات',
      'flavor': 'لحم متماسك ودهني قليلاً',
      'popular_in': 'بحر العرب، البحر الأبيض المتوسط، شرق الأطلسي',
      'nutrition': 'غني بأحماض أوميغا-3 والسيلينيوم وفيتامين B12',
      'fact':
          'يتنقل في أسراب كبيرة وسريعة الحركة قرب السطح. يُعدّ من أهم أنواع الأسماك التجارية على مستوى العالم.',
    },
    'Red Mullet': {
      'scientific': 'Mullus barbatus',
      'habitat': 'القيعان الرملية والطينية',
      'size': '١٥ – ٢٥ سم',
      'season': 'طوال العام',
      'diet': 'الديدان والقشريات والرخويات',
      'flavor': 'لحم طري وحلو',
      'popular_in': 'الخليج العربي، البحر الأبيض المتوسط، البحر الأحمر',
      'nutrition': 'غني بالبروتين وأوميغا-3 والسيلينيوم وفيتامين B12',
      'fact':
          'يُعرف بلونه الأحمر المميز والشوارب تحت ذقنه. يُعدّ من الأطباق الفاخرة في المطبخ الخليجي، وغالبًا يُشوى كاملاً.',
    },
    'Sea Bass': {
      'scientific': 'Dicentrarchus labrax',
      'habitat': 'المياه الساحلية والمصبّات',
      'size': '٣٠ – ٦٠ سم',
      'season': 'الربيع والصيف',
      'diet': 'الأسماك والقشريات والرأسقدميات',
      'flavor': 'لحم أبيض طري وخفيف',
      'popular_in': 'الخليج العربي، البحر الأبيض المتوسط، السواحل الأوروبية',
      'nutrition': 'مصدر ممتاز للبروتين الخفيف والفوسفور والبوتاسيوم',
      'fact':
          'سمكة صيد مرغوبة تُعرف بمقاومتها الشديدة عند اصطيادها. يمكن أن تعيش حتى ١٥ عامًا، وتُعدّ من أبرز مأكولات البحر الخليجية.',
    },
    'Shrimp': {
      'scientific': 'أنواع متعددة',
      'habitat': 'المياه الساحلية الضحلة وأحراش الأعشاب البحرية',
      'size': '٥ – ٢٠ سم',
      'season': 'طوال العام',
      'diet': 'الطحالب والعوالق والمواد العضوية',
      'flavor': 'حلو وطري',
      'popular_in': 'الخليج العربي، خاصةً البحرين والكويت',
      'nutrition': 'قليل السعرات، غني باليود والبروتين ومضادات الأكسدة',
      'fact':
          'تمتلك البحرين تقليدًا عريقًا في صيد الروبيان. يُعدّ روبيان الخليج (المعروف محليًا بـ"روبيان") من أجود أنواعه في العالم وركيزة أساسية في المطبخ البحريني.',
    },
  };

  /// Returns locale-appropriate fish info for [className], or null if unknown.
  Map<String, String>? fishInfoFor(String className) =>
      (_isAr ? _fishInfoAr : _fishInfoEn)[className];

  /// Always returns the English scientific name (Latin), regardless of locale.
  static String? scientificNameFor(String className) =>
      _fishInfoEn[className]?['scientific'];
}
