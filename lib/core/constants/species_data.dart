// lib/core/constants/species_data.dart
// Hardcoded catalogue of the 8 target species for Bahraini waters.

const List<Map<String, dynamic>> kAllSpecies = [
  {
    'id': 'hamour',
    'nameAr': 'هامور',
    'nameEn': 'Grouper',
    'scientific': 'Epinephelus coioides',
    'peakMonths': [10, 11, 12, 1, 2],
    'depthRange': '3-50m',
    'bottomTypes': ['rocky', 'reef', 'coral'],
    'methods': ['gargoor', 'hook_line'],
    'advice': 'يتواجد قرب الشعاب المرجانية، ينشط صباحاً وغروباً',
  },
  {
    'id': 'rubyan',
    'nameAr': 'ربيان',
    'nameEn': 'Shrimp',
    'scientific': 'Penaeus semisulcatus',
    'peakMonths': [3, 4, 5, 6, 7, 8, 9],
    'depthRange': '2-20m',
    'bottomTypes': ['sandy', 'muddy', 'seagrass'],
    'methods': ['trawl', 'haddrah'],
    'advice': 'يفضل المناطق الرملية والطينية، أفضل وقت الليل',
  },
  {
    'id': 'kanad',
    'nameAr': 'كنعد',
    'nameEn': 'Spanish Mackerel',
    'scientific': 'Scomberomorus commerson',
    'peakMonths': [10, 11, 12, 1, 2, 3],
    'depthRange': '5-30m',
    'bottomTypes': ['open_water', 'reef_edge'],
    'methods': ['trolling', 'gillnet'],
    'advice': 'يصطاد بالسحب، ينشط في الأعماق المفتوحة',
  },
  {
    'id': 'safi',
    'nameAr': 'صافي',
    'nameEn': 'Rabbitfish',
    'scientific': 'Siganus canaliculatus',
    'peakMonths': [5, 6, 7, 8],
    'depthRange': '1-15m',
    'bottomTypes': ['seagrass', 'sandy', 'reef'],
    'methods': ['gillnet', 'gargoor', 'hook_line'],
    'advice': 'يتواجد قرب الأعشاب البحرية',
  },
  {
    'id': 'ghabgab',
    'nameAr': 'غبغب',
    'nameEn': 'Blue Crab',
    'scientific': 'Portunus pelagicus',
    'peakMonths': [5, 6, 7, 8, 9],
    'depthRange': '1-25m',
    'bottomTypes': ['muddy', 'sandy', 'seagrass'],
    'methods': ['gargoor', 'trawl', 'haddrah'],
    'advice': 'يُصطاد بالقراقير والحظرة',
  },
  {
    'id': 'sheri',
    'nameAr': 'شعري',
    'nameEn': 'Emperor Fish',
    'scientific': 'Lethrinus nebulosus',
    'peakMonths': [9, 10, 11],
    'depthRange': '5-40m',
    'bottomTypes': ['sandy', 'reef', 'seagrass'],
    'methods': ['gargoor', 'hook_line'],
    'advice': 'ينشط في الخريف، يفضل الأعماق المتوسطة',
  },
  {
    'id': 'sheum',
    'nameAr': 'شعوم',
    'nameEn': 'Bream',
    'scientific': 'Acanthopagrus bifasciatus',
    'peakMonths': [6, 7, 8, 9],
    'depthRange': '2-30m',
    'bottomTypes': ['sandy', 'rocky', 'seagrass'],
    'methods': ['gargoor', 'hook_line', 'gillnet'],
    'advice': 'متوفر طوال العام، ينشط في الصيف',
  },
  {
    'id': 'zebaidi',
    'nameAr': 'زبيدي',
    'nameEn': 'Silver Pomfret',
    'scientific': 'Pampus argenteus',
    'peakMonths': [11, 12, 1, 2, 3],
    'depthRange': '5-60m',
    'bottomTypes': ['muddy', 'sandy'],
    'methods': ['gillnet', 'trawl'],
    'advice': 'يُصطاد بالشباك، موسمه الشتاء',
  },
];

/// Arabic display names for fishing methods.
const Map<String, String> kMethodNamesAr = {
  'gargoor': 'قراقير',
  'hook_line': 'خيوط',
  'trawl': 'شباك جر',
  'gillnet': 'شبكة',
  'trolling': 'سحب',
  'haddrah': 'حظرة',
};

/// Arabic display names for bottom types.
const Map<String, String> kBottomTypeNamesAr = {
  'rocky': 'صخري',
  'reef': 'شعاب',
  'coral': 'مرجاني',
  'coral_reef': 'شعاب مرجانية',
  'sandy': 'رملي',
  'muddy': 'طيني',
  'seagrass': 'أعشاب بحرية',
  'open_water': 'مياه مفتوحة',
  'reef_edge': 'حافة الشعاب',
  'sandy_rocky': 'رملي صخري',
  'sandy_reef': 'رملي مرجاني',
  'rocky_reef': 'صخري مرجاني',
  'seagrass_sandy': 'أعشاب رملية',
};

/// Arabic month names.
const List<String> kMonthNamesAr = [
  'يناير', 'فبراير', 'مارس', 'أبريل',
  'مايو', 'يونيو', 'يوليو', 'أغسطس',
  'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];
