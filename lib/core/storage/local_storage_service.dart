// lib/core/storage/local_storage_service.dart
//
// Interface for persistent local storage operations.

abstract class LocalStorageService {
  Future<void> init();
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
  Future<void> setBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<void> remove(String key);
  Future<void> clear();
}
