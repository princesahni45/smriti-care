// lib/features/caregiver/caregiver_dashboard_screen.dart
//
// Caregiver portal dashboard.
// Faithfully mirrors the React CaregiverDashboard component:
//   - Header: logo, language btn, notification bell, user avatar, logout
//   - Welcome + care overview section
//   - Patient banner: Mr. Ramesh Das, dementia level, location
//   - 4 stat cards (activity, cognitive score, medication, next appointment)
//   - Weekly engagement bar chart (mock data)
//   - Today's routine task list
//   - Health snapshot card
//   - Care insight card

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/app_logo.dart';


class CaregiverDashboardScreen extends StatelessWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ══════════ Sticky Header ══════════
          _CaregiverHeader(onLogout: () => context.go('/role-select')),

          // ══════════ Scrollable content ══════════
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Welcome section
                  _WelcomeSection(),
                  const SizedBox(height: 20),

                  // ── Patient banner
                  _PatientBanner(),
                  const SizedBox(height: 20),

                  // ── Stat cards grid
                  _StatGrid(),
                  const SizedBox(height: 20),

                  // ── Weekly engagement chart
                  _WeeklyChart(),
                  const SizedBox(height: 16),

                  // ── Today's routine + Health snapshot
                  _TwoColumnCards(),
                  const SizedBox(height: 16),

                  // ── Care insight card
                  _CareInsightCard(),
                  const SizedBox(height: 24),
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
// Header
// ══════════════════════════════════════════════════
class _CaregiverHeader extends StatelessWidget {
  final VoidCallback onLogout;
  const _CaregiverHeader({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.borderLight)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Logo + portal label
            const AppLogo(fontSize: 18, iconSize: 26),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Caregiver portal',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.tealDark),
              ),
            ),
            const Spacer(),
            // Language button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.tealBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.teal.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded, size: 16, color: AppColors.teal),
                  const SizedBox(width: 4),
                  Text('🌐 English', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.tealDark)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Notification bell
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.inkSoft),
                  onPressed: () {},
                  tooltip: 'Notifications',
                ),
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            // Avatar
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.teal, borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                AppConstants.caregiverInitials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            // Logout
            TextButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Logout'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.coralDeep,
                textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Welcome Section
// ══════════════════════════════════════════════════
class _WelcomeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CARE OVERVIEW',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.teal, letterSpacing: 0.09,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Good morning, Mohak.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                "Here's how Mr. Ramesh Das is doing today.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.tealLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.teal),
              const SizedBox(width: 6),
              Text(
                'Last updated today, 9:42 AM',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.tealDark, fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════
// Patient Banner
// ══════════════════════════════════════════════════
class _PatientBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.teal, borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Text('RD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          ),
          const SizedBox(width: 14),
          // Patient info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR PATIENT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.muted)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.titleLarge,
                    children: const [
                      TextSpan(text: 'Mr. Ramesh Das  '),
                      TextSpan(
                        text: '72 years',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      'Guwahati, Assam  •  Patient ID: MC-2048',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Dementia risk chip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amberPale,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.amber.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text('DEMENTIA LEVEL',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.amberDeep)),
                const SizedBox(height: 4),
                Text('Moderate', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.amberDeep)),
                Text('Needs regular support',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.amber)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Stat Cards Grid (2×2)
// ══════════════════════════════════════════════════
class _StatGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stats = [
      (label: "Today's activity", value: '42 min',    icon: Icons.access_time_rounded,  bg: AppColors.tealLight,  fg: AppColors.tealDark),
      (label: 'Cognitive score',  value: '72 / 100',  icon: Icons.trending_up_rounded,  bg: AppColors.violetPale, fg: AppColors.violetDeep),
      (label: 'Medication',       value: '2 of 3 taken', icon: Icons.medication_rounded, bg: AppColors.coralPale, fg: AppColors.coralDeep),
      (label: 'Next appointment', value: '12 Sep',    icon: Icons.calendar_today_rounded, bg: AppColors.bluePale, fg: AppColors.blueDeep),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 2.0,
      children: stats.map((s) => _StatCard(
        label: s.label,
        value: s.value,
        icon: s.icon,
        bg: s.bg,
        fg: s.fg,
      )).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color bg;
  final Color fg;

  const _StatCard({required this.label, required this.value, required this.icon, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: fg, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted)),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Weekly Engagement Bar Chart
// ══════════════════════════════════════════════════
class _WeeklyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('COGNITIVE PROGRESS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.teal)),
                const SizedBox(height: 4),
                Text('Weekly engagement', style: Theme.of(context).textTheme.titleMedium),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('This week', style: Theme.of(context).textTheme.labelMedium),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ── Bar chart
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: AppConstants.weeklyEngagement.map((d) {
                final pct = (d['score'] as int) / 100.0;
                final isToday = d['day'] == 'Sun';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${d['score']}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isToday ? AppColors.teal : AppColors.muted,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FractionallySizedBox(
                          heightFactor: pct,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isToday ? AppColors.teal : AppColors.tealPale,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(d['day'] as String,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isToday ? AppColors.teal : AppColors.muted,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 18, color: AppColors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall,
                    children: const [
                      TextSpan(text: '12% improvement', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.teal)),
                      TextSpan(text: ' in cognitive engagement compared with last week.', style: TextStyle(color: AppColors.inkSoft)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Today's Routine + Health Snapshot (side by side on tablet, stacked on phone)
// ══════════════════════════════════════════════════
class _TwoColumnCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _RoutineCard()),
          const SizedBox(width: 14),
          Expanded(child: _HealthSnapshotCard()),
        ],
      );
    }
    return Column(
      children: [
        _RoutineCard(),
        const SizedBox(height: 14),
        _HealthSnapshotCard(),
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("TODAY'S ROUTINE",
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.teal)),
                const SizedBox(height: 4),
                Text('Care tasks', style: Theme.of(context).textTheme.titleMedium),
              ]),
              TextButton(
                onPressed: () {},
                child: Text('View all', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.teal)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...AppConstants.careTasks.map((t) => _TaskRow(
            task: t['task'] as String,
            time: t['time'] as String,
            done: t['done'] as bool,
          )),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String task;
  final String time;
  final bool done;
  const _TaskRow({required this.task, required this.time, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: done ? AppColors.tealLight : AppColors.softSection,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.access_time_rounded,
              size: 16,
              color: done ? AppColors.teal : AppColors.muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 13)),
                Text(time, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: done ? AppColors.tealLight : AppColors.amberPale,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              done ? 'Completed' : 'Upcoming',
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: done ? AppColors.tealDark : AppColors.amberDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthSnapshotCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Blood group',       'B+'),
      ('Primary language',  'English'),
      ('Emergency contact', '+91 98765 43210'),
      ('Care physician',    'Dr. Ananya Bora'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PATIENT DETAILS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.teal)),
                const SizedBox(height: 4),
                Text('Health snapshot', style: Theme.of(context).textTheme.titleMedium),
              ]),
              const Icon(Icons.person_outline_rounded, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 16),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r.$1, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted)),
                Text(r.$2, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 13)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Care Insight Card
// ══════════════════════════════════════════════════
class _CareInsightCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CARE INSIGHT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.violet)),
                const SizedBox(height: 4),
                Text("Today's note", style: Theme.of(context).textTheme.titleMedium),
              ]),
              const Icon(Icons.auto_awesome_rounded, color: AppColors.violet),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Ramesh showed strong recognition during the family-photo activity '
            'and responded well to voice prompts.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.favorite_rounded, size: 16, color: AppColors.coral),
              const SizedBox(width: 6),
              Text('Mood: ', style: Theme.of(context).textTheme.bodySmall),
              Text('Calm & engaged',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 13, color: AppColors.tealDark,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
