import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_days_off/core/network/error_handler.dart';

void main() {
  group('AppException Tests', () {
    test('AppException parses 429 rate limit correctly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 429,
        ),
        type: DioExceptionType.badResponse,
      );

      final appException = AppException.fromDioException(dioException);
      expect(appException.statusCode, 429);
      expect(appException.message.contains('Too many requests'), isTrue);
    });

    test('AppException parses 401 unauthenticated correctly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      final appException = AppException.fromDioException(dioException);
      expect(appException.statusCode, 401);
      expect(appException.message.contains('Session expired'), isTrue);
    });

    test('AppException parses validation errors map from Laravel', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 422,
          data: {
            'message': 'The given data was invalid.',
            'errors': {
              'email': ['The email field is required.'],
              'password': ['The password must be at least 8 characters.']
            }
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final appException = AppException.fromDioException(dioException);
      expect(appException.statusCode, 422);
      expect(appException.validationErrors?['email']?.first, 'The email field is required.');
      expect(appException.validationErrors?['password']?.first, 'The password must be at least 8 characters.');
    });
  });
}
