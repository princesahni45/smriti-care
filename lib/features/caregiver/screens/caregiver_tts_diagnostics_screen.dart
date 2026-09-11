// lib/features/caregiver/screens/caregiver_tts_diagnostics_screen.dart
//
// Caregiver & Developer On-Device Text-To-Speech (TTS) Diagnostics Screen.
//
// Displays:
// 1. Available languages (English, Hindi, Assamese).
// 2. Selected voice and engine metadata.
// 3. Offline capability status.
// 4. Adjustable speech rate slider (0.5x - 1.0x).
// 5. Separate interactive tests for English, Hindi, and Assamese.
// 6. Transparent error reporting when Assamese voice is missing on device.
// 7. Safety guardrail test demonstrating medication dosage blocking.

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/tts/text_to_speech_service.dart';
import '../../../services/tts/local_text_to_speech_service.dart';
import '../../../services/tts/tts_models.dart';

class CaregiverTtsDiagnosticsScreen extends StatefulWidget {
  final TextToSpeechService? ttsService;

  const CaregiverTtsDiagnosticsScreen({
    super.key,
    this.ttsService,
  });

  @override
  State<CaregiverTtsDiagnosticsScreen> createState() =>
      _CaregiverTtsDiagnosticsScreenState();
}

class _CaregiverTtsDiagnosticsScreenState
    extends State<CaregiverTtsDiagnosticsScreen> {
  late TextToSpeechService _tts;
  String _selectedLang = 'en';
  double _speechRate = 0.75;
  TTSLanguageSupport? _currentSupport;
  String? _lastTestStatus;
  String? _lastErrorMessage;
  bool _guardrailTriggered = false;

  static const Map<String, String> _samplePhrases = {
    'en': 'Hello Ramesh. It is time for your afternoon relaxation exercise.',
    'hi': 'नमस्ते रमेश जी। यह आपके दोपहर के विश्राम का समय है।',
    'as': 'নমস্কাৰ ৰমেশ ডাঙৰীয়া। এইটো আপোনাৰ জিৰণিৰ সময়।',
  };

  @override
  void initState() {
    super.initState();
    _tts = widget.ttsService ?? LocalTextToSpeechService.instance;
    _speechRate = _tts.currentRate;
    _refreshDiagnostics();
  }

  Future<void> _refreshDiagnostics() async {
    await _tts.initialize();
    final support = await _tts.checkLanguageSupport(_selectedLang);

    if (mounted) {
      setState(() {
        _currentSupport = support;
      });
    }
  }

  Future<void> _changeLanguage(String code) async {
    setState(() {
      _selectedLang = code;
      _lastTestStatus = null;
      _lastErrorMessage = null;
      _guardrailTriggered = false;
    });

    final support = await _tts.checkLanguageSupport(code);
    if (mounted) {
      setState(() {
        _currentSupport = support;
      });
    }
  }

  Future<void> _testSpeech(String text) async {
    setState(() {
      _lastTestStatus = 'Synthesizing audio on device...';
      _lastErrorMessage = null;
      _guardrailTriggered = false;
    });

    try {
      final ok = await _tts.speak(
        text: text,
        languageCode: _selectedLang,
        rate: _speechRate,
      );

      if (mounted) {
        setState(() {
          if (ok) {
            _lastTestStatus = 'Speech playback initiated successfully.';
          } else {
            _lastTestStatus = 'Speech output unavailable.';
            _lastErrorMessage = _currentSupport?.details ??
                'Device voice engine failed to speak.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastTestStatus = 'Execution halted.';
          _lastErrorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _testMedicationGuardrail() async {
    setState(() {
      _lastTestStatus = 'Testing medication safety filter...';
      _lastErrorMessage = null;
      _guardrailTriggered = false;
    });

    try {
      // Intentionally attempts to speak medication dosage instruction
      await _tts.speak(
        text: 'Take 50mg of Atenolol right now and double your medicine.',
        languageCode: 'en',
      );

      if (mounted) {
        setState(() {
          _lastTestStatus = 'ERROR: Safety guardrail failed to block dosage!';
        });
      }
    } on TTSSafetyViolationException catch (e) {
      if (mounted) {
        setState(() {
          _guardrailTriggered = true;
          _lastTestStatus =
              'SAFETY GUARDRAIL ACTIVE: Blocked medication dosage speech.';
          _lastErrorMessage = e.reason;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastErrorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'On-Device TTS Diagnostics',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Target Hardware & Zero Cloud Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.teal),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded,
                      color: AppColors.tealDark, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Zero Cloud Transmission: Speech audio is synthesized locally using device engines without remote servers.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tealDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Language Selector Card
            _buildLanguageSelectorCard(),
            const SizedBox(height: 16),

            // Language Status & Engine Telemetry Card
            _buildStatusCard(),
            const SizedBox(height: 16),

            // Speech Cadence / Rate Slider Card
            _buildCadenceCard(),
            const SizedBox(height: 16),

            // Speech Synthesis Testing Section
            _buildTestingCard(),
            const SizedBox(height: 16),

            // Safety Guardrail Test Card
            _buildSafetyTestCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelectorCard() {
    return Container(
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
            'Target Synthesis Language',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLangChip('en', 'English', 'English'),
              _buildLangChip('hi', 'Hindi', 'हिन्दी'),
              _buildLangChip('as', 'Assamese', 'অসমীয়া'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLangChip(String code, String name, String native) {
    final isSelected = _selectedLang == code;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          key: Key('tts_lang_chip_$code'),
          label: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  native,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.ink,
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          selected: isSelected,
          selectedColor: AppColors.teal,
          backgroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(vertical: 8),
          onSelected: (val) {
            if (val) _changeLanguage(code);
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final support = _currentSupport;
    final isWorking = support?.isWorking ?? false;
    final isUnavailable = support?.isUnavailable ?? false;

    Color badgeColor = isWorking ? AppColors.teal : AppColors.coral;
    if (support?.status == TTSLanguageSupportStatus.partiallyWorking) {
      badgeColor = AppColors.amber;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                'Engine Status & Voice Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  support?.status.name.toUpperCase() ?? 'CHECKING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            support?.statusLabel ?? 'Querying device voice registry...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
          if (support?.details != null) ...[
            const SizedBox(height: 6),
            Text(
              support!.details!,
              style: TextStyle(
                fontSize: 12,
                color: isUnavailable ? AppColors.coralDeep : AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Divider(height: 24),
          Row(
            children: [
              _buildMetricTile(
                label: 'Selected Voice',
                value: support?.selectedVoice?.name ?? 'None',
              ),
              _buildMetricTile(
                label: 'Voice Count',
                value: '${support?.availableVoicesCount ?? 0} local',
              ),
              _buildMetricTile(
                label: 'Offline Engine',
                value: support?.offlineCapable == true
                    ? 'Strictly Local'
                    : 'Cloud / None',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({required String label, required String value}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCadenceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                'Elderly Speech Cadence',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '${(_speechRate * 100).toInt()}% speed (${_speechRate.toStringAsFixed(2)}x)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.tealDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Recommended calm pace for elderly listeners: 0.70x to 0.85x.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Slider(
            value: _speechRate,
            min: 0.5,
            max: 1.0,
            divisions: 10,
            activeColor: AppColors.teal,
            inactiveColor: AppColors.borderLight,
            onChanged: (val) {
              setState(() => _speechRate = val);
              _tts.setSpeechRate(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTestingCard() {
    final phrase = _samplePhrases[_selectedLang] ?? _samplePhrases['en']!;

    return Container(
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
            'Test Speech Synthesis',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Synthesizes sample phrase through local hardware speaker:',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              '"$phrase"',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentSupport?.isUnavailable == true
                      ? null
                      : () => _testSpeech(phrase),
                  icon:
                      const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: const Text('Play Sample Audio',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _tts.stop(),
                icon: const Icon(Icons.stop_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          if (_lastTestStatus != null) ...[
            const SizedBox(height: 10),
            Text(
              _lastTestStatus!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _guardrailTriggered ? AppColors.tealDark : AppColors.ink,
              ),
            ),
          ],
          if (_lastErrorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              _lastErrorMessage!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.coralDeep,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSafetyTestCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.violetPale,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.violetDeep.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security_rounded,
                  color: AppColors.violetDeep, size: 20),
              SizedBox(width: 8),
              Text(
                'Safety Guardrail Verification',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.violetDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Tests that LLM-generated medication dosage changes are intercepted and strictly blocked before reaching speech synthesis.',
            style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _testMedicationGuardrail,
            icon: const Icon(Icons.shield_outlined,
                color: AppColors.violetDeep, size: 20),
            label: const Text(
              'Test Medication Dosage Interception',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.violetDeep,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              side: const BorderSide(color: AppColors.violetDeep, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
