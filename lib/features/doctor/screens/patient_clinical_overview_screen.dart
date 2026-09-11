// lib/features/doctor/screens/patient_clinical_overview_screen.dart
//
// Patient Clinical Overview Screen for Doctor Portal.
// Sections:
// A. Patient Demographic & Baseline Overview
// B. Cognitive Health & Score Trends
// C. Interactive Cognitive Progress Chart (7D, 30D, 90D)
// D. Cognitive Game Performance Breakdown
// E. MRI Screening Integration with "Mark as Reviewed"
// F. Caregiver Observations (Read-only)
// G. Doctor Notes CRUD with Author Isolation
// H. In-App Clinical Report View Action

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/caregiver_models.dart';
import '../../../core/models/game_result.dart';
import '../../../core/services/step_storage_service.dart';
import '../models/doctor_models.dart';
import '../services/doctor_service.dart';
import '../widgets/cognitive_progress_chart.dart';
import '../widgets/patient_attention_badge.dart';
import 'patient_clinical_report_screen.dart';

class PatientClinicalOverviewScreen extends StatefulWidget {
  final String patientId;

  const PatientClinicalOverviewScreen({
    super.key,
    required this.patientId,
  });

  @override
  State<PatientClinicalOverviewScreen> createState() =>
      _PatientClinicalOverviewScreenState();
}

class _PatientClinicalOverviewScreenState
    extends State<PatientClinicalOverviewScreen> {
  bool _isLoading = true;
  PatientClinicalSummary? _summary;
  final _newNoteController = TextEditingController();
  bool _isAddingNote = false;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  @override
  void dispose() {
    _newNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    setState(() => _isLoading = true);
    try {
      await DoctorService.instance.init();
      final summary = await DoctorService.instance
          .getPatientClinicalSummary(widget.patientId);
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.teal),
        ),
      );
    }

    if (_summary == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Access Unauthorized',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You do not have approved clinical access for this patient record.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final p = _summary!.patient;
    final attention = _summary!.attentionStatus;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          p.fullName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        actions: [
          // Clinical Report View Action
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) =>
                      PatientClinicalReportScreen(summary: _summary!),
                ),
              );
            },
            icon: const Icon(Icons.description_rounded,
                size: 16, color: AppColors.tealDark),
            label: const Text(
              'Report',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.tealDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPatientData,
        color: AppColors.teal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section A: Patient Demographic & Baseline Banner
              _buildPatientBanner(p, attention),
              const SizedBox(height: 18),

              // ── Section B: Cognitive Health Snapshot Cards
              _buildCognitiveHealthCards(),
              const SizedBox(height: 18),

              // ── Section C: Interactive Cognitive Progress Chart
              CognitiveProgressChart(gameHistory: _summary!.gameHistory),
              const SizedBox(height: 24),

              // ── Section D: Cognitive Game Performance Breakdown
              _buildGamePerformanceSection(),
              const SizedBox(height: 24),

              // ── Section E: MRI Screening Section
              _buildMriScreeningSection(),
              const SizedBox(height: 24),

              // FIX: Added authorized caregiver/doctor activity access
              // ── Section E2: Physical Activity & Step Tracking Section
              _buildPhysicalActivitySection(p),
              const SizedBox(height: 24),

              // ── Section F: Caregiver Observations (Read-only)
              _buildCaregiverObservationsSection(),
              const SizedBox(height: 24),

              // ── Section G: Doctor Notes (Add, Edit, View)
              _buildDoctorNotesSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section A: Patient Banner ─────────────────────────────────────────────
  Widget _buildPatientBanner(p, PatientAttentionStatus attention) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.tealLight,
                child: Text(
                  p.avatarInitials,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tealDark,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${p.id} • Age: ${p.age} • Blood Group: ${p.bloodGroup}',
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Location: ${p.location}',
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dementia Stage',
                      style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  const SizedBox(height: 2),
                  Text(
                    p.dementiaLevel,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Primary Language',
                      style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  const SizedBox(height: 2),
                  Text(
                    p.primaryLanguage,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                ],
              ),
              PatientAttentionBadge(status: attention, showReason: false),
            ],
          ),
          if (attention.reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: attention.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: attention.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      attention.reason,
                      style: TextStyle(
                          fontSize: 11,
                          color: attention.color,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Section B: Cognitive Health Snapshot Cards ────────────────────────────
  Widget _buildCognitiveHealthCards() {
    final latest = _summary!.latestScore;
    final prev = _summary!.previousScore;
    final trend = _summary!.trendPercent;

    String trendText = 'Stable';
    Color trendColor = AppColors.muted;
    IconData trendIcon = Icons.remove_rounded;

    if (trend != null) {
      if (trend > 0) {
        trendText = '+${trend.toStringAsFixed(0)}%';
        trendColor = const Color(0xFF2E7D32);
        trendIcon = Icons.trending_up_rounded;
      } else if (trend < 0) {
        trendText = '${trend.toStringAsFixed(0)}%';
        trendColor = const Color(0xFFC62828);
        trendIcon = Icons.trending_down_rounded;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildMetricMiniCard(
            title: 'Latest Score',
            value: latest != null ? '$latest / 100' : '—',
            subtitle: _summary!.lastAssessedAt != null
                ? 'Assessed ${_formatDate(_summary!.lastAssessedAt!)}'
                : 'No tests recorded',
            color: AppColors.teal,
            icon: Icons.psychology_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricMiniCard(
            title: 'Previous Score',
            value: prev != null ? '$prev / 100' : '—',
            subtitle: 'Prior assessment baseline',
            color: const Color(0xFF1565C0),
            icon: Icons.history_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricMiniCard(
            title: 'Trend Variance',
            value: trendText,
            subtitle: trend != null ? 'Delta vs prior test' : 'Need 2+ tests',
            color: trendColor,
            icon: trendIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricMiniCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: AppColors.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Section D: Cognitive Game Performance Breakdown ───────────────────────
  Widget _buildGamePerformanceSection() {
    final games = _summary!.gameHistory;

    // Group games by gameId
    final Map<String, List<GameResult>> grouped = {};
    for (final g in games) {
      grouped.putIfAbsent(g.gameId, () => []).add(g);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cognitive Game Performance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Breakdown of individual interactive cognitive activities',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        if (games.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Column(
              children: [
                Icon(Icons.sports_esports_outlined,
                    size: 36, color: AppColors.muted),
                SizedBox(height: 8),
                Text(
                  'No cognitive assessments available yet.',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                ),
                SizedBox(height: 4),
                Text(
                  'Patient has not completed any cognitive game sessions.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          )
        else
          ...grouped.entries.map((entry) {
            final gameList = entry.value;
            final latestGame = gameList.first;
            final avgScore =
                gameList.map((e) => e.score).reduce((a, b) => a + b) ~/
                    gameList.length;
            final avgAccuracy =
                gameList.map((e) => e.accuracy).reduce((a, b) => a + b) ~/
                    gameList.length;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.psychology_rounded,
                        size: 20, color: AppColors.tealDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          latestGame.gameName,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${gameList.length} session${gameList.length > 1 ? 's' : ''} • Level: ${latestGame.difficulty}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Score: ${latestGame.score} / 100',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Avg: $avgScore • Acc: $avgAccuracy%',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ── Section E: MRI Screening Section ───────────────────────────────────────
  Widget _buildMriScreeningSection() {
    final scans = _summary!.mriScans;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MRI Screening History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            Text(
              '${scans.length} Scan${scans.length == 1 ? '' : 's'}',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Prominent Medical Disclaimer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFB74D)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: Color(0xFFE65100)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI-assisted screening only. This result is not a medical diagnosis.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (scans.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Column(
              children: [
                Icon(Icons.biotech_outlined, size: 36, color: AppColors.muted),
                SizedBox(height: 8),
                Text(
                  'No MRI screening available.',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                ),
                SizedBox(height: 4),
                Text(
                  'No MRI scans have been uploaded for this patient.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          )
        else
          ...scans.map((scan) {
            final isReviewed = scan.isReviewed;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isReviewed
                      ? AppColors.cardBorder
                      : const Color(0xFFFFB74D),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.biotech_rounded,
                            size: 18,
                            color: isReviewed
                                ? AppColors.teal
                                : const Color(0xFFE65100),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            scan.prediction,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isReviewed
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isReviewed ? 'Reviewed' : 'Review Pending',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isReviewed
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uploaded: ${_formatDate(scan.timestamp)} • Confidence: ${(scan.confidenceScore * 100).toStringAsFixed(1)}%',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    scan.recommendation,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.ink, height: 1.3),
                  ),
                  const SizedBox(height: 12),

                  // Review Action Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isReviewed)
                        Text(
                          'Reviewed by Dr. on ${_formatDate(scan.reviewedAt ?? DateTime.now())}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2E7D32),
                              fontStyle: FontStyle.italic),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () async {
                            await DoctorService.instance
                                .markMriAsReviewed(scanId: scan.scanId);
                            if (!mounted) return;
                            _loadPatientData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'MRI marked as clinically reviewed.')),
                            );
                          },
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Mark as Reviewed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // FIX: Added authorized caregiver/doctor activity access
  // ── Section E2: Physical Activity Section (Doctor Portal) ────────────────
  Widget _buildPhysicalActivitySection(PatientProfile patient) {
    final today = StepStorageService.instance.getTodayRecordCached();
    final todaySteps = today?.steps ?? 0;
    final todayGoal = today?.goal ?? 10000;
    final avg7Day = StepStorageService.instance
        .getSevenDayAverageSteps(patientId: patient.id);
    final goalAchievedDays = StepStorageService.instance
        .getGoalCompletedDays(patientId: patient.id, days: 7);
    final history = StepStorageService.instance
        .getRecentHistory(days: 7, patientId: patient.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.directions_walk_rounded,
                    color: AppColors.teal, size: 20),
                SizedBox(width: 8),
                Text(
                  'Physical Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tealPale,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '7-Day Summary',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tealDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Objective mobility metrics & walking volume tracked by device sensor',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 12),

        // 3 Metric Cards Row
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Today',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '$todaySteps',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Goal: $todayGoal',
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.tealDark,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('7-Day Avg',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      avg7Day > 0 ? '$avg7Day' : '$todaySteps',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'steps / day',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Goal Met',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '$goalAchievedDays / 7',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'days target met',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        if (history.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_rounded,
                    size: 16, color: AppColors.muted),
                const SizedBox(width: 8),
                const Text(
                  'Recent:',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    history
                        .map((r) => '${r.date.substring(5)}: ${r.steps}')
                        .join(' • '),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Section F: Caregiver Observations ─────────────────────────────────────
  Widget _buildCaregiverObservationsSection() {
    final obs = _summary!.caregiverObservations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Caregiver Observations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Read-only observations & routine notes submitted by the primary caregiver',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        if (obs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Text(
              'No caregiver observations recorded yet.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          )
        else
          ...obs.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink),
                      ),
                      Text(
                        'Scheduled ${item.scheduledTime}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.ink, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Author: Primary Caregiver (Read-only)',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ── Section G: Doctor Notes (Add, Edit, View) ──────────────────────────────
  Widget _buildDoctorNotesSection() {
    final notes = _summary!.doctorNotes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Doctor Clinical Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            IconButton(
              icon: Icon(_isAddingNote
                  ? Icons.close_rounded
                  : Icons.add_comment_rounded),
              color: AppColors.tealDark,
              onPressed: () {
                setState(() => _isAddingNote = !_isAddingNote);
              },
              tooltip: _isAddingNote ? 'Cancel' : 'Add Clinical Note',
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Add Note Box
        if (_isAddingNote) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.teal),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _newNoteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Enter clinical observations, treatment recommendations, or review notes...',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final text = _newNoteController.text.trim();
                    if (text.isNotEmpty) {
                      await DoctorService.instance.addDoctorNote(
                        patientId: widget.patientId,
                        text: text,
                      );
                      _newNoteController.clear();
                      setState(() => _isAddingNote = false);
                      _loadPatientData();
                    }
                  },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Save Note'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (notes.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Column(
              children: [
                Icon(Icons.notes_rounded, size: 36, color: AppColors.muted),
                SizedBox(height: 8),
                Text(
                  'No doctor notes added yet.',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap the plus icon above to add your first clinical note.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          )
        else
          ...notes.map((note) {
            final isOwnNote =
                note.doctorId == DoctorService.instance.currentDoctorId ||
                    note.doctorId == 'DOC-001';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        note.doctorName,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.tealDark),
                      ),
                      Row(
                        children: [
                          Text(
                            _formatDate(note.createdAt),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.muted),
                          ),
                          if (isOwnNote) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded,
                                  size: 16, color: AppColors.muted),
                              onPressed: () => _editNoteDialog(note),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Edit Note',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    note.text,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.ink, height: 1.3),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _editNoteDialog(DoctorNote note) {
    final editController = TextEditingController(text: note.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Doctor Note'),
        content: TextField(
          controller: editController,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Edit clinical note...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isNotEmpty) {
                await DoctorService.instance.updateDoctorNote(
                  noteId: note.noteId,
                  newText: newText,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  _loadPatientData();
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
