// lib/core/voice/widgets/patient_voice_floating_button.dart
//
// Accessible, high-contrast, elderly-friendly floating Voice Assistant button.
// Features:
// - Large touch target (>= 56 pt height, >= 120 pt width)
// - High-contrast palette (Teal + White) matching SmritiCare theme
// - Unambiguous visible label and screen-reader accessibility
// - Stable, non-animated design to avoid confusing elderly users
// - Preserves active route context and automatically starts listening on tap

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../localization/app_localizations.dart';
import '../voice_route_tracker.dart';
import 'voice_assistant_modal.dart';

class PatientVoiceFloatingButton extends StatelessWidget {
  /// Override the bottom offset if explicitly specified; otherwise automatically
  /// calculated based on whether the active route has a BottomNavigationBar.
  final double? bottomOffset;

  /// Optional navigation callback when assistant triggers a route change.
  final void Function(String route, {Map<String, dynamic>? arguments})?
      onNavigate;

  const PatientVoiceFloatingButton({
    super.key,
    this.bottomOffset,
    this.onNavigate,
  });

  String _getLocalizedButtonLabel(BuildContext context, String lang) {
    return context.tr(
      'voice.buttonLabel',
      defaultText: lang == 'hi' ? 'बोलें' : (lang == 'as' ? 'কওক' : 'Voice'),
    );
  }

  String _getSemanticLabel(BuildContext context, String lang) {
    return context.tr(
      'voice.buttonSemantic',
      defaultText: lang == 'hi'
          ? 'वॉइस सहायक। बोलने के लिए टैप करें।'
          : (lang == 'as'
              ? 'ভইচ সহায়ক। ক’বলৈ টিপক।'
              : 'Voice Assistant. Tap to speak or give commands.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang =
        LocalizationService.instance.currentLocaleNotifier.value.languageCode;
    final tracker = VoiceRouteTracker.instance;
    final currentRoute = tracker.currentRoute;
    final safeArea = MediaQuery.of(context).padding;

    // Position above the BottomNavigationBar if on main shell screens, otherwise standard padding
    final defaultBottom = tracker.isShellScreenWithBottomNav ? 76.0 : 18.0;
    final effectiveBottom = (bottomOffset ?? defaultBottom) + safeArea.bottom;
    final effectiveRight = 16.0 + safeArea.right;

    return Positioned(
      right: effectiveRight,
      bottom: effectiveBottom,
      child: Semantics(
        button: true,
        label: _getSemanticLabel(context, lang),
        hint: 'Opens the voice assistant and starts listening',
        child: Material(
          color: Colors.transparent,
          elevation: 6,
          shadowColor: AppColors.tealDeep.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(32),
          child: InkWell(
            onTap: () {
              // Preserve current screen context and open assistant with auto-listen
              showVoiceAssistantModal(
                context: context,
                currentRoute: currentRoute,
                onNavigate: onNavigate,
              );
            },
            borderRadius: BorderRadius.circular(32),
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 56,
                  minWidth: 124,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getLocalizedButtonLabel(context, lang),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
