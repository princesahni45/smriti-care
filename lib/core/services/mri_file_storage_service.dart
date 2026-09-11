// lib/core/services/mri_file_storage_service.dart
//
// FIX: Added local caregiver file storage for MRI scans and documents.
// Copies selected files to app-specific storage (not temp picker paths).
// Manages JSON metadata index for all caregiver uploads.
//
// Storage layout:
//   <appDocumentsDir>/
//     caregiver_uploads/
//       mri/            ← NIfTI (.nii, .nii.gz) or Analyze (.img)
//       images/         ← JPG, PNG, etc.
//       pdf/            ← PDF documents
//       presentations/  ← PPT, PPTX
//       other/          ← everything else
//       mri_history.json    ← MRI analysis results
//       uploads_index.json  ← metadata for all uploaded files

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/mri_models.dart';
import '../../config/api_config.dart';

class MriFileStorageService {
  MriFileStorageService._();
  static final MriFileStorageService instance = MriFileStorageService._();

  static const String _uploadsDir = 'caregiver_uploads';
  static const String _uploadsIndex = 'uploads_index.json';
  static const String _mriHistoryFile = 'mri_history.json';

  // ── Directory Helpers ─────────────────────────────────────────────────────

  Future<Directory> _getRootDir() async {
    final appDocs = await getApplicationDocumentsDirectory();
    final root = Directory('${appDocs.path}/$_uploadsDir');
    if (!await root.exists()) await root.create(recursive: true);
    return root;
  }

  Future<Directory> _getCategoryDir(MriFileCategory category) async {
    final root = await _getRootDir();
    final sub = switch (category) {
      MriFileCategory.mri => 'mri',
      MriFileCategory.images => 'images',
      MriFileCategory.pdf => 'pdf',
      MriFileCategory.presentations => 'presentations',
      MriFileCategory.other => 'other',
    };
    final dir = Directory('${root.path}/$sub');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ── File Classification ────────────────────────────────────────────────────

  // FIX: Added MRI format validation — classifies based on real backend supported formats
  ({MriFileCategory category, bool isMriCompatible}) classifyFile(
      String fileName) {
    final lower = fileName.toLowerCase();

    // Handle double extension .nii.gz first
    if (lower.endsWith('.nii.gz')) {
      return (category: MriFileCategory.mri, isMriCompatible: true);
    }

    final ext =
        lower.contains('.') ? lower.substring(lower.lastIndexOf('.') + 1) : '';

    // Check against real supported extensions from ApiConfig
    if (ApiConfig.mriCompatibleExtensions.contains(ext)) {
      return (category: MriFileCategory.mri, isMriCompatible: true);
    }
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'tif', 'webp']
        .contains(ext)) {
      return (category: MriFileCategory.images, isMriCompatible: false);
    }
    if (ext == 'pdf') {
      return (category: MriFileCategory.pdf, isMriCompatible: false);
    }
    if (['ppt', 'pptx', 'doc', 'docx'].contains(ext)) {
      return (category: MriFileCategory.presentations, isMriCompatible: false);
    }
    return (category: MriFileCategory.other, isMriCompatible: false);
  }

  String _getExtension(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.nii.gz')) return 'nii.gz';
    if (lower.contains('.')) return lower.substring(lower.lastIndexOf('.') + 1);
    return '';
  }

  // ── Save File to Local Storage ─────────────────────────────────────────────

  // FIX: Copies file to app-specific safe storage (not temp picker paths)
  Future<MriUploadedFile> saveFile({
    required String sourcePath,
    required String originalFileName,
    required String caregiverId,
    String? hdrSourcePath, // For Analyze 7.5 .img — path to the paired .hdr
  }) async {
    final classification = classifyFile(originalFileName);
    final extension = _getExtension(originalFileName);

    final categoryDir = await _getCategoryDir(classification.category);
    final timestamp = DateTime.now();
    final safeTs = _safeTimestamp(timestamp);

    final prefix = switch (classification.category) {
      MriFileCategory.mri => 'mri',
      MriFileCategory.images => 'img',
      MriFileCategory.pdf => 'doc',
      MriFileCategory.presentations => 'pres',
      MriFileCategory.other => 'file',
    };

    // Unique filename to avoid overwriting
    final uniqueName = '${prefix}_$safeTs.$extension';
    final destPath = '${categoryDir.path}/$uniqueName';

    final sourceFile = File(sourcePath);
    final destFile = await sourceFile.copy(destPath);
    final fileSize = await destFile.length();

    // Copy .hdr file if this is an Analyze 7.5 .img
    String? hdrDestPath;
    if (hdrSourcePath != null && hdrSourcePath.isNotEmpty) {
      try {
        final hdrSrc = File(hdrSourcePath);
        if (await hdrSrc.exists()) {
          final hdrName = '${prefix}_$safeTs.hdr';
          final hdrDest = '${categoryDir.path}/$hdrName';
          await hdrSrc.copy(hdrDest);
          hdrDestPath = hdrDest;
        }
      } catch (e) {
        debugPrint('MriFileStorageService: could not copy .hdr file: $e');
      }
    }

    final record = MriUploadedFile(
      id: '${prefix}_${timestamp.millisecondsSinceEpoch}',
      originalFileName: originalFileName,
      localFilePath: destFile.path,
      category: classification.category,
      fileExtension: extension,
      fileSizeBytes: fileSize,
      uploadedAt: timestamp,
      caregiverId: caregiverId,
      isMriCompatible: classification.isMriCompatible,
      predictionStatus: 'not_analyzed',
      hdrFilePath: hdrDestPath,
    );

    await _appendToIndex(record);
    return record;
  }

  String _safeTimestamp(DateTime dt) {
    // Produces e.g. '20260911_144500'
    return '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}'
        '_${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  // ── MRI History ────────────────────────────────────────────────────────────

  // FIX: Added local MRI history storage
  Future<void> saveMriResult({
    required MriUploadedFile file,
    required MriScanResult result,
  }) async {
    final root = await _getRootDir();
    final histFile = File('${root.path}/$_mriHistoryFile');

    List<Map<String, dynamic>> history = [];
    if (await histFile.exists()) {
      try {
        final raw = await histFile.readAsString();
        final parsed = jsonDecode(raw);
        if (parsed is List) {
          history = List<Map<String, dynamic>>.from(parsed);
        }
      } catch (e) {
        debugPrint('MriFileStorageService: history parse error: $e');
      }
    }

    history.insert(0, {
      ...result.toMap(),
      'localFilePath': file.localFilePath,
      'originalFileName': file.originalFileName,
    });

    await histFile.writeAsString(jsonEncode(history));

    await _updateIndexRecord(
        file.id,
        file.copyWith(
          predictionStatus:
              result.status == 'completed' ? 'completed' : 'failed',
          scanResultId: result.scanId,
        ));
  }

  Future<List<MriScanResult>> loadMriHistory() async {
    try {
      final root = await _getRootDir();
      final histFile = File('${root.path}/$_mriHistoryFile');
      if (!await histFile.exists()) return [];
      final raw = await histFile.readAsString();
      final parsed = jsonDecode(raw);
      if (parsed is! List) return [];
      return parsed
          .map(
              (e) => MriScanResult.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('MriFileStorageService: loadMriHistory error: $e');
      return [];
    }
  }

  // ── Uploads Index ──────────────────────────────────────────────────────────

  Future<void> _appendToIndex(MriUploadedFile record) async {
    final all = await loadAllUploads();
    all.insert(0, record);
    await _writeIndex(all);
  }

  Future<void> _updateIndexRecord(String id, MriUploadedFile updated) async {
    final all = await loadAllUploads();
    final idx = all.indexWhere((f) => f.id == id);
    if (idx >= 0) all[idx] = updated;
    await _writeIndex(all);
  }

  Future<void> _writeIndex(List<MriUploadedFile> files) async {
    final root = await _getRootDir();
    final indexFile = File('${root.path}/$_uploadsIndex');
    await indexFile
        .writeAsString(jsonEncode(files.map((f) => f.toMap()).toList()));
  }

  Future<List<MriUploadedFile>> loadAllUploads() async {
    try {
      final root = await _getRootDir();
      final indexFile = File('${root.path}/$_uploadsIndex');
      if (!await indexFile.exists()) return [];
      final raw = await indexFile.readAsString();
      final parsed = jsonDecode(raw);
      if (parsed is! List) return [];
      return parsed
          .map((e) =>
              MriUploadedFile.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('MriFileStorageService: loadAllUploads error: $e');
      return [];
    }
  }

  Future<List<MriUploadedFile>> loadUploadsByCategory(
      MriFileCategory category) async {
    final all = await loadAllUploads();
    return all.where((f) => f.category == category).toList();
  }

  Future<bool> fileExists(MriUploadedFile record) async {
    return File(record.localFilePath).exists();
  }

  Future<String> getStorageRootPath() async {
    final root = await _getRootDir();
    return root.path;
  }
}
