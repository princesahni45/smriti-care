// lib/features/doctor/screens/patient_clinical_report_screen.dart
//
// In-App Comprehensive Clinical Report View.
// Formats patient demographics, cognitive trends, MRI results, caregiver observations,
// and doctor notes into a clean, professional clinical document.

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/doctor_service.dart';

class PatientClinicalReportScreen extends StatelessWidget {
  final PatientClinicalSummary summary;

  const PatientClinicalReportScreen({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final p = summary.patient;
    final doctor = DoctorService.instance.doctorProfile;
    final attention = summary.attentionStatus;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Clinical Summary Report',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, color: AppColors.ink),
            tooltip: 'Print Report',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Clinical Report formatted for printing/export.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
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
              // ── Report Document Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SMRITICARE CLINICAL REPORT',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: AppColors.tealDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Generated: ${_formatDate(DateTime.now())}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'STATUS: ${attention.label.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: attention.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(
                  height: 1, thickness: 1.5, color: AppColors.cardBorder),
              const SizedBox(height: 16),

              // ── Patient & Physician Overview
              const Text(
                '1. Patient & Physician Information',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              _buildTwoColTable([
                ('Full Name', p.fullName),
                ('Patient ID', p.id),
                ('Age / Gender', '${p.age} years / Adult'),
                ('Blood Group', p.bloodGroup),
                ('Primary Location', p.location),
                ('Dementia Stage', p.dementiaLevel),
                ('Attending Physician', doctor.name),
                ('Clinic / Hospital', doctor.hospitalOrClinic),
              ]),
              const SizedBox(height: 20),

              // ── Cognitive Health & Assessment Summary
              const Text(
                '2. Cognitive Assessment Summary',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              _buildTwoColTable([
                (
                  'Latest Composite Score',
                  summary.latestScore != null
                      ? '${summary.latestScore} / 100'
                      : 'No data'
                ),
                (
                  'Previous Baseline Score',
                  summary.previousScore != null
                      ? '${summary.previousScore} / 100'
                      : 'No data'
                ),
                (
                  'Recent Trend',
                  summary.trendPercent != null
                      ? '${summary.trendPercent! > 0 ? '+' : ''}${summary.trendPercent!.toStringAsFixed(1)}%'
                      : 'Stable'
                ),
                (
                  'Total Recorded Sessions',
                  '${summary.gameHistory.length} sessions'
                ),
                ('Clinical Attention Status', attention.label),
                ('Reasoning', attention.reason),
              ]),
              const SizedBox(height: 20),

              // ── Game Breakdown
              const Text(
                '3. Cognitive Activity Breakdown',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              if (summary.gameHistory.isEmpty)
                const Text('No cognitive games recorded.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted))
              else
                ...summary.gameHistory.take(5).map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('• ${g.gameName} (${g.difficulty})',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.ink)),
                          Text('Score: ${g.score}/100 • Acc: ${g.accuracy}%',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )),
              const SizedBox(height: 20),

              // ── MRI Screening Summary
              const Text(
                '4. MRI AI Screening History',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              if (summary.mriScans.isEmpty)
                const Text('No MRI scans uploaded for this patient.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted))
              else
                ...summary.mriScans.map((m) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Prediction: ${m.prediction}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                              Text(
                                  m.isReviewed
                                      ? 'CLINICALLY REVIEWED'
                                      : 'REVIEW PENDING',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: m.isReviewed
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFFE65100))),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                              'Confidence: ${(m.confidenceScore * 100).toStringAsFixed(1)}% • Scan Date: ${_formatDate(m.timestamp)}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                    )),
              const SizedBox(height: 20),

              // ── Caregiver Observations
              const Text(
                '5. Caregiver Observations',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              if (summary.caregiverObservations.isEmpty)
                const Text('No caregiver observations recorded.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted))
              else
                ...summary.caregiverObservations.map((o) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• ${o.title}: "${o.message}"',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.ink)),
                    )),
              const SizedBox(height: 20),

              // ── Doctor Clinical Notes
              const Text(
                '6. Physician Clinical Notes',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              if (summary.doctorNotes.isEmpty)
                const Text('No doctor notes recorded yet.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted))
              else
                ...summary.doctorNotes.map((n) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${n.doctorName} (${_formatDate(n.createdAt)}):',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tealDark)),
                          Text(n.text,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.ink)),
                        ],
                      ),
                    )),
              const SizedBox(height: 24),

              // ── Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'DISCLAIMER: SmritiCare is an AI-assisted supportive technology for cognitive care monitoring. Game assessments and MRI screenings do not constitute an independent medical diagnosis. Clinical judgment remains the sole responsibility of the attending physician.',
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTwoColTable(List<(String, String)> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: rows
            .map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.$1,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.$2,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}
