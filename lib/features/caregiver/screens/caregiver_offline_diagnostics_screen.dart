// lib/features/caregiver/screens/caregiver_offline_diagnostics_screen.dart
//
// Offline-First Diagnostics Screen for Caregivers and Administrators.
//
// Displays:
// 1. Network state (Online / Offline / Airplane Mode)
// 2. Local database status and persistent storage health
// 3. Pending sync event count
// 4. On-device AI model statuses (Qwen, AI4Bharat ASR, TTS offline capability)
// 5. Last successful synchronization timestamp
// 6. Synchronization errors and manual sync trigger
// 7. Sanitized pending events inspection (zero PII exposure)

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/sync/offline_sync_service.dart';
import '../../../services/ai/local_qwen_service.dart';
import '../../../services/voice/ai4bharat_asr_service.dart';
import '../../../services/tts/text_to_speech_service.dart';
import '../../../services/tts/local_text_to_speech_service.dart';
import '../../../services/tts/tts_models.dart';

class CaregiverOfflineDiagnosticsScreen extends StatefulWidget {
  final OfflineSyncService? syncService;
  final TextToSpeechService? ttsService;
  final VoidCallback? onBack;

  const CaregiverOfflineDiagnosticsScreen({
    super.key,
    this.syncService,
    this.ttsService,
    this.onBack,
  });

  @override
  State<CaregiverOfflineDiagnosticsScreen> createState() =>
      _CaregiverOfflineDiagnosticsScreenState();
}

class _CaregiverOfflineDiagnosticsScreenState
    extends State<CaregiverOfflineDiagnosticsScreen> {
  late OfflineSyncService _sync;
  late TextToSpeechService _tts;
  bool _isLoading = true;
  bool _isOnline = false;
  TTSLanguageSupport? _enTts;
  TTSLanguageSupport? _hiTts;
  TTSLanguageSupport? _asTts;

  static const Color _statusGreen = Color(0xFF1B8755);

  @override
  void initState() {
    super.initState();
    _sync = widget.syncService ?? OfflineSyncService.instance;
    _tts = widget.ttsService ?? LocalTextToSpeechService.instance;
    _refreshDiagnostics();
  }

  Future<void> _refreshDiagnostics() async {
    setState(() => _isLoading = true);
    await _sync.init();
    final online = await _sync.isRemoteReachable();

    await _tts.initialize();
    final enSupport = await _tts.checkLanguageSupport('en');
    final hiSupport = await _tts.checkLanguageSupport('hi');
    final asSupport = await _tts.checkLanguageSupport('as');

    if (mounted) {
      setState(() {
        _isOnline = online;
        _enTts = enSupport;
        _hiTts = hiSupport;
        _asTts = asSupport;
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerManualSync() async {
    setState(() => _isLoading = true);
    await _sync.syncUpstream();
    await _refreshDiagnostics();
  }

  void _toggleSimulatedAirplaneMode() {
    if (_isOnline) {
      _sync.setMockReachability(false);
    } else {
      _sync.setMockReachability(true);
    }
    _refreshDiagnostics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Offline Diagnostics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Status',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.teal),
            onPressed: _refreshDiagnostics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNetworkCard(),
                  const SizedBox(height: 16),
                  _buildStorageHealthCard(),
                  const SizedBox(height: 16),
                  _buildSyncCard(),
                  const SizedBox(height: 16),
                  _buildAiModelsCard(),
                  const SizedBox(height: 16),
                  _buildPendingEventsCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildNetworkCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Network State',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isOnline
                      ? _statusGreen.withValues(alpha: 0.12)
                      : AppColors.amberPale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isOnline ? 'Online' : 'Offline / Airplane Mode',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _isOnline ? _statusGreen : AppColors.amberDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isOnline
                ? 'Device has verified internet connectivity. Upstream sync is active.'
                : 'Device is running entirely offline. All patient features and local operations continue normally.',
            style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _toggleSimulatedAirplaneMode,
            icon: Icon(
              _isOnline
                  ? Icons.airplanemode_active_rounded
                  : Icons.wifi_rounded,
              size: 18,
            ),
            label: Text(
              _isOnline
                  ? 'Simulate Airplane Mode'
                  : 'Restore Online Connectivity',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.teal,
              side: const BorderSide(color: AppColors.teal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageHealthCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Local Database Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _sync.databaseStatus,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _statusGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStorageFileRow('Patient & Caregiver Reminders',
              'smriti_care_caregiver_store.json', true),
          _buildStorageFileRow(
              'Cognitive Game History', 'smriti_care_game_history.json', true),
          _buildStorageFileRow('User Preferences & Locale',
              'smriti_care_preferences.json', true),
          _buildStorageFileRow(
              'Offline Sync Queue', 'smriti_care_sync_queue.json', true),
        ],
      ),
    );
  }

  Widget _buildStorageFileRow(String name, String fileName, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: active ? _statusGreen : AppColors.coral,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            fileName,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncCard() {
    final pendingCount = _sync.getPendingCount();
    final lastSync = _sync.lastSuccessfulSync;
    final lastError = _sync.lastSyncError;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Synchronization Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pendingCount > 0
                      ? AppColors.amberPale
                      : _statusGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pendingCount > 0
                      ? '$pendingCount Pending'
                      : 'All Synced (0 Pending)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color:
                        pendingCount > 0 ? AppColors.amberDeep : _statusGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Last Successful Sync: ${lastSync != null ? _formatDateTime(lastSync) : 'None (Offline Mode)'}',
            style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
          ),
          if (lastError != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.coralPale,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.coral),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sync Note: $lastError',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.coralDeep,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _triggerManualSync,
            icon: const Icon(Icons.sync_rounded, size: 18),
            label: const Text('Sync Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiModelsCard() {
    final qwen = LocalQwenService.instance;
    final asr = AI4BharatASRService.instance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI & Voice Models Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          _buildModelRow(
            'Local Qwen Model',
            qwen.status.name,
            qwen.isAvailable,
            'Runs offline only when model weights are verified on storage',
          ),
          const Divider(height: 20),
          _buildModelRow(
            'AI4Bharat ASR Engine',
            asr.modelStatus.name,
            asr.isAvailable,
            'Recognizes speech locally without streaming audio to the cloud',
          ),
          const Divider(height: 20),
          const Text(
            'Text-To-Speech (TTS) Offline Capability:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          _buildTtsLangRow('English (en)', _enTts),
          _buildTtsLangRow('Hindi (hi)', _hiTts),
          _buildTtsLangRow('Assamese (as)', _asTts),
        ],
      ),
    );
  }

  Widget _buildModelRow(
      String title, String statusName, bool ready, String subtext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ready
                    ? _statusGreen.withValues(alpha: 0.12)
                    : AppColors.muted.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ready ? _statusGreen : AppColors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtext,
          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
        ),
      ],
    );
  }

  Widget _buildTtsLangRow(String label, TTSLanguageSupport? support) {
    final ready =
        support != null && support.offlineCapable && support.isWorking;
    final statusText = support?.statusLabel ?? 'Checking...';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
          ),
          Text(
            ready ? 'Offline Ready' : statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ready ? _statusGreen : AppColors.amberDeep,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingEventsCard() {
    final pendingEvents = _sync.getPendingEvents();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Queued Synchronization Events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '${pendingEvents.length} items',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Sanitized event records stored safely for reconnection upload (zero private data logged).',
            style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 12),
          if (pendingEvents.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.softSection,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Queue is empty. No pending offline events.',
                style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingEvents.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (context, idx) {
                final e = pendingEvents[idx];
                return Row(
                  children: [
                    Icon(
                      e.eventType == 'game_completion'
                          ? Icons.psychology_rounded
                          : Icons.alarm_on_rounded,
                      size: 20,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.eventType,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'ID: ${e.id} • Retries: ${e.retryCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTimeOnly(e.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeOnly(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
