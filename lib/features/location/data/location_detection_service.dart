import 'package:dio/dio.dart';
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

  /// Attempts to automatically detect the user's city and geographic coordinates
  /// using lightweight IP geolocation.
  Future<({String city, String country, String countryCode, double lat, double lng, String timezone})?>
      detectLocation() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('http://ip-api.com/json');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        if (data['status'] == 'success') {
          final detectedCity = (data['city'] as String?) ?? 'Dhaka';
          final country = (data['country'] as String?) ?? 'Bangladesh';
          final countryCode = (data['countryCode'] as String?) ?? 'BD';
          var lat = (data['lat'] as num?)?.toDouble() ?? 23.8103;
          var lon = (data['lon'] as num?)?.toDouble() ?? 90.4125;
          final timezone = (data['timezone'] as String?) ?? 'Asia/Dhaka';

          // Match to a known BD district if in Bangladesh
          if (countryCode == 'BD' || country.toLowerCase() == 'bangladesh') {
            final district = findBdDistrict(detectedCity) ??
                findBdDistrict(data['regionName'] as String? ?? '');
            if (district != null) {
              lat = district.latitude;
              lon = district.longitude;
              return (
                city: district.nameEn,
                country: 'Bangladesh',
                countryCode: 'BD',
                lat: lat,
                lng: lon,
                timezone: 'Asia/Dhaka',
              );
            }
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
      }
    } catch (_) {}
    return null;
  }
}

