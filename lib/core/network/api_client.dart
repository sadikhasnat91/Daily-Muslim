import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:islam/core/network/api_result.dart';

class ApiClient {
  ApiClient({Dio? dio, Connectivity? connectivity, this.maxRetries = 2})
    : _dio = dio ?? Dio(),
      _connectivity = connectivity ?? Connectivity();

  final Dio _dio;
  final Connectivity _connectivity;
  final int maxRetries;

  Future<ApiResult<Map<String, dynamic>>> get(
    String url, {
    Map<String, dynamic>? query,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final connectivity = await _connectivity.checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      return ApiResult.failure('No internet connection');
    }

    Object? lastError;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _dio
            .get<Map<String, dynamic>>(url, queryParameters: query)
            .timeout(timeout);

        final body = response.data;
        if (body == null) {
          return ApiResult.failure('Empty response');
        }

        return ApiResult.success(body);
      } on TimeoutException {
        lastError = 'Request timeout';
      } on DioException catch (e) {
        lastError = e.message ?? 'Network error';
      } catch (e) {
        lastError = e.toString();
      }
    }

    return ApiResult.failure(lastError?.toString() ?? 'Unknown API error');
  }
}
