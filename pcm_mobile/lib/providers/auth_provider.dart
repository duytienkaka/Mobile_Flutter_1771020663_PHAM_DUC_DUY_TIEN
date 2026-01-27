import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final api = ApiService();
  final storage = const FlutterSecureStorage();

  bool isLoading = false;
  String? token;
  String? fullName;
  int? walletBalance;
  bool initialized = false;

  Future<void> initAuth() async {
    token = await storage.read(key: 'token');

    if (token != null) {
      api.setToken(token!);
    }

    initialized = true;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      token = await api.login(username, password);

      await storage.write(key: 'token', value: token);

      isLoading = false;
      notifyListeners();

      return true;
    } catch (_) {
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'token');
    token = null;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) return;

      final data = await api.getProfile(token);

      fullName = data['fullName'];
      walletBalance = data['walletBalance'];

      notifyListeners();
    } catch (e) {
      debugPrint('Load profile failed: $e');
    }
  }

  Future<void> topUp(double amount) async {
    final token = await storage.read(key: 'token');
    if (token == null) return;

    await api.topUp(token, amount);
    await loadProfile();
  }
}
