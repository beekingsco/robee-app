import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../theme/robee_theme.dart';

class WeatherChip extends StatefulWidget {
  final double lat;
  final double lng;
  final String tempUnit; // 'F' or 'C'

  const WeatherChip({
    super.key,
    required this.lat,
    required this.lng,
    this.tempUnit = 'F',
  });

  @override
  State<WeatherChip> createState() => _WeatherChipState();
}

class _WeatherChipState extends State<WeatherChip> {
  WeatherData? _weather;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final data = await WeatherService.getWeather(widget.lat, widget.lng);
    if (mounted) {
      setState(() {
        _weather = data;
        _loading = false;
      });
    }
  }

  double _convertTemp(double celsius) {
    if (widget.tempUnit == 'F') return celsius * 9 / 5 + 32;
    return celsius;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: RoBeeTheme.glassWhite5,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RoBeeTheme.glassWhite10),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: RoBeeTheme.glassWhite60,
          ),
        ),
      );
    }

    if (_weather == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: RoBeeTheme.glassWhite5,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RoBeeTheme.glassWhite10),
        ),
        child: const Text('--', style: RoBeeTheme.bodyMedium),
      );
    }

    final temp = _convertTemp(_weather!.temperature);
    final condition = WeatherService.weatherEmoji(
      _weather!.conditionCode,
      _weather!.isDay,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: RoBeeTheme.glassWhite5,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RoBeeTheme.glassWhite10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _weatherIcon(_weather!.conditionCode, _weather!.isDay),
            size: 14,
            color: Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            '${temp.round()}°${widget.tempUnit}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${_weather!.humidity.round()}%',
            style: const TextStyle(
              color: RoBeeTheme.glassWhite60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  IconData _weatherIcon(int code, bool isDay) {
    if (code >= 95) return Icons.thunderstorm_outlined;
    if (code >= 61) return Icons.grain;
    if (code >= 51) return Icons.water_drop_outlined;
    if (code >= 71) return Icons.ac_unit;
    if (code >= 40) return Icons.foggy;
    if (code >= 1) return isDay ? Icons.wb_cloudy_outlined : Icons.nights_stay_outlined;
    return isDay ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined;
  }
}
