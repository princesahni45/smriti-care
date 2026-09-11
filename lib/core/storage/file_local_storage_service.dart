// lib/core/storage/file_local_storage_service.dart
//
// File-based implementation of LocalStorageService for persistent offline storage.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'local_storage_service.dart';

class FileLocalStorageService implements LocalStorageService {
  final Map<String, dynamic> _data = {};
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is Map<String, dynamic>) {
            _data.addAll(decoded);
          }
        }
      }
    } catch (e) {
      debugPrint('FileLocalStorageService init warning: $e');
    } finally {
      _initialized = true;
    }
  }

  Future<File> _getFile() async {
    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = Directory.systemTemp;
    }
    return File('${dir.path}/smriti_care_preferences.json');
  }

  Future<void> _save() async {
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(_data));
    } catch (e) {
      debugPrint('FileLocalStorageService save warning: $e');
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    await init();
    _data[key] = value;
    await _save();
  }

  @override
  Future<String?> getString(String key) async {
    await init();
    return _data[key] as String?;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await init();
    _data[key] = value;
    await _save();
  }

  @override
  Future<bool?> getBool(String key) async {
    await init();
    return _data[key] as bool?;
  }

  @override
  Future<void> remove(String key) async {
    await init();
    _data.remove(key);
    await _save();
  }

  @override
  Future<void> clear() async {
    await init();
    _data.clear();
    await _save();
  }
}
