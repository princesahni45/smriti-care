// lib/features/patient/patient_dashboard_screen.dart
//
// Elder-friendly patient dashboard.
// Faithfully mirrors the React PatientDashboard component:
//   - Sticky header with Home / Help / Voice / Language controls
//   - Time-based greeting + date
//   - Progress bar (1 of 3 activities)
//   - 4-card activity grid
//   - "Today's Activity" featured panel
//   - Logout confirmation + Caregiver PIN flow

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/user_model.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/smriti_button.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final _patient = PatientUser.prototype();

  // ── Greeting helpers (from React getTimeGreeting() and getLocalDate())
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5  && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  String get _localDate {
    final now = DateTime.now();
    const weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months   = ['January','February','March','April','May','June',
                      'July','August','September','October','November','December'];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  // Progress: 1 of 3 activities completed (mock data)
  final int _completedCount       = 1;
  final int _totalTodayActivities = 3;

  void _handleActivityTap(String activityId) {
    if (activityId == 'brain-games' || activityId == 'games') {
      context.go('/games');
    } else if (activityId == 'memory-match') {
      context.go('/games/memory-match');
    } else if (activityId == 'memory-activity' || activityId == 'word-recall') {
      context.go('/games/word-recall');
    } else if (activityId == 'different-object') {
      context.go('/games/different-object');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$activityId — coming soon in future updates.'),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.coralPale, borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.logout_rounded, color: AppColors.coralDeep, size: 28),
          ),
          const SizedBox(height: 16),
          Text('Are you sure?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(
            'Do you want to leave the patient dashboard?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // "Go Back" — default safe action (primary)
              Expanded(
                child: SmritiButton(
                  label: 'Go Back',
                  onPressed: () => Navigator.pop(ctx, false),
                ),
              ),
              const SizedBox(width: 12),
              // "Continue" — subtle secondary
              Expanded(
                child: SmritiButton.secondary(
                  label: 'Continue',
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
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.tealLight, borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.shield_rounded, color: AppColors.teal, size: 28),
              ),
              const SizedBox(height: 14),
              Text('Caregiver Authorization',
                  style: Theme.of(ctx).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Enter caregiver PIN to end this session.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              // ── PIN Input
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 8,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 12,
                ),
                decoration: InputDecoration(
                  hintText: '••••',
                  counterText: '',
                  errorText: pinError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.teal, width: 2),
                  ),
                ),
                onChanged: (_) => setStateDlg(() => pinError = null),
              ),
              const SizedBox(height: 18),
              // ── Numeric keypad (matching React caregiver-pin-keypad)
              _PinKeypad(
                onKey: (v) => setStateDlg(() {
                  pinError = null;
                  if (v == 'clear') {
                    pinController.clear();
                  } else if (v == 'back') {
                    final t = pinController.text;
                    if (t.isNotEmpty) pinController.text = t.substring(0, t.length - 1);
                  } else if (pinController.text.length < 8) {
                    pinController.text += v;
                  }
                }),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SmritiButton(
                      label: 'Submit',
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
                      label: 'Cancel',
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
    final progressPercent = _completedCount / _totalTodayActivities;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ══════════ Sticky Header (pd-header) ══════════
          _PatientHeader(onLogout: _handleLogout),

          // ══════════ Scrollable content ══════════
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting + date
                  Text(
                    '$_greeting, ${_patient.displayName}!',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _localDate,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Today's progress bar
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today's Progress",
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              '$_completedCount of $_totalTodayActivities completed',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.teal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            backgroundColor: AppColors.tealLight,
                            valueColor: const AlwaysStoppedAnimation(AppColors.teal),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Activity grid title
                  Text('Activities', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),

                  // ── 2×2 activity grid (from ACTIVITY_CARDS)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.15,
                    children: AppConstants.activityCards.map((act) {
                      return _ActivityCard(
                        title: act['title']!,
                        subtitle: act['subtitle']!,
                        colorKey: act['color']!,
                        onTap: () => _handleActivityTap(act['id']!),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Today's featured activity panel
                  _TodayActivityPanel(onTap: () => _handleActivityTap('memory-match')),
                  const SizedBox(height: 24),

                  // ── Help / SOS card
                  _HelpCard(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Sticky Header
// ══════════════════════════════════════════════════
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
          border: Border(bottom: BorderSide(color: AppColors.border, width: 2.5)),
          boxShadow: [BoxShadow(color: AppColors.teal.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const AppLogo(iconSize: 32, fontSize: 20),
            const Spacer(),
            // ── Control buttons (Home / Help / Voice / Lang) — matching pd-controls
            _CtrlBtn(icon: Icons.home_rounded,        label: 'Home',  onTap: () {}),
            _CtrlBtn(icon: Icons.phone_rounded,        label: 'Help',  onTap: () {}, color: AppColors.coralDeep),
            _CtrlBtn(icon: Icons.mic_rounded,          label: 'Voice', onTap: () {}),
            _CtrlBtn(icon: Icons.language_rounded,     label: 'Lang',  onTap: () {}),
            const SizedBox(width: 4),
            // ── Logout
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
                    const Icon(Icons.logout_rounded, size: 16, color: AppColors.coralDeep),
                    const SizedBox(width: 4),
                    Text('Exit', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.coralDeep,
                    )),
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
  const _CtrlBtn({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.tealDark;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26, color: c),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Activity Card
// ══════════════════════════════════════════════════
class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String colorKey;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.colorKey,
    required this.onTap,
  });

  ({Color bg, Color fg, IconData icon}) get _style {
    switch (colorKey) {
      case 'blue':   return (bg: AppColors.bluePale,   fg: AppColors.blueDeep,   icon: Icons.sports_esports_rounded);
      case 'teal':   return (bg: AppColors.tealLight,  fg: AppColors.tealDark,   icon: Icons.psychology_rounded);
      case 'violet': return (bg: AppColors.violetPale, fg: AppColors.violetDeep, icon: Icons.music_note_rounded);
      case 'coral':  return (bg: AppColors.coralPale,  fg: AppColors.coralDeep,  icon: Icons.record_voice_over_rounded);
      default:       return (bg: AppColors.tealLight,  fg: AppColors.tealDark,   icon: Icons.star_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: s.bg, borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(s.icon, color: s.fg, size: 22),
              ),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Today's Featured Activity Panel
// ══════════════════════════════════════════════════
class _TodayActivityPanel extends StatelessWidget {
  final VoidCallback onTap;
  const _TodayActivityPanel({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E6B65), Color(0xFF157F7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "TODAY'S ACTIVITY",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    letterSpacing: 0.09,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.psychology_rounded, color: Colors.white70, size: 22),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Memory Match',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'A simple memory activity',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.80),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text('Start Activity'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.tealDark,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Help / SOS Card
// ══════════════════════════════════════════════════
class _HelpCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.coralPale,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.coral.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.map_rounded, color: AppColors.coralDeep, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lost or confused?', style: Theme.of(context).textTheme.titleSmall),
                Text('Take Me Home & SOS',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.coralDeep)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.coralDeep),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Numeric PIN keypad (matching React caregiver-pin-keypad)
// ══════════════════════════════════════════════════
class _PinKeypad extends StatelessWidget {
  final void Function(String) onKey;
  const _PinKeypad({required this.onKey});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: [
        ...['1','2','3','4','5','6','7','8','9'].map(
          (n) => _KeyBtn(label: n, onTap: () => onKey(n)),
        ),
        _KeyBtn(label: 'Clear', onTap: () => onKey('clear'), isUtil: true),
        _KeyBtn(label: '0',     onTap: () => onKey('0')),
        _KeyBtn(label: '⌫',    onTap: () => onKey('back'), isUtil: true),
      ],
    );
  }
}

class _KeyBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isUtil;
  const _KeyBtn({required this.label, required this.onTap, this.isUtil = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isUtil ? AppColors.softSection : AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isUtil ? 12 : 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
