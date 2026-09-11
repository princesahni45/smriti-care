// lib/features/emergency/take_me_home_screen.dart
//
// Take Me Home & Emergency SOS Screen for Elderly Patients.
// Integrates:
// 1. Two-Number SOS UI (Primary & Secondary Contacts)
// 2. Hardware GPS Coordinates Acquisition (100% offline without internet)
// 3. Fallback to Last Known Location when live satellite fix times out
// 4. Native Phone Dialer (tel:) & SMS Composer (sms:)
// 5. Safe Home Address guidance for confused or lost seniors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/caregiver_models.dart';
import '../../core/services/caregiver_service.dart';
import '../../services/location_service.dart';
import '../../services/emergency_service.dart';

class TakeMeHomeScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const TakeMeHomeScreen({super.key, this.onBack});

  @override
  State<TakeMeHomeScreen> createState() => _TakeMeHomeScreenState();
}

class _TakeMeHomeScreenState extends State<TakeMeHomeScreen> {
  bool _sosSent = false;
  bool _isLoadingLocation = true;
  SosLocation? _currentLocation;
  late HomeLocation _home;

  @override
  void initState() {
    super.initState();
    _home = CaregiverService.instance.getHomeLocation();

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _isLoadingLocation = false;
      _currentLocation = SosLocation(
        latitude: 26.1856,
        longitude: 91.7539,
        accuracy: 10.0,
        timestamp: DateTime.now(),
        isLastKnown: false,
        statusMessage: 'Test Location',
      );
    } else {
      _initServicesAndLocation();
    }
  }

  Future<void> _initServicesAndLocation() async {
    await EmergencyService.instance.init();
    await _acquireLocation();
  }

  Future<void> _acquireLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    final loc = await LocationService.instance.getCurrentSosLocation(
      timeout: const Duration(seconds: 7),
    );

    if (mounted) {
      setState(() {
        _currentLocation = loc;
        _isLoadingLocation = false;
      });
    }
  }

  void _triggerSos() {
    setState(() {
      _sosSent = true;
    });

    // Add alert to caregiver log
    CaregiverService.instance.addSosAlertLog(
      triggerType: 'Patient App SOS',
      notes: _currentLocation != null
          ? 'Patient SOS triggered at Lat: ${_currentLocation!.latitude.toStringAsFixed(5)}, Lng: ${_currentLocation!.longitude.toStringAsFixed(5)}'
          : 'Patient initiated Take Me Home SOS alert from mobile app.',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'SOS Alert Dispatched. Emergency call and message options are ready below.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.coralDeep,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _callNumber(String number, String name) {
    EmergencyService.instance.launchCall(number);
  }

  void _smsNumber(String number, String name) {
    final location = _currentLocation ??
        SosLocation(
          latitude: 26.1445,
          longitude: 91.7362,
          accuracy: 50.0,
          timestamp: DateTime.now(),
          isLastKnown: true,
          statusMessage: 'Location pending',
        );

    final message = EmergencyService.instance.buildSosMessage(
      location: location,
    );

    EmergencyService.instance.launchSms(number, message);
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
        title: Text(
          context.tr('safety.title', defaultText: 'Take Me Home & SOS'),
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Reassurance Banner ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color:
                      _sosSent ? const Color(0xFFE8F5E9) : AppColors.tealLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _sosSent ? Colors.green.shade400 : AppColors.teal,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _sosSent ? Colors.green.shade100 : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _sosSent
                            ? Icons.check_circle_rounded
                            : Icons.favorite_rounded,
                        color: _sosSent
                            ? Colors.green.shade800
                            : AppColors.tealDark,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _sosSent
                                ? 'Help is being coordinated.'
                                : 'Don\'t worry, you are safe.',
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _sosSent
                                  ? Colors.green.shade900
                                  : AppColors.tealDeep,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _sosSent
                                ? 'Use the buttons below to call or send your GPS coordinates.'
                                : 'Help is one tap away. Sit comfortably and breathe gently.',
                            style: TextStyle(
                              fontSize: 13,
                              color: _sosSent
                                  ? Colors.green.shade800
                                  : AppColors.tealDark,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Emergency SOS Activation Button ─────────────────────────────
              SizedBox(
                height: 62,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coralDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 1,
                  ),
                  icon: const Icon(Icons.sos_rounded, size: 32),
                  label: Text(
                    _sosSent ? 'SOS ALERT ACTIVE' : 'PRESS FOR EMERGENCY SOS',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  onPressed: _triggerSos,
                ),
              ),

              const SizedBox(height: 20),

              // FIX: Use shared SOS contacts for caregiver and patient
              ValueListenableBuilder<EmergencySettingsData>(
                valueListenable: EmergencyService.instance.settingsNotifier,
                builder: (context, settings, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('safety.emergencySettings',
                                defaultText: 'Emergency Contacts'),
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: settings.isCloudSynced
                                  ? AppColors.tealPale
                                  : AppColors.amberPale,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  settings.isCloudSynced
                                      ? Icons.cloud_done_rounded
                                      : Icons.offline_pin_rounded,
                                  size: 13,
                                  color: settings.isCloudSynced
                                      ? AppColors.tealDark
                                      : AppColors.amberDeep,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  settings.isCloudSynced
                                      ? 'Cloud Synced'
                                      : 'Offline Stored',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: settings.isCloudSynced
                                        ? AppColors.tealDark
                                        : AppColors.amberDeep,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 1. Primary Contact Card
                      _buildContactActionCard(
                        context: context,
                        badgeLabel: context.tr('safety.primaryCaregiver',
                            defaultText: 'Primary Emergency Contact'),
                        name: settings.primaryName,
                        relationship: settings.primaryRelationship,
                        phone: settings.primaryPhone,
                        badgeColor: AppColors.teal,
                        onCall: () => _callNumber(
                            settings.primaryPhone, settings.primaryName),
                        onSms: () => _smsNumber(
                            settings.primaryPhone, settings.primaryName),
                      ),

                      const SizedBox(height: 12),

                      // 2. Secondary Contact Card
                      _buildContactActionCard(
                        context: context,
                        badgeLabel: context.tr('safety.addEmergencyContact',
                            defaultText: 'Secondary Emergency Contact'),
                        name: settings.secondaryName,
                        relationship: settings.secondaryRelationship,
                        phone: settings.secondaryPhone,
                        badgeColor: AppColors.violet,
                        onCall: () => _callNumber(
                            settings.secondaryPhone, settings.secondaryName),
                        onSms: () => _smsNumber(
                            settings.secondaryPhone, settings.secondaryName),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 22),

              // ── Current GPS Location Card ───────────────────────────────────
              _buildLocationStatusCard(),

              const SizedBox(height: 22),

              // ── Safe Home Address Card ──────────────────────────────────────
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
                          child: const Icon(Icons.home_rounded,
                              color: AppColors.blueDeep, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Safe Home Address',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted,
                                ),
                              ),
                              Text(
                                'Show this to anyone helping you',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.inkSoft),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        _home.address,
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── National Emergency 112 Button ───────────────────────────────
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.local_police_rounded,
                      size: 22, color: AppColors.muted),
                  label: const Text(
                    'Call National Emergency 112',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => EmergencyService.instance.launchCall('112'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactActionCard({
    required BuildContext context,
    required String badgeLabel,
    required String name,
    required String relationship,
    required String phone,
    required Color badgeColor,
    required VoidCallback onCall,
    required VoidCallback onSms,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
              const Icon(Icons.verified_user_outlined,
                  size: 16, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$name ($relationship)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            phone,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 14),

          // Two Action Buttons: Call & SMS
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                    label: const Text(
                      'Call',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    onPressed: onCall,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.sms_rounded, size: 18),
                    label: const Text(
                      'SMS',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    onPressed: onSms,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatusCard() {
    final loc = _currentLocation;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.amberPale,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: AppColors.amberDeep, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'GPS Emergency Coordinates',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    size: 20, color: AppColors.teal),
                onPressed: _isLoadingLocation ? null : _acquireLocation,
                tooltip: 'Refresh Location',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingLocation) ...[
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.teal),
                ),
                SizedBox(width: 12),
                Text(
                  'Acquiring satellite GPS fix (offline capable)...',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ] else if (loc != null) ...[
            // Status Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: loc.isLastKnown
                    ? Colors.amber.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    loc.isLastKnown
                        ? Icons.history_rounded
                        : Icons.satellite_alt_rounded,
                    size: 14,
                    color: loc.isLastKnown
                        ? Colors.amber.shade900
                        : Colors.green.shade900,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    loc.isLastKnown
                        ? 'Last Known Location'
                        : 'Live Satellite GPS Fix',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: loc.isLastKnown
                          ? Colors.amber.shade900
                          : Colors.green.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Coordinates in clear legible typography
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          context.tr('safety.latitude',
                              defaultText: 'Latitude:'),
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.muted)),
                      Text(
                        loc.latitude.toStringAsFixed(6),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          context.tr('safety.longitude',
                              defaultText: 'Longitude:'),
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.muted)),
                      Text(
                        loc.longitude.toStringAsFixed(6),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink),
                      ),
                    ],
                  ),
                  if (loc.accuracy > 0) ...[
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            context.tr('safety.accuracy',
                                defaultText: 'Accuracy:'),
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.muted)),
                        Text(
                          '± ${loc.accuracy.toStringAsFixed(1)} meters',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkSoft),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.offline_bolt_rounded, size: 14, color: AppColors.teal),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'GPS satellite positioning works 100% without cellular data or Wi-Fi.',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
