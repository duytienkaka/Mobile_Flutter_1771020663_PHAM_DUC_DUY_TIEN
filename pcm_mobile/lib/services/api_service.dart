import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const baseUrl = 'http://localhost:5096';

  final Dio dio = Dio();
  final storage = const FlutterSecureStorage();

  ApiService() {
    dio.options.baseUrl = baseUrl;
  }

  Future<String> login(String username, String password) async {
    final response = await dio.post(
      '/api/auth/login',
      data: {'UserName': username, 'Password': password},
    );

    final token = response.data['token'];

    setToken(token);

    return token;
  }

  Future<List<dynamic>> getMyBookings(String token) async {
    final response = await dio.get(
      '/api/bookings/my',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> getMe(String token) async {
    final response = await dio.get(
      '/api/members/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<List<dynamic>> getCourts(String token) async {
    final response = await dio.get(
      '/api/courts',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> bookCourt({
    required String token,
    required int courtId,
    required DateTime start,
    required DateTime end,
  }) async {
    final response = await dio.post(
      '/api/bookings',
      data: {
        'courtId': courtId,
        'startTime': start.toIso8601String(),
        'endTime': end.toIso8601String(),
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await dio.get(
      '/api/members/me',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return response.data;
  }

  Future<void> cancelBooking(String token, int bookingId) async {
    await dio.delete(
      '/api/bookings/$bookingId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> topUp(String token, double amount) async {
    await dio.post(
      '/api/wallet/topup',
      data: {'amount': amount},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<List<dynamic>> getCourtReviews(int courtId, String token) async {
    final response = await dio.get(
      '/api/courts/$courtId/reviews',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<void> addCourtReview(
      int courtId, String token, int rating, String comment) async {
    await dio.post(
      '/api/courts/$courtId/reviews',
      data: {'rating': rating, 'comment': comment},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}