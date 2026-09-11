// lib/features/patient/patient_dashboard_screen.dart
//
// Elder-friendly, highly accessible patient dashboard.
// Designed with the 8 Core Dementia UI Accessibility Rules:
// 1. Larger icons (48-72px icons for primary actions).
// 2. Large visual cards with short, readable labels.
// 3. Drastically reduced text (zero paragraphs or medical jargon).
// 4. One clear action per card.
// 5. Reduced choices and strong visual hierarchy.
// 6. Zero swipe gestures or multi-touch requirements.
// 7. High contrast palette with minimum 48x48 touch targets.
// 8. Full offline functionality & multilingual support.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/user_model.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/caregiver_service.dart';
import '../../core/services/step_counter_service.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/smriti_button.dart';
import '../../widgets/sos_button.dart';
import 'widgets/daily_steps_card.dart';
import 'widgets/patient_cognitive_performance_card.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  // Medication reminder state
  bool _reminderAcknowledged = false;

  @override
  void initState() {
    super.initState();
    final patient = CaregiverService.instance.getPatientProfile();
    StepCounterService.instance.init(patientId: patient.id);
  }

  // ── Greeting helpers with multilingual support
  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return context.tr('patient.greetingMorning', defaultText: 'Good Morning');
    }
    if (hour >= 12 && hour < 17) {
      return context.tr('patient.greetingAfternoon', defaultText: 'Good Afternoon');
    }
    if (hour >= 17 && hour < 21) {
      return context.tr('patient.greetingEvening', defaultText: 'Good Evening');
    }
    return context.tr('patient.greetingNight', defaultText: 'Good Night');
  }

  String _getLocalDate(BuildContext context) {
    final now = DateTime.now();
    const weekdayKeys = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
    ];
    const monthKeys = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    final weekdayName = context.tr('dates.${weekdayKeys[now.weekday - 1]}', defaultText: 'Today');
    final monthName = context.tr('dates.${monthKeys[now.month - 1]}', defaultText: '');
    return '$weekdayName, $monthName ${now.day}';
  }

  void _handleActionTap(String actionId) {
    switch (actionId) {
      case 'games':
      case 'brain-games':
        context.push('/games');
        break;
      case 'home':
      case 'take-me-home':
        context.push('/take-me-home');
        break;
      case 'family':
      case 'family-memories':
        context.push('/games/family-memories');
        break;
      case 'routine':
      case 'routine-sequence':
        context.push('/games/routine');
        break;
      case 'memory-match':
        context.push('/games/memory-match');
        break;
      case 'word-recall':
        context.push('/games/word-recall');
        break;
      case 'different-object':
        context.push('/games/different-object');
        break;
      case 'orientation':
        context.push('/games/orientation');
        break;
      case 'emergency':
      case 'sos':
        context.push('/take-me-home');
        break;
      case 'profile':
      case 'patient-profile':
        context.push('/patient-profile');
        break;
      default:
        context.push('/games');
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await _showLogoutConfirmDialog();
    if (confirmed == true && mounted) {
      final pinOk = await _showCaregiverPinDialog();
      if (pinOk == true && mounted) {
        context.go('/role-select');
      }
    }
  }

  Future<bool?> _showLogoutConfirmDialog() => showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          contentPadding: const EdgeInsets.all(28),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.coralPale,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.logout_rounded, color: AppColors.coralDeep, size: 32),
              ),
              const SizedBox(height: 18),
              Text(
                context.tr('patient.logoutConfirmTitle', defaultText: 'Leave Session?'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('patient.logoutConfirmBody', defaultText: 'Do you want to leave the patient dashboard?'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SmritiButton(
                      label: context.tr('patient.goBack', defaultText: 'Stay Here'),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SmritiButton.secondary(
                      label: context.tr('patient.confirmLogout', defaultText: 'Exit'),
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Future<bool?> _showCaregiverPinDialog() {
    final pinController = TextEditingController();
    String? pinError;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.shield_rounded, color: AppColors.teal, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('patient.pinTitle', defaultText: 'Caregiver Check'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('patient.enterPinToEnd', defaultText: 'Enter 4-digit caregiver PIN (1234) to exit.'),
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 14,
                ),
                decoration: InputDecoration(
                  hintText: '••••',
                  counterText: '',
                  errorText: pinError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.teal, width: 2),
                  ),
                ),
                onChanged: (_) => setStateDlg(() => pinError = null),
              ),
              const SizedBox(height: 18),
              _PinKeypad(
                onKey: (v) => setStateDlg(() {
                  pinError = null;
                  if (v == 'clear') {
                    pinController.clear();
                  } else if (v == 'back') {
                    final t = pinController.text;
                    if (t.isNotEmpty) pinController.text = t.substring(0, t.length - 1);
                  } else if (pinController.text.length < 4) {
                    pinController.text += v;
                  }
                }),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SmritiButton(
                      label: context.tr('patient.pinSubmit', defaultText: 'Submit'),
                      onPressed: () {
                        final result = AuthService.validateCaregiverPin(pinController.text);
                        if (result.success) {
                          Navigator.pop(ctx, true);
                        } else {
                          setStateDlg(() => pinError = result.error);
                          pinController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SmritiButton.secondary(
                      label: context.tr('patient.pinCancel', defaultText: 'Cancel'),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientProfile = CaregiverService.instance.getPatientProfile();
    final patientName = patientProfile.fullName.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ══════════ Sticky Header ══════════
          _PatientHeader(onLogout: _handleLogout),

          // ══════════ Scrollable Content ══════════
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting & Date (Large, Calm, Friendly)
                  Text(
                    '${_getGreeting(context)}, $patientName!',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getLocalDate(context),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── High-Priority Medication / Reminder Card (Rule 3 & 5)
                  _buildMedicationReminderCard(),

                  const SizedBox(height: 16),
                  const DailyStepsCard(),

                  const SizedBox(height: 16),
                  // FIX: Save real cognitive score after game completion & show in Patient Dashboard
                  const PatientCognitivePerformanceCard(),

                  const SizedBox(height: 24),

                  // ── Section Title
                  const Text(
                    'What would you like to do?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── 4 Primary Visual Action Cards (Rule 1, 2, 4, 5)
                  // 1. Play Games
                  _LargeActionCard(
                    icon: Icons.sports_esports_rounded,
                    title: 'Play',
                    subtitle: 'Brain & Memory Games',
                    color: AppColors.teal,
                    bgColor: AppColors.tealPale,
                    onTap: () => _handleActionTap('games'),
                  ),
                  const SizedBox(height: 14),

                  // 2. Take Me Home
                  _LargeActionCard(
                    icon: Icons.home_rounded,
                    title: 'Take Me Home',
                    subtitle: 'Safe Guide to Home',
                    color: AppColors.blueDeep,
                    bgColor: AppColors.bluePale,
                    onTap: () => _handleActionTap('home'),
                  ),
                  const SizedBox(height: 14),

                  // 3. Family Memories
                  _LargeActionCard(
                    icon: Icons.family_restroom_rounded,
                    title: 'Family',
                    subtitle: 'Faces & Photos',
                    color: AppColors.violetDeep,
                    bgColor: AppColors.violetPale,
                    onTap: () => _handleActionTap('family'),
                  ),
                  const SizedBox(height: 14),

                  // 4. Daily Routine
                  _LargeActionCard(
                    icon: Icons.checklist_rounded,
                    title: 'Daily Routine',
                    subtitle: 'Steps for Today',
                    color: AppColors.amberDeep,
                    bgColor: AppColors.amberPale,
                    onTap: () => _handleActionTap('routine'),
                  ),

                  const SizedBox(height: 24),

                  // ── Prominent Emergency SOS Button (Rule 1 & 8)
                  const SosButton(),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── High-Priority Reminder Card ───────────────────────────────────────────

  Widget _buildMedicationReminderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _reminderAcknowledged ? AppColors.softSection : AppColors.amberPale.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _reminderAcknowledged ? AppColors.borderLight : AppColors.amberDeep.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 48px Medication Icon
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _reminderAcknowledged ? AppColors.border : AppColors.amberDeep,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.medication_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _reminderAcknowledged ? 'Medicine Taken ✓' : 'Medicine — 10:00 AM',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _reminderAcknowledged ? AppColors.muted : AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _reminderAcknowledged
                      ? 'Acknowledged for today'
                      : 'Take with a glass of water',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (!_reminderAcknowledged)
            ElevatedButton(
              onPressed: () {
                setState(() => _reminderAcknowledged = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Great job! Medicine marked as taken.'),
                      ],
                    ),
                    backgroundColor: AppColors.tealDark,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amberDeep,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Large Visual Action Card (Rule 1, 2, 4 — 64px Icon, One Action, No Jargon)
// ═════════════════════════════════════════════════════════════════════════════

class _LargeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _LargeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Large 64px visual icon container
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 38,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Sticky Header with large touch targets
// ═════════════════════════════════════════════════════════════════════════════

class _PatientHeader extends StatelessWidget {
  final VoidCallback onLogout;
  const _PatientHeader({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(bottom: BorderSide(color: AppColors.border, width: 2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const AppLogo(iconSize: 32, fontSize: 20),
            const Spacer(),
            _CtrlBtn(
              icon: Icons.account_circle_rounded,
              label: context.tr('common.profile', defaultText: 'Profile'),
              onTap: () => context.push('/patient-profile'),
              color: AppColors.teal,
            ),
            _CtrlBtn(
              icon: Icons.phone_rounded,
              label: context.tr('common.help', defaultText: 'Help'),
              onTap: () => context.push('/take-me-home'),
              color: AppColors.coralDeep,
            ),
            _CtrlBtn(
              icon: Icons.language_rounded,
              label: context.tr('common.language', defaultText: 'Lang'),
              onTap: () => context.push('/language-select'),
            ),
            const SizedBox(width: 4),
            // Caregiver exit gate
            GestureDetector(
              onTap: onLogout,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.coralPale,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.coralDeep),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('common.logout', defaultText: 'Exit'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.coralDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _CtrlBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.inkSoft;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26, color: c),
              Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Keypad for Caregiver PIN Verification
// ═════════════════════════════════════════════════════════════════════════════

class _PinKeypad extends StatelessWidget {
  final void Function(String) onKey;
  const _PinKeypad({required this.onKey});

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['clear', '0', 'back'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((k) {
              Widget child;
              if (k == 'clear') {
                child = const Text(
                  'C',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.coralDeep),
                );
              } else if (k == 'back') {
                child = const Icon(Icons.backspace_outlined, size: 20, color: AppColors.inkSoft);
              } else {
                child = Text(
                  k,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 64,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => onKey(k),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: AppColors.surface,
                    ),
                    child: child,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
