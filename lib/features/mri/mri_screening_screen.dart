// lib/features/mri/mri_screening_screen.dart
//
// MRI AI Screening Screen for SmritiCare.
// Connects with Python/FastAPI AI backend for early cognitive risk analysis.
// Strictly non-clinical: early assistance screening telemetry only.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/mri_models.dart';
import '../../core/services/mri_screening_service.dart';

class MriScreeningScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const MriScreeningScreen({super.key, this.onBack});

  @override
  State<MriScreeningScreen> createState() => _MriScreeningScreenState();
}

class _MriScreeningScreenState extends State<MriScreeningScreen> {
  String _selectedSample = 'Normal Baseline Scan';
  String _sampleKey = 'normal';
  bool _isAnalyzing = false;
  bool _isServerHealthy = false;
  MriScanResult? _result;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    final healthy = await MriScreeningService.instance.checkBackendHealth();
    if (mounted) {
      setState(() {
        _isServerHealthy = healthy;
      });
    }
  }

  Future<void> _runAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    if (_isServerHealthy) {
      // Live backend call
      final res = await MriScreeningService.instance.analyzeMriScan(
        patientId: 'MC-2048',
        imageBytes: [1, 2, 3, 4], // Placeholder for selected scan binary
        fileName: '$_sampleKey.png',
      );
      if (mounted) {
        setState(() {
          _result = res;
          _isAnalyzing = false;
        });
      }
    } else {
      // When backend is offline, generate demonstration result with clear offline notice
      await Future.delayed(const Duration(milliseconds: 1200));
      final res = MriScreeningService.instance.generateDemoResult(
        patientId: 'MC-2048',
        sampleType: _sampleKey,
        fileName: '$_sampleKey.png',
      );
      if (mounted) {
        setState(() {
          _result = res;
          _isAnalyzing = false;
        });
      }
    }
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(
        text: MriScreeningService.instance.apiBaseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Configure FastAPI Backend',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the endpoint of your Python FastAPI server running the MRI model:',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'http://10.0.2.2:8000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                prefixIcon: const Icon(Icons.dns_rounded, color: AppColors.teal),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: For Android emulators use 10.0.2.2. For physical USB devices, use your computer\'s local Wi-Fi IP (e.g. 192.168.1.X:8000).',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              MriScreeningService.instance.setBaseUrl(controller.text);
              Navigator.pop(ctx);
              _checkServer();
            },
            child: const Text('Save & Test'),
          ),
        ],
      ),
    );
  }

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
              context.go('/');
            }
          },
        ),
        title: const Text(
          'MRI AI Screening',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
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
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Server Status Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isServerHealthy
                      ? const Color(0xFFE8F5E9)
                      : AppColors.amberPale,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isServerHealthy
                        ? Colors.green.shade400
                        : AppColors.amber,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isServerHealthy
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      color: _isServerHealthy
                          ? Colors.green.shade700
                          : AppColors.amberDeep,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isServerHealthy
                            ? 'FastAPI AI Backend Connected (${MriScreeningService.instance.apiBaseUrl})'
                            : 'AI Backend Standby (${MriScreeningService.instance.apiBaseUrl}). Showing demonstrative pipeline.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _isServerHealthy
                              ? Colors.green.shade900
                              : AppColors.amberDeep,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showServerConfigDialog,
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.tealDark,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Scan Selection Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.borderLight, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.bluePale,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.document_scanner_rounded,
                              color: AppColors.blueDeep, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Structural MRI Scan',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Coronal T1 slice: $_selectedSample',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Sample Radiographic Scans
                    _buildSampleScanTile(
                      keyName: 'normal',
                      title: 'Normal Baseline Scan',
                      subtitle: 'Age-matched cognitively healthy structural scan',
                      icon: Icons.health_and_safety_rounded,
                    ),
                    const SizedBox(height: 8),
                    _buildSampleScanTile(
                      keyName: 'mci',
                      title: 'Mild Cognitive Impairment Scan',
                      subtitle: 'Early medial temporal lobe volumetric variation',
                      icon: Icons.warning_amber_rounded,
                    ),
                    const SizedBox(height: 8),
                    _buildSampleScanTile(
                      keyName: 'dementia',
                      title: 'Atrophy Marker Scan',
                      subtitle: 'Marked cortical thinning and ventricular expansion',
                      icon: Icons.biotech_rounded,
                    ),

                    const SizedBox(height: 18),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded, size: 22),
                        label: Text(
                          _isAnalyzing
                              ? 'Analyzing Structural Markers...'
                              : 'Run AI Model Screening',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        onPressed: _isAnalyzing ? null : _runAnalysis,
                      ),
                    ),
                  ],
                ),
              ),

              // Results Section
              if (_result != null) ...[
                const SizedBox(height: 22),
                _buildResultCard(_result!),
              ],

              const SizedBox(height: 24),

              // Non-clinical clinical disclaimer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.softSection,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_outlined,
                        color: AppColors.muted, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Non-Clinical Screening Disclaimer: SmritiCare AI model analysis is intended for early supportive screening and cognitive monitoring only. It does not replace clinical diagnoses by certified neurologists, neuropsychologists, or radiologists.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSampleScanTile({
    required String keyName,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _sampleKey == keyName;

    return InkWell(
      onTap: () {
        setState(() {
          _sampleKey = keyName;
          _selectedSample = title;
          _result = null;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tealLight : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.teal : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? AppColors.teal : AppColors.muted, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.tealDark : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.teal, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(MriScanResult res) {
    Color cardColor = AppColors.tealPale;
    Color borderColor = AppColors.teal;
    Color textColor = AppColors.tealDeep;

    if (res.predictionClass == MriPredictionClass.mildCognitiveImpairment) {
      cardColor = AppColors.amberPale;
      borderColor = AppColors.amber;
      textColor = AppColors.amberDeep;
    } else if (res.predictionClass == MriPredictionClass.dementiaRisk) {
      cardColor = AppColors.coralPale;
      borderColor = AppColors.coral;
      textColor = AppColors.coralDeep;
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SCREENING RESULT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: textColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Confidence: ${(res.confidenceScore * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            res.prediction,
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            res.recommendation,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.ink.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_done_rounded,
                    size: 16, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Server: ${res.serverUrl} • Scan ID: ${res.scanId}',
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
}
