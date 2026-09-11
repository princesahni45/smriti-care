// lib/core/voice/widgets/global_patient_voice_assistant.dart
//
// Global wrapper widget that conditionally displays the PatientVoiceFloatingButton
// on all patient-facing screens, while strictly hiding it on caregiver/admin screens
// and during modal dialogs/bottom sheets.

import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../voice_route_tracker.dart';
import 'patient_voice_floating_button.dart';

class GlobalPatientVoiceAssistant extends StatelessWidget {
  /// The underlying page or Navigator widget.
  final Widget? child;

  /// Optional navigation callback for routing delegation.
  final void Function(String route, {Map<String, dynamic>? arguments})?
      onNavigate;

  const GlobalPatientVoiceAssistant({
    super.key,
    this.child,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        VoiceRouteTracker.instance,
        LocalizationService.instance.currentLocaleNotifier,
      ]),
      builder: (context, _) {
        final shouldShow = VoiceRouteTracker.instance.shouldShowFloatingButton;

        return Stack(
          alignment: Alignment.bottomRight,
          children: [
            if (child != null) child!,
            if (shouldShow)
              PatientVoiceFloatingButton(
                onNavigate: onNavigate,
              ),
          ],
        );
      },
    );
  }
}
