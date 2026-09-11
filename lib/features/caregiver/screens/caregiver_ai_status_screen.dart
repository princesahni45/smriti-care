// lib/features/caregiver/screens/caregiver_ai_status_screen.dart
//
// Caregiver Diagnostics & Local AI Model Installation / Status Screen.
//
// DESIGN PRINCIPLES:
// 1. High contrast, readable metrics for device capacity auditing.
// 2. Clear representation of whether the on-device Qwen model is installed or running fallback.
// 3. Zero emojis in the UI or strings.
// 4. Safe test prompt runner for proof-of-concept evaluation.

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/ai/local_qwen_service.dart';
import '../../../services/ai/ai_model_status.dart';
import '../../../services/ai/ai_request.dart';

class CaregiverAiStatusScreen extends StatefulWidget {
  final LocalQwenService? aiService;

  const CaregiverAiStatusScreen({
    super.key,
    this.aiService,
  });

  @override
  State<CaregiverAiStatusScreen> createState() =>
      _CaregiverAiStatusScreenState();
}

class _CaregiverAiStatusScreenState extends State<CaregiverAiStatusScreen> {
  late LocalQwenService _aiService;
  bool _isLoading = false;
  String _lastTestOutput = '';
  String _lastOutputDetails = '';

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? LocalQwenService.instance;
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _isLoading = true);
    await _aiService.initialize();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runTestPrompt(AIContextType contextType, String prompt) async {
    setState(() {
      _isLoading = true;
      _lastTestOutput = 'Generating response...';
      _lastOutputDetails = '';
    });

    final request = AIRequest(
      prompt: prompt,
      languageCode: 'en',
      patientName: 'Ramesh',
      contextType: contextType,
      metadata: const {
        'gameTitle': 'Memory Match',
        'reminderTitle': 'Blood Pressure Medicine',
        'reminderTime': '8:30 AM',
      },
    );

    final response = await _aiService.generateResponse(request);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _lastTestOutput = response.text;
        _lastOutputDetails = 'Latency: ms | Tokens:  | '
            'Source:  | '
            'TPS: ';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _aiService.status;
    final metrics = _aiService.metrics;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'On-Device AI Diagnostics',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.teal),
            tooltip: 'Refresh Status',
            onPressed: _refreshStatus,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            _buildStatusBanner(status),
            const SizedBox(height: 16),

            // Hardware & Model Specifications
            _buildSpecsCard(metrics),
            const SizedBox(height: 16),

            // Telemetry & Benchmark Metrics
            _buildBenchmarkCard(metrics),
            const SizedBox(height: 20),

            // Proof of Concept Test Actions
            const Text(
              'Proof of Concept Test Queries',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Test the 5 supported non-clinical conversation types.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Greeting'),
                  onPressed: _isLoading
                      ? null
                      : () => _runTestPrompt(
                          AIContextType.greeting, 'Good morning assistant.'),
                ),
                ActionChip(
                  label: const Text('Explain Game'),
                  onPressed: _isLoading
                      ? null
                      : () => _runTestPrompt(AIContextType.gameExplanation,
                          'How do I play Memory Match?'),
                ),
                ActionChip(
                  label: const Text('Repeat Reminder'),
                  onPressed: _isLoading
                      ? null
                      : () => _runTestPrompt(AIContextType.reminderRepeat,
                          'What is my next reminder?'),
                ),
                ActionChip(
                  label: const Text('Caregiver Help'),
                  onPressed: _isLoading
                      ? null
                      : () => _runTestPrompt(AIContextType.caregiverAssistance,
                          'I feel confused and need my caregiver.'),
                ),
                ActionChip(
                  label: const Text('General Question'),
                  onPressed: _isLoading
                      ? null
                      : () => _runTestPrompt(AIContextType.generalQuery,
                          'Is it raining outside today?'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Response Preview Box
            if (_lastTestOutput.isNotEmpty) _buildOutputCard(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(AIModelStatus status) {
    Color bannerColor;
    Color textColor;
    String statusTitle;
    String statusSubtitle;
    IconData icon;

    switch (status) {
      case AIModelStatus.ready:
        bannerColor = AppColors.tealPale;
        textColor = AppColors.tealDark;
        statusTitle = 'Model Ready for On-Device Inference';
        statusSubtitle =
            'Qwen model is loaded in device RAM. Operating fully offline.';
        icon = Icons.check_circle_rounded;
        break;
      case AIModelStatus.loading:
        bannerColor = AppColors.violetPale;
        textColor = AppColors.violetDeep;
        statusTitle = 'Model Loading into RAM';
        statusSubtitle = 'Mapping weights from internal storage.';
        icon = Icons.hourglass_top_rounded;
        break;
      case AIModelStatus.notInstalled:
        bannerColor = AppColors.surface;
        textColor = AppColors.muted;
        statusTitle = 'Model Weights Not Installed';
        statusSubtitle =
            'No model binary found in app storage. Active queries use deterministic fallbacks.';
        icon = Icons.info_outline_rounded;
        break;
      case AIModelStatus.unavailable:
        bannerColor = AppColors.coralPale;
        textColor = AppColors.coralDeep;
        statusTitle = 'AI Service Unavailable';
        statusSubtitle =
            'Deterministic safety fallbacks are actively protecting responses.';
        icon = Icons.warning_amber_rounded;
        break;
      case AIModelStatus.error:
        bannerColor = AppColors.coralPale;
        textColor = AppColors.coralDeep;
        statusTitle = 'Initialization Error';
        statusSubtitle = 'Failed to load native engine. Fallback active.';
        icon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusSubtitle,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsCard(AIModelBenchmarkMetrics metrics) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hardware & Model Specifications',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          _buildSpecRow('Target Hardware', 'OnePlus Nord CE 3 Lite 5G'),
          _buildSpecRow('SoC / Processor', 'Qualcomm Snapdragon 695 5G'),
          _buildSpecRow('Device Memory', '8 GB LPDDR4X'),
          _buildSpecRow('Selected Model', 'Qwen3-0.6B Quantized (Q4_K_M)'),
          _buildSpecRow('Model Weight Size', ' MB'),
          _buildSpecRow('Network Policy', '100% Offline (Zero Cloud Sync)'),
        ],
      ),
    );
  }

  Widget _buildBenchmarkCard(AIModelBenchmarkMetrics metrics) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Telemetry & Diagnostics (Non-Sensitive)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          _buildSpecRow('Resident RAM Usage', ' MB'),
          _buildSpecRow('Load Duration', ' ms'),
          _buildSpecRow('First Token Latency', ' ms'),
          _buildSpecRow('Generation Speed', ' tokens/sec'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
        ],
      ),
    );
  }

  Widget _buildOutputCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Response Verification',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.tealDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _lastTestOutput,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              height: 1.4,
            ),
          ),
          if (_lastOutputDetails.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _lastOutputDetails,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
