class AnalysisData {
  final String description;
  final List<AnalysisTag> tags;
  final List<String> dominantColors;

  const AnalysisData({
    required this.description,
    required this.tags,
    required this.dominantColors,
  });

  factory AnalysisData.fromJson(Map<String, dynamic> json) {
    return AnalysisData(description: json['description'] as String? ?? '',
    tags: (json['tags'] as List<dynamic>? ?? [])
    .map((t) => AnalysisTag.fromJson(t as Map<String, dynamic>)).toList(),
    dominantColors: (json['dominant_colors'] as List<dynamic>? ?? []).map((c) => c.toString()).toList()
    );
  }

  String get summarForHistory => description.isNotEmpty ? description : tags.isNotEmpty ? tags.map((t) => t.label).take(3).join(',') : 'Image analyzed';
}

class AnalysisTag {
  final String label;
  final double confidence;

  const AnalysisTag({
    required this.label,
    required this.confidence,
  });

  factory AnalysisTag.fromJson(Map<String, dynamic> json) {
    return AnalysisTag(label: json['label'] as String? ?? '', confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0);
  }

  String get confidencePercentage => confidence.toStringAsFixed(0);
}