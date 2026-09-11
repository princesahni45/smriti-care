// lib/core/storage/in_memory_storage_service.dart
//
// In-memory implementation of LocalStorageService used for development, testing,
// and fallback before SQLite/SharedPreferences are initialized.

import 'local_storage_service.dart';

class InMemoryStorageService implements LocalStorageService {
  final Map<String, dynamic> _store = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> setString(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<String?> getString(String key) async {
    return _store[key] as String?;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _store[key] = value;
  }

  @override
  Future<bool?> getBool(String key) async {
    return _store[key] as bool?;
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}
