import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LanguageProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String _languageCode = 'vi';
  bool _loaded = false;

  String get languageCode => _languageCode;
  bool get loaded => _loaded;
  Locale get locale => Locale(_languageCode);

  Future<void> loadLanguage() async {
    final saved = await _storage.read(key: 'language_code');
    if (saved != null && (saved == 'en' || saved == 'vi')) {
      _languageCode = saved;
    }
    _loaded = true;
    notifyListeners();
  }

  void setLanguage(String code) {
    if (code != 'en' && code != 'vi') return;
    _languageCode = code;
    _storage.write(key: 'language_code', value: code);
    notifyListeners();
  }
}
