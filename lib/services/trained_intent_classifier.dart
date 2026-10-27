import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;

/// On-device inference from a supervised Multinomial Naive Bayes model.
/// This does NOT generate natural language; the existing CoachHybridRouter
/// remains responsible for retrieving real data and generating the answer.
class TrainedIntentClassifier {
  TrainedIntentClassifier._();
  static Map<String, dynamic>? _model;

  static Future<void> load() async {
    _model ??= jsonDecode(
      await rootBundle.loadString('assets/ai/intent_nb.json'),
    ) as Map<String, dynamic>;
  }

  static Future<String?> classify(String text) async {
    await load();
    if (text.trim().length < 5) return null;
    final m = _model!;
    final classes = List<String>.from(m['classes'] as List);
    final priors = (m['class_log_prior'] as List).cast<num>();
    final lookup = m['feature_log_prob'] as Map<String, dynamic>;
    final scores = priors.map((v) => v.toDouble()).toList();
    final s = text.toLowerCase();
    final tokens = <String>{};
    for (var n = 2; n <= 3; n++) {
      for (var i = 0; i + n <= s.length; i++) {
        tokens.add(s.substring(i, i + n));
      }
    }
    for (final token in tokens) {
      final vals = lookup[token];
      if (vals is! List) continue;
      for (var i = 0; i < scores.length; i++) {
        scores[i] += (vals[i] as num).toDouble();
      }
    }
    var best = 0;
    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > scores[best]) best = i;
    }
    final highest = scores[best];
    final expScores = scores.map((x) => math.exp(x - highest)).toList();
    final total = expScores.reduce((a, b) => a + b);
    final p = expScores[best] / total;
    final sorted = [...expScores]..sort();
    final margin = (expScores[best] - sorted[sorted.length - 2]) / total;
    if (p < (m['confidence_threshold'] as num).toDouble() ||
        margin < (m['margin_threshold'] as num).toDouble()) {
      return null; // Ask Gemini only if the existing rules cannot answer.
    }
    final intent = classes[best];
    // Safety-critical intents must *always* be handled by explicit rules.
    if (const {'symptoms', 'medical', 'safety_reason', 'recovery', 'unknown'}
        .contains(intent)) {
      return null;
    }
    return intent;
  }
}
