// lib/features/doctor/widgets/cognitive_progress_chart.dart
//
// Interactive Cognitive Progress Chart for Doctor Patient Clinical Overview.
// Supports 7 Days, 30 Days, and 90 Days windows.
// Strictly uses REAL GameResult data — shows 'Not enough assessment data yet.' if insufficient.

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/game_result.dart';

class CognitiveProgressChart extends StatefulWidget {
  final List<GameResult> gameHistory;

  const CognitiveProgressChart({
    super.key,
    required this.gameHistory,
  });

  @override
  State<CognitiveProgressChart> createState() => _CognitiveProgressChartState();
}

class _CognitiveProgressChartState extends State<CognitiveProgressChart> {
  int _selectedDays = 7; // 7, 30, or 90

  List<GameResult> _getFilteredData() {
    final cutoff = DateTime.now().subtract(Duration(days: _selectedDays));
    final filtered =
        widget.gameHistory.where((g) => g.timestamp.isAfter(cutoff)).toList();
    // Sort oldest to newest for chronological progress
    filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _getFilteredData();

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
          // Header: Title & Time Filter Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cognitive Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Row(
                children: [
                  _buildFilterChip(7, '7D'),
                  const SizedBox(width: 6),
                  _buildFilterChip(30, '30D'),
                  const SizedBox(width: 6),
                  _buildFilterChip(90, '90D'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart Body or "Not enough assessment data yet"
          if (filteredData.length < 2)
            Container(
              height: 160,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timeline_rounded,
                      size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  const Text(
                    'Not enough assessment data yet.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'At least 2 completed sessions within the last $_selectedDays days are needed to plot progress.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 160,
              width: double.infinity,
              child: CustomPaint(
                painter: _LineChartPainter(data: filteredData),
              ),
            ),

          if (filteredData.length >= 2) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Sessions', '${filteredData.length}'),
                _buildStatItem(
                  'Average',
                  (filteredData.map((e) => e.score).reduce((a, b) => a + b) /
                          filteredData.length)
                      .toStringAsFixed(1),
                ),
                _buildStatItem(
                  'Peak',
                  '${filteredData.map((e) => e.score).reduce(max)}',
                ),
                _buildStatItem(
                  'Lowest',
                  '${filteredData.map((e) => e.score).reduce(min)}',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(int days, String label) {
    final isSelected = _selectedDays == days;
    return InkWell(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _selectedDays = days;
          });
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.teal : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.teal : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<GameResult> data;

  _LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingBottom = 20;
    final double chartHeight = size.height - paddingBottom;
    final double chartWidth = size.width;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = chartHeight * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    // Min and Max scores in range (clamped to 0-100)
    const double minScore = 0;
    const double maxScore = 100;

    final points = <Offset>[];
    final stepX = chartWidth / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final scoreRatio = (data[i].score - minScore) / (maxScore - minScore);
      final y = chartHeight - (scoreRatio * chartHeight);
      points.add(Offset(x, y.clamp(0, chartHeight)));
    }

    // Draw gradient area under curve
    final path = Path()..moveTo(points.first.dx, chartHeight);
    for (final p in points) {
      path.lineTo(p.dx, p.dy);
    }
    path.lineTo(points.last.dx, chartHeight);
    path.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.teal.withValues(alpha: 0.25),
          AppColors.teal.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight));
    canvas.drawPath(path, fillPaint);

    // Draw line
    final linePaint = Paint()
      ..color = AppColors.teal
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw data points & score labels
    final dotPaint = Paint()..color = AppColors.teal;
    final dotInnerPaint = Paint()..color = Colors.white;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 4.5, dotPaint);
      canvas.drawCircle(p, 2.5, dotInnerPaint);

      // Score label above dot
      final textSpan = TextSpan(
        text: '${data[i].score}',
        style: const TextStyle(
          color: AppColors.tealDark,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final labelY = (p.dy - 16).clamp(0.0, chartHeight - 12);
      textPainter.paint(
        canvas,
        Offset(p.dx - (textPainter.width / 2), labelY),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.data != data;
}
