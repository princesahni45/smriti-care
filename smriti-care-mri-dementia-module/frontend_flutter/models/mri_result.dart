// lib/features/mri_analysis/models/mri_result.dart
//
// Model class deserializing AI-Assisted MRI Dementia Severity Estimation API output.

class MriResult {
  final String labelHeader;
  final String prediction;
  final int classId;
  final double confidence;
  final Map<String, double> probabilities;
  final Map<String, double> displayProbabilities;
  final bool isLowConfidence;
  final String clinicalNote;
  final String disclaimer;
  final String? gradcamUrl;
  final String? gradcamDisclaimer;
  final Map<String, dynamic>? modelInfo;

  const MriResult({
    required this.labelHeader,
    required this.prediction,
    required this.classId,
    required this.confidence,
    required this.probabilities,
    required this.displayProbabilities,
    required this.isLowConfidence,
    required this.clinicalNote,
    required this.disclaimer,
    this.gradcamUrl,
    this.gradcamDisclaimer,
    this.modelInfo,
  });

  factory MriResult.fromJson(Map<String, dynamic> json) {
    // Parse probabilities dictionary
    final rawProbs = json['probabilities'] as Map<String, dynamic>? ?? {};
    final probs = <String, double>{};
    rawProbs.forEach((key, value) {
      probs[key] = (value as num).toDouble();
    });

    // Parse display probabilities if available
    final rawDisplay = json['display_probabilities'] as Map<String, dynamic>? ?? {};
    final displayProbs = <String, double>{};
    rawDisplay.forEach((key, value) {
      displayProbs[key] = (value as num).toDouble();
    });

    return MriResult(
      labelHeader: json['label_header'] as String? ?? 'AI-Assisted Dementia Severity Estimation',
      prediction: json['prediction'] as String? ?? 'Unknown',
      classId: json['class_id'] as int? ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      probabilities: probs,
      displayProbabilities: displayProbs.isNotEmpty ? displayProbs : probs,
      isLowConfidence: json['is_low_confidence'] as bool? ?? false,
      clinicalNote: json['clinical_note'] as String? ?? '',
      disclaimer: json['disclaimer'] as String? ??
          'This system provides AI-assisted estimation based on MRI patterns for research and educational purposes only. It is not a medical diagnosis.',
      gradcamUrl: json['gradcam_url'] as String?,
      gradcamDisclaimer: json['gradcam_disclaimer'] as String? ??
          'Model Attention Visualization — Not a Clinical Interpretation',
      modelInfo: json['model_info'] as Map<String, dynamic>?,
    );
  }
}
