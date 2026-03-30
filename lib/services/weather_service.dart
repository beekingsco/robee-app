import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class WeatherData {
  final double temperature;
  final double humidity;
  final int conditionCode;
  final bool isDay;
  final String? sunrise;
  final String? sunset;
  final String timezone;

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.conditionCode,
    required this.isDay,
    this.sunrise,
    this.sunset,
    required this.timezone,
  });
}

class WeatherService {
  static final _log = Logger(printer: SimplePrinter());
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  /// Fetch current weather from Open-Meteo (free, no API key).
  static Future<WeatherData?> getWeather(double lat, double lng) async {
    try {
      final url = 'https://api.open-meteo.com/v1/forecast'
          '?latitude=$lat&longitude=$lng'
          '&current=temperature_2m,relative_humidity_2m,weather_code,is_day'
          '&daily=sunrise,sunset'
          '&timezone=auto'
          '&forecast_days=1';

      final resp = await _dio.get<Map<String, dynamic>>(url);
      final data = resp.data!;

      final current = data['current'] as Map<String, dynamic>;
      final daily = data['daily'] as Map<String, dynamic>?;

      return WeatherData(
        temperature: (current['temperature_2m'] as num).toDouble(),
        humidity: (current['relative_humidity_2m'] as num).toDouble(),
        conditionCode: (current['weather_code'] as num).toInt(),
        isDay: (current['is_day'] as num).toInt() == 1,
        sunrise: (daily?['sunrise'] as List<dynamic>?)?.firstOrNull as String?,
        sunset: (daily?['sunset'] as List<dynamic>?)?.firstOrNull as String?,
        timezone: data['timezone'] as String? ?? 'UTC',
      );
    } catch (e) {
      _log.w('WeatherService.getWeather failed: $e');
      return null;
    }
  }

  /// Returns nectar flow estimate based on current month (northern hemisphere).
  static String getNectarFlow() {
    final month = DateTime.now().month;
    // Peak nectar: April–July
    if (month >= 4 && month <= 7) return 'High';
    // Moderate: March, August–September
    if (month == 3 || month == 8 || month == 9) return 'Moderate';
    // Low: October–February
    return 'Low';
  }

  /// Maps WMO weather code to a descriptive string.
  static String describeCode(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Partly Cloudy';
    if (code <= 49) return 'Foggy';
    if (code <= 69) return 'Rainy';
    if (code <= 79) return 'Snowy';
    if (code <= 99) return 'Stormy';
    return 'Unknown';
  }

  /// Maps WMO code to icon-friendly emoji.
  static String weatherEmoji(int code, bool isDay) {
    if (code == 0) return isDay ? 'Clear' : 'Clear Night';
    if (code <= 3) return isDay ? 'Partly Cloudy' : 'Cloudy';
    if (code <= 49) return 'Foggy';
    if (code <= 69) return 'Rain';
    if (code <= 79) return 'Snow';
    return 'Storm';
  }

  /// Returns true if the weather code represents rain/storm conditions.
  static bool isRainy(int code) => code >= 51 && code <= 99;
  static bool isCloudy(int code) => code >= 1 && code <= 49;
}
