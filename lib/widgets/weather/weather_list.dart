import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/weather/weather_response_model.dart';
import '../../models/weather/hour_model.dart';
import '../../models/weather/forecast_day_model.dart';
import '../../models/weather/tide_model.dart';
import 'package:Bahaar/utilities/cn/celestial_calculator.dart';
import '../../l10n/app_localizations.dart';
import 'celestial_almanac_card.dart';

// Reusable styles and colors
class _WeatherStyles {
  static const Color accent = Color(0xFF4FC3F7);
  static const Color orange = Color(0xFFFFB74D);
  static const Color coral = Color(0xFFFF8A65);

  static Color white(double alpha) => Colors.white.withValues(alpha: alpha);

  static BoxDecoration cardDecoration({double radius = 24}) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [white(0.15), white(0.05)],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: white(0.2)),
  );

  static TextStyle labelStyle = TextStyle(color: white(0.7), fontSize: 13, fontWeight: FontWeight.w500);
  static const TextStyle valueStyle = TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w400);
}

class WeatherList extends StatelessWidget {
  final weather_response_model weatherData;
  final List<TideEntry> tides;
  final AppLocalizations l10n;

  const WeatherList({super.key, required this.weatherData, required this.l10n, this.tides = const []});

  /// Arabic translations for common Bahraini city/area names returned by WeatherAPI.
  static const Map<String, String> _cityArabic = {
    'manama': 'المنامة',
    'muharraq': 'المحرق',
    'riffa': 'الرفاع',
    'isa town': 'مدينة عيسى',
    'hamad town': 'مدينة حمد',
    'sitra': 'سترة',
    'budaiya': 'البديع',
    'jidhafs': 'جدحفص',
    'jidd hafs': 'جدحفص',
    'hidd': 'الحد',
    'tubli': 'توبلي',
    'sanabis': 'السنابس',
    'janabiyah': 'الجنبية',
    'aali': 'عالي',
    'zallaq': 'الزلاق',
    'nuwaidrat': 'نويدرات',
    'diraz': 'دراز',
    'barbar': 'بربار',
    'bilad al qadeem': 'بلاد القديم',
    'sar': 'سار',
    'bani jamra': 'بني جمرة',
    'karbabad': 'كرباباد',
    'malkiya': 'المالكية',
    'jasra': 'الجسرة',
    'shahrakan': 'شهركان',
    'al malikiyah': 'المالكية',
    'bahrain': 'البحرين',
    'east riffa': 'الرفاع الشرقي',
    'west riffa': 'الرفاع الغربي',
    'northern city': 'المدينة الشمالية',
    'southern city': 'المدينة الجنوبية',
    'manamah': 'المنامة',
    'al muharraq': 'المحرق',
    'al hidd': 'الحد',
    'al janabiyah': 'الجنبية',
    'al budaiya': 'البديع',
    'al sitra': 'سترة',
    'al aali': 'عالي',
    'qudaibiya': 'قضيبية',
    'adliya': 'العدلية',
    'hoora': 'الحورة',
    'um al hassam': 'أم الحصم',
    'mahooz': 'المحوز',
    'segaya': 'سيجيئة',
  };

  /// Arabic translations for WeatherAPI condition text strings.
  static const Map<String, String> _conditionArabic = {
    'sunny': 'مشمس',
    'clear': 'صافٍ',
    'partly cloudy': 'غائم جزئياً',
    'cloudy': 'غائم',
    'overcast': 'ملبد بالغيوم',
    'mist': 'ضباب خفيف',
    'fog': 'ضباب',
    'freezing fog': 'ضباب متجمد',
    'haze': 'ضباب دخاني',
    'dust': 'غبار',
    'sand': 'رمال',
    'dust whirls': 'أعمدة غبار',
    'blowing dust': 'عواصف غبارية',
    'blowing sand': 'عواصف رملية',
    'sandstorm': 'عاصفة رملية',
    'dust storm': 'عاصفة ترابية',
    'patchy rain possible': 'أمطار متفرقة محتملة',
    'patchy snow possible': 'ثلوج متفرقة محتملة',
    'patchy sleet possible': 'زخات صقيع متفرقة',
    'patchy freezing drizzle possible': 'رذاذ متجمد متفرق',
    'thundery outbreaks possible': 'عواصف رعدية محتملة',
    'blowing snow': 'عواصف ثلجية',
    'blizzard': 'عاصفة ثلجية شديدة',
    'patchy light drizzle': 'رذاذ خفيف متفرق',
    'light drizzle': 'رذاذ خفيف',
    'freezing drizzle': 'رذاذ متجمد',
    'heavy freezing drizzle': 'رذاذ متجمد كثيف',
    'patchy light rain': 'أمطار خفيفة متفرقة',
    'light rain': 'أمطار خفيفة',
    'moderate rain at times': 'أمطار معتدلة أحياناً',
    'moderate rain': 'أمطار معتدلة',
    'heavy rain at times': 'أمطار غزيرة أحياناً',
    'heavy rain': 'أمطار غزيرة',
    'light freezing rain': 'مطر متجمد خفيف',
    'moderate or heavy freezing rain': 'مطر متجمد معتدل أو غزير',
    'light sleet': 'صقيع خفيف',
    'moderate or heavy sleet': 'صقيع معتدل أو غزير',
    'patchy light snow': 'ثلج خفيف متفرق',
    'light snow': 'ثلج خفيف',
    'patchy moderate snow': 'ثلج معتدل متفرق',
    'moderate snow': 'ثلج معتدل',
    'patchy heavy snow': 'ثلج كثيف متفرق',
    'heavy snow': 'ثلج كثيف',
    'ice pellets': 'حبات صقيع',
    'light rain shower': 'زخة مطر خفيفة',
    'moderate or heavy rain shower': 'زخة مطر معتدلة أو غزيرة',
    'torrential rain shower': 'زخة مطر غزيرة جداً',
    'light snow showers': 'زخات ثلج خفيفة',
    'moderate or heavy snow showers': 'زخات ثلج معتدلة أو غزيرة',
    'patchy light rain with thunder': 'أمطار خفيفة مع رعد',
    'moderate or heavy rain with thunder': 'أمطار معتدلة أو غزيرة مع رعد',
    'patchy light snow with thunder': 'ثلج خفيف مع رعد',
    'moderate or heavy snow with thunder': 'ثلج معتدل أو غزير مع رعد',
    'thunderstorm': 'عاصفة رعدية',
    'light thunderstorm': 'عاصفة رعدية خفيفة',
    'heavy thunderstorm': 'عاصفة رعدية شديدة',
  };

  /// Arabic translations for moon phase strings from WeatherAPI.
  static const Map<String, String> _moonPhaseArabic = {
    'new moon': 'محاق',
    'waxing crescent': 'هلال متصاعد',
    'first quarter': 'تربيع أول',
    'waxing gibbous': 'أحدب متصاعد',
    'full moon': 'بدر',
    'waning gibbous': 'أحدب متناقص',
    'last quarter': 'تربيع أخير',
    'waning crescent': 'هلال متناقص',
  };

  /// Returns city name translated to Arabic when locale is Arabic.
  String _cityName(String name) {
    if (l10n.localeName != 'ar') return name;
    return _cityArabic[name.toLowerCase()] ?? name;
  }

  /// Converts ASCII digits to Arabic-Indic numerals when locale is Arabic.
  String _n(dynamic value) {
    final str = value.toString();
    if (l10n.localeName != 'ar') return str;
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return str.replaceAllMapped(
      RegExp(r'[0-9]'),
      (m) => digits[int.parse(m.group(0)!)],
    );
  }

  /// Translates WeatherAPI condition text when locale is Arabic.
  String _conditionText(String text) {
    if (l10n.localeName != 'ar') return text;
    return _conditionArabic[text.toLowerCase()] ?? text;
  }

  /// Translates moon phase text when locale is Arabic.
  String _moonPhase(String phase) {
    if (l10n.localeName != 'ar') return phase;
    return _moonPhaseArabic[phase.toLowerCase()] ?? phase;
  }

  /// Converts "06:30 AM" / "07:15 PM" to Arabic format when locale is Arabic.
  String _formatTime(String time) {
    if (l10n.localeName != 'ar') return time;
    final t = time.toUpperCase()
        .replaceAll(' AM', ' ص')
        .replaceAll(' PM', ' م');
    return _n(t);
  }

  /// Returns localized km/h unit string.
  String get _kmh => l10n.localeName == 'ar' ? 'كم/س' : 'km/h';

  /// Returns localized km unit string.
  String get _km => l10n.localeName == 'ar' ? 'كم' : 'km';

  // Reusable weather icon widget
  Widget _weatherIcon(String iconUrl, {double size = 32}) {
    return Image.network(
      'https:$iconUrl',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => Icon(
        Icons.cloud,
        color: _WeatherStyles.white(0.7),
        size: size,
      ),
    );
  }

  // Reusable section header with accent bar
  Widget _sectionHeader(String title, Color accentColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Reusable gradient divider
  Widget _gradientDivider({bool vertical = false}) {
    return Container(
      width: vertical ? 1 : null,
      height: vertical ? 50 : 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            _WeatherStyles.white(0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildUniqueHeader(),
          _buildHourlyForecast(),
          const SizedBox(height: 20),
          _buildDailyForecast(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildWindDetailCard(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildCompactCard(
                      icon: Icons.wb_sunny_outlined,
                      title: l10n.uvIndex,
                      value: _n(weatherData.currentWeather.uv.round()),
                      subtitle: _getUVLevel(weatherData.currentWeather.uv),
                      accentColor: _getUVColor(weatherData.currentWeather.uv),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCompactCard(
                      icon: Icons.thermostat_outlined,
                      title: l10n.feelsLike,
                      value: '${_n(weatherData.currentWeather.feelslike_c.round())}°',
                      subtitle: _getFeelsLikeDescription(),
                      accentColor: const Color(0xFF64B5F6),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildCompactCard(
                      icon: Icons.water_drop,
                      title: l10n.humidity,
                      value: '${_n(weatherData.currentWeather.humidity)}%',
                      subtitle: '${l10n.weatherDewPoint} ${_n(weatherData.currentWeather.dewpoint_c.round())}°',
                      accentColor: _WeatherStyles.accent,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCompactCard(
                      icon: Icons.visibility_outlined,
                      title: l10n.visibility,
                      value: '${_n(weatherData.currentWeather.vis_km.round())} $_km',
                      subtitle: _getVisibilityDescription(),
                      accentColor: const Color(0xFF81C784),
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSunMoonCard(),
                const SizedBox(height: 16),
                _buildTidesCard(),
                const SizedBox(height: 16),
                _buildCelestialAlmanac(),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUniqueHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        children: [
          // Location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _WeatherStyles.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _WeatherStyles.accent.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _cityName(weatherData.location.name).toUpperCase(),
                style: TextStyle(
                  color: _WeatherStyles.white(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Temperature circle
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _WeatherStyles.white(0.1), width: 2),
                ),
              ),
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_WeatherStyles.white(0.1), Colors.transparent],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _n(weatherData.currentWeather.temp_c.round()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '°C',
                      style: TextStyle(
                        color: _WeatherStyles.white(0.7),
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Condition pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _WeatherStyles.white(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _WeatherStyles.white(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _weatherIcon(weatherData.currentWeather.condition.icon, size: 28),
                const SizedBox(width: 8),
                Text(
                  _conditionText(weatherData.currentWeather.condition.text),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // High/Low
          if (weatherData.forecast != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _tempIndicator(weatherData.forecast!.forecastDay.day.maxtemp_c.round(), Icons.arrow_upward, _WeatherStyles.orange),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(width: 40, height: 2, child: _gradientDivider()),
                ),
                _tempIndicator(weatherData.forecast!.forecastDay.day.mintemp_c.round(), Icons.arrow_downward, const Color(0xFF64B5F6)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _tempIndicator(int temp, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text('${_n(temp)}°', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    if (weatherData.forecast == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final hours = weatherData.forecast!.forecastday
        .expand((day) => day.hour)
        .where((h) => DateTime.parse(h.time).isAfter(now.subtract(const Duration(hours: 1))))
        .take(24)
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _WeatherStyles.cardDecoration(),
      child: Column(
        children: [
          _sectionHeader(l10n.hourlyForecast, _WeatherStyles.accent),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: hours.length,
              itemBuilder: (context, index) => _hourItem(hours[index], index == 0),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _hourItem(hour_model hour, bool isNow) {
    final hourTime = DateTime.parse(hour.time);
    return Container(
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isNow ? BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_WeatherStyles.accent.withValues(alpha: 0.3), _WeatherStyles.accent.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _WeatherStyles.accent.withValues(alpha: 0.5)),
      ) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isNow ? l10n.weatherNow : _n('${hourTime.hour}:00'),
            style: TextStyle(
              color: isNow ? _WeatherStyles.accent : _WeatherStyles.white(0.8),
              fontSize: 14,
              fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          _weatherIcon(hour.condition_icon, size: 36),
          Text(
            '${_n(hour.temp_c.round())}°',
            style: TextStyle(
              color: isNow ? Colors.white : _WeatherStyles.white(0.9),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyForecast() {
    if (weatherData.forecast == null) return const SizedBox.shrink();

    final days = weatherData.forecast!.forecastday;
    final weekMin = days.map((d) => d.day.mintemp_c).reduce(math.min);
    final weekMax = days.map((d) => d.day.maxtemp_c).reduce(math.max);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _WeatherStyles.cardDecoration(),
      child: Column(
        children: [
          _sectionHeader('${_n(days.length)}-${l10n.dailyForecast}', _WeatherStyles.orange),
          ...days.asMap().entries.map((e) => _dayRow(e.value, e.key == 0, weekMin, weekMax)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _dayRow(forecast_day day, bool isToday, double weekMin, double weekMax) {
    final date = DateTime.parse(day.date);
    final dayName = isToday ? l10n.weatherToday : _getDayName(date.weekday);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: isToday ? BoxDecoration(color: _WeatherStyles.white(0.08)) : null,
      child: Row(
        children: [
          SizedBox(
            width: 55,
            child: Text(
              dayName,
              style: TextStyle(
                color: isToday ? Colors.white : _WeatherStyles.white(0.8),
                fontSize: 15,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          _weatherIcon(day.day.condition_icon),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            child: day.day.daily_chance_of_rain > 0
                ? Row(
                    children: [
                      const Icon(Icons.water_drop, color: _WeatherStyles.accent, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '${_n(day.day.daily_chance_of_rain)}%',
                        style: const TextStyle(color: _WeatherStyles.accent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                : null,
          ),
          const Spacer(),
          Text('${_n(day.day.mintemp_c.round())}°', style: TextStyle(color: _WeatherStyles.white(0.5), fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          SizedBox(width: 80, child: _temperatureBar(day.day.mintemp_c, day.day.maxtemp_c, weekMin, weekMax, isToday)),
          const SizedBox(width: 8),
          Text('${_n(day.day.maxtemp_c.round())}°', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _temperatureBar(double min, double max, double weekMin, double weekMax, bool isToday) {
    final range = weekMax - weekMin;
    final startPercent = (min - weekMin) / range;
    final endPercent = (max - weekMin) / range;
    final currentPercent = isToday ? (weatherData.currentWeather.temp_c - weekMin) / range : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: _WeatherStyles.white(0.15),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Stack(
            children: [
              Positioned(
                left: constraints.maxWidth * startPercent,
                right: constraints.maxWidth * (1 - endPercent),
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF64B5F6), _WeatherStyles.orange, _WeatherStyles.coral]),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (currentPercent != null)
                Positioned(
                  left: (constraints.maxWidth * currentPercent - 5).clamp(0, constraints.maxWidth - 10),
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWindDetailCard() {
    final wind = weatherData.currentWeather;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _WeatherStyles.cardDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(painter: _ModernCompassPainter(wind.wind_degree.toDouble())),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.air, color: _WeatherStyles.white(0.7), size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.wind, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_n(wind.wind_kph.round()), style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w300, height: 1)),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(_kmh, style: TextStyle(color: _WeatherStyles.white(0.7), fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _WeatherStyles.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(wind.wind_dir, style: const TextStyle(color: _WeatherStyles.accent, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.waves, color: _WeatherStyles.white(0.5), size: 14),
                    const SizedBox(width: 6),
                    Text('${l10n.weatherGusts} ${_n(wind.gust_kph.round())} $_kmh', style: TextStyle(color: _WeatherStyles.white(0.6), fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 130,
      decoration: _WeatherStyles.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 6),
              Text(title, style: _WeatherStyles.labelStyle),
            ],
          ),
          const Spacer(),
          Text(value, style: _WeatherStyles.valueStyle),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: _WeatherStyles.white(0.6), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildSunMoonCard() {
    if (weatherData.forecast == null) return const SizedBox.shrink();

    final astro = weatherData.forecast!.forecastDay.astro;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _WeatherStyles.cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _celestialInfo(Icons.wb_sunny, _WeatherStyles.orange, l10n.sunrise, _formatTime(astro.sunrise))),
              _gradientDivider(vertical: true),
              Expanded(child: _celestialInfo(Icons.wb_twilight, _WeatherStyles.coral, l10n.sunset, _formatTime(astro.sunset))),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _gradientDivider(),
          ),
          Row(
            children: [
              Icon(_getMoonIcon(astro.moon_phase), color: _WeatherStyles.white(0.9), size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_moonPhase(astro.moon_phase), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                    Text('${_n(astro.moon_illumination)}${l10n.illuminated}', style: TextStyle(color: _WeatherStyles.white(0.6), fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _moonTime(Icons.arrow_upward, _formatTime(astro.moonrise)),
                  const SizedBox(height: 4),
                  _moonTime(Icons.arrow_downward, _formatTime(astro.moonset)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _celestialInfo(IconData icon, Color color, String title, String time) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: _WeatherStyles.white(0.6), fontSize: 13)),
        const SizedBox(height: 4),
        Text(time, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _moonTime(IconData icon, String time) {
    return Row(
      children: [
        Icon(icon, color: _WeatherStyles.white(0.5), size: 12),
        const SizedBox(width: 4),
        Text(time, style: TextStyle(color: _WeatherStyles.white(0.7), fontSize: 13)),
      ],
    );
  }

  IconData _getMoonIcon(String phase) {
    return switch (phase.toLowerCase()) {
      'new moon' => Icons.brightness_1_outlined,
      'full moon' => Icons.brightness_1,
      'first quarter' => Icons.brightness_2,
      'last quarter' => Icons.brightness_3,
      _ => Icons.nightlight_round,
    };
  }

  Widget _buildCelestialAlmanac() {
    final now = DateTime.now();
    final lat = weatherData.location.lat;
    final lon = weatherData.location.lon;
    final solar = CelestialCalculator.calculateSolarDay(lat, lon, now);
    final lunar = CelestialCalculator.calculateLunarDay(lat, lon, now);
    return CelestialAlmanacCard(solar: solar, lunar: lunar);
  }

  Widget _buildTidesCard() {
    const tideBlue = Color(0xFF4FC3F7);
    const tideLow = Color(0xFF81D4FA);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _WeatherStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(l10n.weatherTodayTides, tideBlue),
          const SizedBox(height: 4),
          if (tides.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.waves, color: _WeatherStyles.white(0.4), size: 28),
                  const SizedBox(width: 12),
                  Text(
                    l10n.weatherTideUnavailable,
                    style: TextStyle(color: _WeatherStyles.white(0.5), fontSize: 15),
                  ),
                ],
              ),
            )
          else
            ...tides.map((entry) {
              final isHigh = entry.isHigh;
              final color = isHigh ? tideBlue : tideLow;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isHigh ? Icons.arrow_upward : Icons.arrow_downward,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHigh ? l10n.weatherHighTide : l10n.weatherLowTide,
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          entry.formattedTime,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${_n(entry.heightMt.toStringAsFixed(2))} m',
                      style: TextStyle(
                        color: _WeatherStyles.white(0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    return [
      '',
      l10n.dayMon,
      l10n.dayTue,
      l10n.dayWed,
      l10n.dayThu,
      l10n.dayFri,
      l10n.daySat,
      l10n.daySun,
    ][weekday];
  }

  String _getUVLevel(double uv) {
    if (uv <= 2) return l10n.uvLow;
    if (uv <= 5) return l10n.uvModerate;
    if (uv <= 7) return l10n.uvHigh;
    if (uv <= 10) return l10n.uvVeryHigh;
    return l10n.uvExtreme;
  }

  Color _getUVColor(double uv) {
    if (uv <= 2) return const Color(0xFF81C784);
    if (uv <= 5) return _WeatherStyles.orange;
    if (uv <= 7) return _WeatherStyles.coral;
    if (uv <= 10) return const Color(0xFFE57373);
    return const Color(0xFFBA68C8);
  }

  String _getFeelsLikeDescription() {
    final diff = weatherData.currentWeather.feelslike_c - weatherData.currentWeather.temp_c;
    if (diff.abs() < 2) return l10n.feelsLikeSimilar;
    return diff > 0 ? l10n.feelsLikeWarmer : l10n.feelsLikeCooler;
  }

  String _getVisibilityDescription() {
    final vis = weatherData.currentWeather.vis_km;
    if (vis >= 10) return l10n.visibilityClear;
    if (vis >= 5) return l10n.visibilityGood;
    if (vis >= 2) return l10n.uvModerate;
    return l10n.visibilityLow;
  }
}

class _ModernCompassPainter extends CustomPainter {
  final double windDegree;
  _ModernCompassPainter(this.windDegree);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Outer ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _WeatherStyles.white(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Decorative dots
    final dotPaint = Paint()..color = _WeatherStyles.white(0.4)..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45 - 90) * math.pi / 180;
      canvas.drawCircle(
        Offset(center.dx + (radius - 8) * math.cos(angle), center.dy + (radius - 8) * math.sin(angle)),
        i % 2 == 0 ? 3.0 : 2.0,
        dotPaint,
      );
    }

    // Direction arrow
    final angle = (windDegree - 90) * math.pi / 180;
    final arrowLength = radius - 16;
    final path = Path()
      ..moveTo(center.dx + arrowLength * math.cos(angle), center.dy + arrowLength * math.sin(angle))
      ..lineTo(center.dx + 10 * math.cos(angle + math.pi - 0.5), center.dy + 10 * math.sin(angle + math.pi - 0.5))
      ..lineTo(center.dx + 10 * math.cos(angle + math.pi + 0.5), center.dy + 10 * math.sin(angle + math.pi + 0.5))
      ..close();
    canvas.drawPath(path, Paint()..color = _WeatherStyles.accent);

    // Center dot
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);

    // N indicator
    final textPainter = TextPainter(
      text: const TextSpan(text: 'N', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, 6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
