import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:islam/features/location/data/bd_districts.dart';

class LocationDetectionService {
  LocationDetectionService._();
  static final LocationDetectionService instance = LocationDetectionService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    ),
  );

  /// Attempts to determine the user's location, prioritizing hardware GPS,
  /// then falling back to IP-based geolocation, and finally returning null.
  Future<({String city, String country, String countryCode, double lat, double lng, String timezone})?>
      detectLocation({bool promptGps = true}) async {
    // 1. First Priority: Hardware GPS
    try {
      final gpsResult = await detectGpsLocation(requestPermission: promptGps);
      if (gpsResult != null) {
        return gpsResult;
      }
    } catch (_) {}

    // 2. Second Priority: IP Geolocation (HTTPS)
    try {
      final ipResult = await _detectIpLocation();
      if (ipResult != null) {
        return ipResult;
      }
    } catch (_) {}

    return null;
  }

  /// Directly attempts to read GPS coordinates from the device.
  Future<({String city, String country, String countryCode, double lat, double lng, String timezone})?>
      detectGpsLocation({bool requestPermission = true}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) return null;

      final lat = position.latitude;
      final lng = position.longitude;

      // Check if coordinates are within Bangladesh bounds
      // (approx latitude 20.5 to 26.7, longitude 88.0 to 92.7)
      if (lat >= 20.5 && lat <= 26.7 && lng >= 88.0 && lng <= 92.7) {
        final district = findClosestBdDistrict(lat, lng);
        return (
          city: district.nameEn,
          country: 'Bangladesh',
          countryCode: 'BD',
          lat: lat,
          lng: lng,
          timezone: 'Asia/Dhaka',
        );
      }

      // If outside Bangladesh, resolve timezone and city name via IP or defaults
      return (
        city: 'Local Area',
        country: 'Global',
        countryCode: 'GLOBAL',
        lat: lat,
        lng: lng,
        timezone: DateTime.now().timeZoneName.isNotEmpty
            ? DateTime.now().timeZoneName
            : 'Asia/Dhaka',
      );
    } catch (_) {
      return null;
    }
  }

  Future<({String city, String country, String countryCode, double lat, double lng, String timezone})?>
      _detectIpLocation() async {
    try {
      // Use HTTPS endpoints
      final response = await _dio.get<Map<String, dynamic>>('https://ipapi.co/json/');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final detectedCity = (data['city'] as String?) ?? 'Dhaka';
        final country = (data['country_name'] as String?) ?? 'Bangladesh';
        final countryCode = (data['country_code'] as String?) ?? 'BD';
        var lat = (data['latitude'] as num?)?.toDouble() ?? 23.8103;
        var lon = (data['longitude'] as num?)?.toDouble() ?? 90.4125;
        final timezone = (data['timezone'] as String?) ?? 'Asia/Dhaka';

        if (countryCode == 'BD' || country.toLowerCase() == 'bangladesh') {
          final district = findClosestBdDistrict(lat, lon);
          return (
            city: district.nameEn,
            country: 'Bangladesh',
            countryCode: 'BD',
            lat: lat,
            lng: lon,
            timezone: 'Asia/Dhaka',
          );
        }

        return (
          city: detectedCity,
          country: country,
          countryCode: countryCode,
          lat: lat,
          lng: lon,
          timezone: timezone,
        );
      }
    } catch (_) {}
    return null;
  }
}

