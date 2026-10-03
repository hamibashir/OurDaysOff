import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? validationErrors;

  AppException({
    required this.message,
    this.statusCode,
    this.validationErrors,
  });

  @override
  String toString() => message;

  factory AppException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException(
          message: 'Connection timed out. Please check your internet connection.',
          statusCode: error.response?.statusCode,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (statusCode == 429) {
          return AppException(
            message: 'Too many requests. Please wait a moment before trying again.',
            statusCode: 429,
          );
        }

        if (statusCode == 401) {
          return AppException(
            message: 'Session expired or unauthenticated. Please log in again.',
            statusCode: 401,
          );
        }

        if (data is Map<String, dynamic>) {
          final message = data['message'] as String? ?? 'An unexpected error occurred.';
          Map<String, List<String>>? validationErrors;

          if (data['errors'] is Map) {
            final rawErrors = data['errors'] as Map<String, dynamic>;
            validationErrors = rawErrors.map((key, value) {
              if (value is List) {
                return MapEntry(key, value.map((e) => e.toString()).toList());
              }
              return MapEntry(key, [value.toString()]);
            });
          }

          return AppException(
            message: message,
            statusCode: statusCode,
            validationErrors: validationErrors,
          );
        }

        return AppException(
          message: 'Server error (${statusCode ?? "unknown"}). Please try again later.',
          statusCode: statusCode,
        );

      case DioExceptionType.cancel:
        return AppException(message: 'Request was cancelled.');

      case DioExceptionType.connectionError:
        return AppException(
          message: 'Unable to connect to the server. Please check your network or server status.',
        );

      case DioExceptionType.badCertificate:
        return AppException(message: 'Security certificate verification failed.');

      case DioExceptionType.unknown:
      default:
        return AppException(
          message: error.message ?? 'An unexpected network error occurred.',
        );
    }
  }
}
