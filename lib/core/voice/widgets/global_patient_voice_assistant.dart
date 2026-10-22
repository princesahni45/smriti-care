import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../voice_route_tracker.dart';
import 'patient_voice_floating_button.dart';

class GlobalPatientVoiceAssistant extends StatelessWidget {
  final Widget? child;

  final void Function(String route, {Map<String, dynamic>? arguments})?
      onNavigate;

  final GlobalKey<NavigatorState>? navigatorKey;

  const GlobalPatientVoiceAssistant({
    super.key,
    this.child,
    this.onNavigate,
    this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        VoiceRouteTracker.instance,
        LocalizationService.instance.currentLocaleNotifier,
      ]),
      builder: (context, _) {
        final shouldShow =
            VoiceRouteTracker.instance.shouldShowFloatingButton;

        return Stack(
          alignment: Alignment.bottomRight,
          children: [
            if (child != null) child!,
            if (shouldShow)
              PatientVoiceFloatingButton(
                onNavigate: onNavigate,
                navigatorKey: navigatorKey,
              ),
          ],
        );
      },
    );
  }
}
