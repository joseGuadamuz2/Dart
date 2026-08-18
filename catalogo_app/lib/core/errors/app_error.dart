import 'package:dio/dio.dart';

import '../constants/app_strings.dart';

class AppError implements Exception {
  final String message;

  const AppError(this.message);

  factory AppError.from(Object error) {
    if (error is AppError) return error;
    if (error is DioException) {
      final status = error.response?.statusCode;
      switch (status) {
        case 401:
          return const AppError(AppStrings.sessionExpired);
        case 403:
          return const AppError(AppStrings.forbidden);
        case 404:
          return const AppError(AppStrings.notFound);
        case 500:
        case 502:
        case 503:
          return const AppError(AppStrings.serverError);
      }
      switch (error.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return const AppError(AppStrings.connectionError);
        default:
          break;
      }
      final data = error.response?.data;
      if (data is Map && data["message"] != null) {
        return AppError(data["message"].toString());
      }
    }
    return AppError(error.toString().replaceFirst("Exception: ", ""));
  }

  @override
  String toString() => message;
}