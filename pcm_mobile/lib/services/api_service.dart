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

  Future<void> register(String username, String password, String fullName) async {
    await dio.post(
      '/api/auth/register',
      data: {
        'UserName': username,
        'Password': password,
        'FullName': fullName,
      },
    );
  }

  Future<void> changePassword(String token, String currentPassword, String newPassword) async {
    await dio.put(
      '/api/auth/change-password',
      data: {
        'CurrentPassword': currentPassword,
        'NewPassword': newPassword,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
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

  Future<Map<String, dynamic>> createGroupBooking({
    required String token,
    required int courtId,
    required DateTime start,
    required DateTime end,
    required List<String> invitedUserNames,
  }) async {
    final response = await dio.post(
      '/api/bookings/group',
      data: {
        'courtId': courtId,
        'startTime': start.toIso8601String(),
        'endTime': end.toIso8601String(),
        'invitedUserNames': invitedUserNames,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> payGroupShare(String token, int groupId) async {
    final response = await dio.post(
      '/api/bookings/group/$groupId/pay',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<List<dynamic>> getMyGroupBookings(String token) async {
    final response = await dio.get(
      '/api/bookings/group/my',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> createTournament({
    required String token,
    required String name,
    required String sport,
    required DateTime startDate,
    DateTime? endDate,
    required double entryFee,
    required int maxTeams,
  }) async {
    final response = await dio.post(
      '/api/tournaments',
      data: {
        'name': name,
        'sport': sport,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'entryFee': entryFee,
        'maxTeams': maxTeams,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<List<dynamic>> getTournaments(String token) async {
    final response = await dio.get(
      '/api/tournaments',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> registerForTournament({
    required String token,
    required int tournamentId,
    required String teamName,
  }) async {
    final response = await dio.post(
      '/api/tournaments/$tournamentId/register',
      data: {'teamName': teamName},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> getTournamentDetails(int tournamentId, String token) async {
    final response = await dio.get(
      '/api/tournaments/$tournamentId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  // Admin APIs
  Future<List<dynamic>> getAdminUsers(String token) async {
    final response = await dio.get(
      '/api/admin/users',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<void> updateUserRole(String token, int userId, String role) async {
    await dio.put(
      '/api/admin/users/$userId/role',
      data: role,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> deleteUser(String token, int userId) async {
    await dio.delete(
      '/api/admin/users/$userId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<List<dynamic>> getAdminCourts(String token) async {
    final response = await dio.get(
      '/api/admin/courts',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<void> updateCourt(String token, int courtId, Map<String, dynamic> court) async {
    await dio.put(
      '/api/admin/courts/$courtId',
      data: court,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> deleteCourt(String token, int courtId) async {
    await dio.delete(
      '/api/admin/courts/$courtId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<List<dynamic>> getAdminBookings(String token) async {
    final response = await dio.get(
      '/api/admin/bookings',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<void> deleteBookingAdmin(String token, int bookingId) async {
    await dio.delete(
      '/api/admin/bookings/$bookingId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<List<dynamic>> getAdminTournaments(String token) async {
    final response = await dio.get(
      '/api/admin/tournaments',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<void> deleteTournamentAdmin(String token, int tournamentId) async {
    await dio.delete(
      '/api/admin/tournaments/$tournamentId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<List<dynamic>> getAdminTopUpRequests(String token) async {
    final response = await dio.get(
      '/api/admin/topup-requests',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<void> createCourtAdmin(String token, Map<String, dynamic> court) async {
    await dio.post(
      '/api/admin/courts',
      data: court,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> createTournamentAdmin(String token, Map<String, dynamic> tournament) async {
    await dio.post(
      '/api/admin/tournaments',
      data: tournament,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}