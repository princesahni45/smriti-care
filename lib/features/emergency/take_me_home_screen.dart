// lib/features/emergency/take_me_home_screen.dart
//
// Take Me Home & Emergency SOS Screen for Elderly Patients.
// Ports TakeMeHome.jsx with elderly-friendly accessible buttons and safe home guidance.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/caregiver_models.dart';
import '../../core/services/caregiver_service.dart';

class TakeMeHomeScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const TakeMeHomeScreen({super.key, this.onBack});

  @override
  State<TakeMeHomeScreen> createState() => _TakeMeHomeScreenState();
}

class _TakeMeHomeScreenState extends State<TakeMeHomeScreen> {
  bool _sosSent = false;
  late EmergencyContact _contact;
  late HomeLocation _home;

  @override
  void initState() {
    super.initState();
    _contact = CaregiverService.instance.getEmergencyContact();
    _home = CaregiverService.instance.getHomeLocation();
  }

  void _triggerSos() {
    setState(() {
      _sosSent = true;
    });

    // Add alert to caregiver log
    CaregiverService.instance.addSosAlertLog(
      triggerType: 'Patient App SOS',
      notes: 'Patient initiated Take Me Home SOS alert from mobile app.',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'SOS Alert Dispatched to Rahul Das. Help is being coordinated.',
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
          'Take Me Home & SOS',
          style: TextStyle(
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
              // Reassurance Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _sosSent ? const Color(0xFFE8F5E9) : AppColors.tealLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _sosSent ? Colors.green.shade400 : AppColors.teal,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _sosSent ? Colors.green.shade100 : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _sosSent
                            ? Icons.check_circle_rounded
                            : Icons.favorite_rounded,
                        color: _sosSent ? Colors.green.shade800 : AppColors.tealDark,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _sosSent ? 'You are safe.' : 'Don\'t worry, you are safe.',
                            style: GoogleFonts.dmSans(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: _sosSent
                                  ? Colors.green.shade900
                                  : AppColors.tealDeep,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _sosSent
                                ? '${_contact.name} has received your location and is on the way.'
                                : 'Help is just one touch away. Sit comfortably and breathe gently.',
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

              const SizedBox(height: 22),

              // Safe Home Address Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.borderLight, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
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
                              color: AppColors.blueDeep, size: 26),
                        ),
                        const SizedBox(width: 14),
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
                              SizedBox(height: 2),
                              Text(
                                'Show this to anyone helping you',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        _home.address,
                        style: GoogleFonts.dmSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Emergency Caregiver Call Button
              SizedBox(
                height: 64,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.phone_rounded, size: 28),
                  label: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Call ${_contact.name} (${_contact.relationship})',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        _contact.phone,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70),
                      ),
                    ],
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Dialing ${_contact.name} at ${_contact.phone}...'),
                        backgroundColor: AppColors.teal,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // Immediate SOS Emergency Trigger
              SizedBox(
                height: 64,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coralDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.sos_rounded, size: 34),
                  label: const Text(
                    'PRESS FOR EMERGENCY SOS',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  onPressed: _triggerSos,
                ),
              ),

              const SizedBox(height: 14),

              // Call 112 Button
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.local_police_rounded,
                      size: 24, color: AppColors.muted),
                  label: const Text(
                    'Call National Emergency 112',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Connecting to National Emergency 112...'),
                        backgroundColor: Colors.black87,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
