import 'package:dio/dio.dart';

/// Dio client singleton for making HTTP requests
class DioClient {
  static final DioClient _instance = DioClient._internal();
  static DioClient get instance => _instance;

  late final Dio dio;

  DioClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:3000',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
  }
}