// lib/features/mri/mri_screening_screen.dart
//
// FIX: Complete MRI Screening Screen for SmritiCare Caregiver Dashboard.
// Real file picker → local copy → MRI format validation → FastAPI /predict → show result → save history.
// Document-only files (PDF/PPT/image) are saved locally but Analyze MRI button is disabled.

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/mri_models.dart';
import '../../core/services/mri_screening_service.dart';
import '../../core/services/mri_file_storage_service.dart';
import '../../core/constants/app_constants.dart';

class MriScreeningScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const MriScreeningScreen({super.key, this.onBack});

  @override
  State<MriScreeningScreen> createState() => _MriScreeningScreenState();
}

class _MriScreeningScreenState extends State<MriScreeningScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _isServerHealthy = false;
  bool _checkingServer = true;
  bool _isSaving = false;
  bool _isAnalyzing = false;

  MriUploadedFile? _selectedFile;
  MriScanResult? _result;
  String? _errorMessage;
  String? _saveMessage;

  List<MriScanResult> _mriHistory = [];
  List<MriUploadedFile> _allUploads = [];

  @override
  void initState() {
    super.initState();
    _checkServer();
    _loadHistory();
  }

  Future<void> _checkServer() async {
    setState(() => _checkingServer = true);
    final healthy = await MriScreeningService.instance.checkBackendHealth();
    if (mounted) {
      setState(() {
        _isServerHealthy = healthy;
        _checkingServer = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    final history = await MriFileStorageService.instance.loadMriHistory();
    final uploads = await MriFileStorageService.instance.loadAllUploads();
    if (mounted) {
      setState(() {
        _mriHistory = history;
        _allUploads = uploads;
      });
    }
  }

  // ── File Picker ────────────────────────────────────────────────────────────

  // FIX: Configured file_picker for MRI files with custom extensions (.nii, .nii.gz, .dcm, .dicom, .zip, .gz)
  Future<void> _pickMriFile({bool browseAll = false}) async {
    try {
      PlatformFile? platformFile;

      if (!browseAll) {
        try {
          platformFile = await FilePicker.pickFile(
            type: FileType.custom,
            allowedExtensions: [
              'nii',
              'gz',
              'dcm',
              'dicom',
              'zip',
              'img',
            ],
          );
        } catch (_) {
          // If system picker rejects custom filter on certain devices, fall back to any
          platformFile = await FilePicker.pickFile(type: FileType.any);
        }
      } else {
        // Fallback for Android file managers that grey out unregistered mime extensions
        platformFile = await FilePicker.pickFile(type: FileType.any);
      }

      if (platformFile == null) return;
      if (platformFile.path == null) {
        _showError(
            'Could not access the selected file path. Check storage permissions.');
        return;
      }

      // FIX: Validate complete filename including .nii.gz
      final name = platformFile.name.toLowerCase();
      final validMRI = name.endsWith('.nii') ||
          name.endsWith('.nii.gz') ||
          name.endsWith('.dcm') ||
          name.endsWith('.dicom') ||
          name.endsWith('.zip') ||
          name.endsWith('.gz') ||
          name.endsWith('.img');

      if (!validMRI) {
        _showError(
            'Unsupported MRI file format.\nSupported: .nii, .nii.gz, .dcm, .dicom, .zip, .gz');
        return;
      }

      debugPrint("Selected MRI file: ${platformFile.name}");
      debugPrint("MRI path: ${platformFile.path}");

      setState(() {
        _isSaving = true;
        _errorMessage = null;
        _saveMessage = null;
        _result = null;
      });

      // Copy to local storage
      MriUploadedFile savedFile;
      try {
        savedFile = await MriFileStorageService.instance.saveFile(
          sourcePath: platformFile.path!,
          originalFileName: platformFile.name,
          caregiverId: AppConstants.caregiverName,
        );
        setState(() {
          _selectedFile = savedFile;
          _isSaving = false;
          _saveMessage = '✓ MRI file selected and saved locally';
        });
        await _loadHistory();
      } catch (e) {
        setState(() {
          _isSaving = false;
          _errorMessage =
              'Failed to save file locally: ${e.toString().split('\n').first}';
        });
        return;
      }
    } on Exception catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage =
            'File selection error: ${e.toString().split('\n').first}';
      });
    }
  }

  // FIX: Separate document/image picker keeping PDF/images completely separate from MRI
  Future<void> _pickDocumentFile() async {
    try {
      final platformFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'pptx', 'docx'],
      );

      if (platformFile == null || platformFile.path == null) return;

      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      try {
        await MriFileStorageService.instance.saveFile(
          sourcePath: platformFile.path!,
          originalFileName: platformFile.name,
          caregiverId: AppConstants.caregiverName,
        );
        setState(() => _isSaving = false);
        await _loadHistory();
      } catch (e) {
        setState(() {
          _isSaving = false;
          _errorMessage =
              'Failed to save document: ${e.toString().split('\n').first}';
        });
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage =
            'Document selection error: ${e.toString().split('\n').first}';
      });
    }
  }

  // ── MRI Analysis ───────────────────────────────────────────────────────────

  // FIX: Added FastAPI MRI integration — sends real file to /predict
  Future<void> _runAnalysis() async {
    if (_selectedFile == null || !_selectedFile!.isMriCompatible) return;

    setState(() {
      _isAnalyzing = true;
      _result = null;
      _errorMessage = null;
    });

    try {
      // Check if local file still exists
      if (!await MriFileStorageService.instance.fileExists(_selectedFile!)) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage =
              'Local MRI file not found. Please re-select the file.';
        });
        return;
      }

      String? hdrPath;
      if (_selectedFile!.fileExtension.toLowerCase() == 'img') {
        hdrPath = _selectedFile!.hdrFilePath;
      }

      final res = await MriScreeningService.instance.analyzeMriFile(
        filePath: _selectedFile!.localFilePath,
        fileName: _selectedFile!.originalFileName,
        caregiverId: AppConstants.caregiverName,
        hdrPath: hdrPath,
      );

      if (mounted) {
        setState(() {
          _result = res;
          _isAnalyzing = false;
        });
      }

      // Save result to history
      if (res.status == 'completed') {
        // FIX: Added local MRI history storage
        await MriFileStorageService.instance.saveMriResult(
          file: _selectedFile!,
          result: res,
        );
        await _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = 'Analysis error: ${e.toString().split('\n').first}';
        });
      }
    }
  }

  // FIX: Config dialog with preset buttons for USB reverse (127.0.0.1), Wi-Fi LAN (192.168.9.221), and emulator (10.0.2.2)
  void _showServerConfigDialog() {
    final controller =
        TextEditingController(text: MriScreeningService.instance.apiBaseUrl);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Configure FastAPI Backend',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select a preset or enter your PC/server IP running the Python FastAPI server:',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.usb_rounded,
                        size: 16, color: AppColors.teal),
                    label: const Text('USB (127.0.0.1:8000)',
                        style: TextStyle(fontSize: 11)),
                    backgroundColor: controller.text == 'http://127.0.0.1:8000'
                        ? AppColors.tealPale
                        : null,
                    onPressed: () {
                      setDialogState(() {
                        controller.text = 'http://127.0.0.1:8000';
                      });
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.wifi_rounded,
                        size: 16, color: AppColors.teal),
                    label: const Text('Wi-Fi (192.168.9.221:8000)',
                        style: TextStyle(fontSize: 11)),
                    backgroundColor:
                        controller.text == 'http://192.168.9.221:8000'
                            ? AppColors.tealPale
                            : null,
                    onPressed: () {
                      setDialogState(() {
                        controller.text = 'http://192.168.9.221:8000';
                      });
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.phone_android_rounded,
                        size: 16, color: AppColors.teal),
                    label: const Text('Emulator (10.0.2.2:8000)',
                        style: TextStyle(fontSize: 11)),
                    backgroundColor: controller.text == 'http://10.0.2.2:8000'
                        ? AppColors.tealPale
                        : null,
                    onPressed: () {
                      setDialogState(() {
                        controller.text = 'http://10.0.2.2:8000';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'http://127.0.0.1:8000',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon:
                      const Icon(Icons.dns_rounded, color: AppColors.teal),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('common.cancel', defaultText: 'Cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                MriScreeningService.instance.setBaseUrl(controller.text.trim());
                Navigator.pop(ctx);
                _checkServer();
              },
              child: const Text('Save & Test'),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (mounted) setState(() => _errorMessage = msg);
  }

  String _categoryLabel(MriFileCategory cat) => switch (cat) {
        MriFileCategory.mri => 'MRI Scans',
        MriFileCategory.images => 'Images',
        MriFileCategory.pdf => 'PDFs',
        MriFileCategory.presentations => 'Presentations',
        MriFileCategory.other => 'Documents',
      };

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.ink, size: 28),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/caregiver');
            }
          },
        ),
        title: const Text('MRI Screening',
            style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 19)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet_rounded,
                color: AppColors.teal),
            tooltip: 'Server Settings',
            onPressed: _showServerConfigDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildServerStatusBanner(),
              const SizedBox(height: 16),
              _buildFileSelectionCard(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorCard(_errorMessage!),
              ],
              if (_result != null) ...[
                const SizedBox(height: 16),
                _buildResultCard(_result!),
              ],
              const SizedBox(height: 20),
              _buildDisclaimerCard(),
              const SizedBox(height: 20),
              _buildMriHistorySection(),
              const SizedBox(height: 20),
              _buildDocumentSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Server Status Banner ───────────────────────────────────────────────────

  Widget _buildServerStatusBanner() {
    final url = MriScreeningService.instance.apiBaseUrl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _checkingServer
            ? AppColors.softSection
            : (_isServerHealthy
                ? const Color(0xFFE8F5E9)
                : AppColors.amberPale),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _checkingServer
              ? AppColors.borderLight
              : (_isServerHealthy ? Colors.green.shade400 : AppColors.amber),
        ),
      ),
      child: Row(
        children: [
          _checkingServer
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.teal))
              : Icon(
                  _isServerHealthy
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: _isServerHealthy
                      ? Colors.green.shade700
                      : AppColors.amberDeep,
                  size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _checkingServer
                  ? 'Checking backend...'
                  : _isServerHealthy
                      ? 'AI Backend Connected ($url)'
                      : 'Backend Offline ($url)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _isServerHealthy
                    ? Colors.green.shade900
                    : AppColors.amberDeep,
              ),
            ),
          ),
          // FIX: Added one-tap refresh/retry button to test connection immediately
          InkWell(
            onTap: _checkingServer ? null : _checkServer,
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(Icons.refresh_rounded,
                  size: 16, color: AppColors.tealDark),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _showServerConfigDialog,
            child: const Text('Change',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tealDark,
                    decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }

  // ── File Selection Card ────────────────────────────────────────────────────

  Widget _buildFileSelectionCard() {
    final hasFile = _selectedFile != null;
    final canAnalyze = hasFile &&
        _selectedFile!.isMriCompatible &&
        !_isAnalyzing &&
        !_isSaving;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.tealPale,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.biotech_rounded,
                    color: AppColors.teal, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MRI Scan Upload',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    SizedBox(height: 2),
                    Text('Supported: .nii, .nii.gz, .dcm, .dicom, .zip, .gz',
                        style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // FIX: The MRI upload button shows "Select MRI File"
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.teal, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                foregroundColor: AppColors.tealDark,
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.teal))
                  : const Icon(Icons.attach_file_rounded),
              label: Text(_isSaving ? 'Saving MRI File...' : 'Select MRI File',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              onPressed:
                  _isSaving ? null : () => _pickMriFile(browseAll: false),
            ),
          ),
          const SizedBox(height: 4),
          // FIX: Fallback helper if Android file manager greys out uncompressed .nii files
          Center(
            child: TextButton(
              onPressed: _isSaving ? null : () => _pickMriFile(browseAll: true),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Files greyed out? Browse all files from storage',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.teal,
                    decoration: TextDecoration.underline),
              ),
            ),
          ),

          // FIX: Display filename, file size, file format, and selected status
          if (hasFile) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _selectedFile!.isMriCompatible
                    ? AppColors.tealLight
                    : AppColors.amberPale,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedFile!.isMriCompatible
                      ? AppColors.teal
                      : AppColors.amber,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filename display
                  Row(
                    children: [
                      Icon(
                        _selectedFile!.isMriCompatible
                            ? Icons.check_circle_rounded
                            : Icons.info_rounded,
                        color: _selectedFile!.isMriCompatible
                            ? AppColors.tealDark
                            : AppColors.amberDeep,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFile!.originalFileName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _selectedFile!.isMriCompatible
                                ? AppColors.tealDeep
                                : AppColors.amberDeep,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // File Format, File Size, Selected Status badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _detailBadge(
                          'Format', _selectedFile!.fileExtension.toUpperCase()),
                      _detailBadge('Size', _selectedFile!.formattedSize),
                      _detailBadge(
                        'Status',
                        _selectedFile!.isMriCompatible
                            ? 'Selected'
                            : 'Unsupported',
                        isSuccess: _selectedFile!.isMriCompatible,
                      ),
                    ],
                  ),
                  if (_saveMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(_saveMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedFile!.isMriCompatible
                              ? AppColors.tealDark
                              : AppColors.amberDeep,
                          height: 1.4,
                        )),
                  ],
                ],
              ),
            ),
          ],

          // Non-MRI notice
          if (hasFile && !_selectedFile!.isMriCompatible) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.softSection,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.muted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This file has been stored locally, but it cannot be analyzed by the MRI AI model. '
                      'Only .nii, .nii.gz, and .img (Analyze 7.5) formats are supported.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.muted, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Analyze MRI Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canAnalyze ? AppColors.teal : AppColors.borderLight,
                foregroundColor: canAnalyze ? Colors.white : AppColors.muted,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Icon(Icons.auto_awesome_rounded, size: 22),
              label: Text(
                _isAnalyzing ? 'Analyzing...' : 'Analyze MRI',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              onPressed: canAnalyze ? _runAnalysis : null,
            ),
          ),

          if (!hasFile || !_selectedFile!.isMriCompatible)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  hasFile
                      ? 'Analyze MRI disabled — selected file is not a supported MRI format'
                      : 'Select a NIfTI or Analyze 7.5 file to enable analysis',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Error Card ─────────────────────────────────────────────────────────────

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.error, height: 1.4)),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  // ── Result Card ────────────────────────────────────────────────────────────

  Widget _buildResultCard(MriScanResult res) {
    Color cardColor, borderColor, textColor;
    switch (res.predictionClass) {
      case MriPredictionClass.normal:
        cardColor = AppColors.tealLight;
        borderColor = AppColors.teal;
        textColor = AppColors.tealDeep;
        break;
      case MriPredictionClass.veryMild:
        cardColor = AppColors.amberPale;
        borderColor = AppColors.amber;
        textColor = AppColors.amberDeep;
        break;
      case MriPredictionClass.dementia:
        cardColor = AppColors.coralPale;
        borderColor = AppColors.coral;
        textColor = AppColors.coralDeep;
        break;
      case MriPredictionClass.inconclusive:
        cardColor = AppColors.softSection;
        borderColor = AppColors.borderLight;
        textColor = AppColors.muted;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
              color: borderColor.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8)),
                child: Text('SCREENING RESULT',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: textColor)),
              ),
              const Spacer(),
              if (res.status == 'completed')
                Text('${(res.confidenceScore * 100).round()}% confidence',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor)),
            ],
          ),
          const SizedBox(height: 12),
          Text(res.prediction,
              style: GoogleFonts.dmSans(
                  fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 8),
          Text(res.recommendation,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.ink.withValues(alpha: 0.85))),

          // Low confidence warning
          if (res.isLowConfidence) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(res.clinicalNote,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.amberDeep)),
                  ),
                ],
              ),
            ),
          ],

          // Class Probabilities
          if (res.displayProbabilities != null &&
              res.displayProbabilities!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Class Probabilities',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  const SizedBox(height: 8),
                  ...res.displayProbabilities!.entries.map((e) {
                    final pct = (e.value * 100);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Text(e.key,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.inkSoft))),
                              Text('${pct.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: textColor)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          LinearProgressIndicator(
                            value: e.value.clamp(0.0, 1.0),
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.5),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(borderColor),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.storage_rounded,
                    size: 14, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Saved locally · ${res.timestamp.day}/${res.timestamp.month}/${res.timestamp.year} '
                    '${res.timestamp.hour.toString().padLeft(2, '0')}:${res.timestamp.minute.toString().padLeft(2, '0')}',
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Medical Disclaimer ─────────────────────────────────────────────────────

  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softSection,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: AppColors.muted, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI-generated MRI screening results are for research and decision-support purposes only '
              'and are not a medical diagnosis. Clinical interpretation must be performed by a qualified '
              'healthcare professional.',
              style:
                  TextStyle(fontSize: 11, color: AppColors.muted, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  // ── MRI History Section ────────────────────────────────────────────────────

  Widget _buildMriHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Previous MRI Screenings',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
        const SizedBox(height: 10),
        if (_mriHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Center(
              child: Text(
                  'No MRI screenings yet.\nSelect an MRI file and run analysis to see results here.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                  textAlign: TextAlign.center),
            ),
          )
        else
          ...(_mriHistory.take(5).map((r) => _buildHistoryTile(r))),
      ],
    );
  }

  Widget _buildHistoryTile(MriScanResult r) {
    Color dotColor;
    switch (r.predictionClass) {
      case MriPredictionClass.normal:
        dotColor = AppColors.teal;
        break;
      case MriPredictionClass.veryMild:
        dotColor = AppColors.amber;
        break;
      case MriPredictionClass.dementia:
        dotColor = AppColors.coral;
        break;
      default:
        dotColor = AppColors.muted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.prediction,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${r.imageName ?? 'MRI scan'} · ${(r.confidenceScore * 100).round()}% confidence',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${r.timestamp.day}/${r.timestamp.month}/${r.timestamp.year}',
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  // ── Document Section ───────────────────────────────────────────────────────

  // FIX: Separate document section with its own dedicated upload button for PDFs/images
  Widget _buildDocumentSection() {
    final nonMriUploads = _allUploads.where((f) => !f.isMriCompatible).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Other Uploaded Documents',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            TextButton.icon(
              onPressed: _isSaving ? null : _pickDocumentFile,
              icon: const Icon(Icons.upload_file_rounded,
                  size: 16, color: AppColors.tealDark),
              label: const Text('Select PDF / Image',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tealDark)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (nonMriUploads.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Center(
              child: Text(
                  'No documents uploaded yet.\nUse "Select PDF / Image" above to store PDFs or images locally.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                  textAlign: TextAlign.center),
            ),
          )
        else
          ...nonMriUploads.take(10).map((f) => _buildDocumentTile(f)),
      ],
    );
  }

  // FIX: Display badges for Format, Size, and Selected Status
  Widget _detailBadge(String label, String value, {bool isSuccess = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess
              ? AppColors.teal.withValues(alpha: 0.3)
              : AppColors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, color: AppColors.ink),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: AppColors.muted),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isSuccess ? AppColors.tealDark : AppColors.amberDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTile(MriUploadedFile f) {
    IconData icon;
    Color iconColor;
    switch (f.category) {
      case MriFileCategory.images:
        icon = Icons.image_rounded;
        iconColor = AppColors.violet;
        break;
      case MriFileCategory.pdf:
        icon = Icons.picture_as_pdf_rounded;
        iconColor = AppColors.coral;
        break;
      case MriFileCategory.presentations:
        icon = Icons.slideshow_rounded;
        iconColor = AppColors.amber;
        break;
      default:
        icon = Icons.insert_drive_file_rounded;
        iconColor = AppColors.muted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.softSection,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.originalFileName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${f.fileExtension.toUpperCase()} · ${f.formattedSize} · '
                  '${f.uploadedAt.day}/${f.uploadedAt.month}/${f.uploadedAt.year}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.softSection,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_categoryLabel(f.category),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}
