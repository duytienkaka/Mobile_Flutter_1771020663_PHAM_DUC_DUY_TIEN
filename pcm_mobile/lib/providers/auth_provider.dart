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
  String? role;
  bool initialized = false;
  final Set<int> favoriteCourtIds = {};

  Future<void> initAuth() async {
    token = await storage.read(key: 'token');
    await _loadFavorites();

    if (token != null) {
      api.setToken(token!);
      await loadProfile(); // Load profile when token exists
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

      await loadProfile(); // Load profile after login
      await _loadFavorites();

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
    favoriteCourtIds.clear();
    notifyListeners();
  }

  bool isFavoriteCourt(int courtId) => favoriteCourtIds.contains(courtId);

  Future<void> toggleFavoriteCourt(int courtId) async {
    if (favoriteCourtIds.contains(courtId)) {
      favoriteCourtIds.remove(courtId);
    } else {
      favoriteCourtIds.add(courtId);
    }
    await storage.write(key: 'favorite_courts', value: favoriteCourtIds.join(','));
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    final raw = await storage.read(key: 'favorite_courts');
    favoriteCourtIds.clear();
    if (raw != null && raw.isNotEmpty) {
      for (final part in raw.split(',')) {
        final id = int.tryParse(part.trim());
        if (id != null) favoriteCourtIds.add(id);
      }
    }
  }

  Future<void> loadProfile() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) return;

      final data = await api.getProfile(token);

      debugPrint('Profile data: $data'); // Debug print

      fullName = data['fullName'];
      walletBalance = (data['walletBalance'] as double?)?.toInt();
      role = data['role'];

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

  Future<void> requestTopUp(double amount) async {
    final token = await storage.read(key: 'token');
    if (token == null) return;

    await api.requestTopUp(token, amount);
  }

  Future<bool> register(String username, String password, String fullName) async {
    try {
      isLoading = true;
      notifyListeners();

      await api.register(username, password, fullName);

      isLoading = false;
      notifyListeners();

      return true;
    } catch (_) {
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      isLoading = true;
      notifyListeners();

      final token = await storage.read(key: 'token');
      if (token == null) return false;

      await api.changePassword(token, currentPassword, newPassword);

      isLoading = false;
      notifyListeners();

      return true;
    } catch (_) {
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
