enum TextOverlayPosition { top, center, bottom }

class TextOverlaySettings {
  const TextOverlaySettings({
    this.title = '',
    this.subtitle = '',
    this.promotionText = '',
    this.position = TextOverlayPosition.bottom,
  });

  final String title;
  final String subtitle;
  final String promotionText;
  final TextOverlayPosition position;

  Map<String, Object?> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'promotionText': promotionText,
    'position': position.name,
  };

  factory TextOverlaySettings.fromJson(Map<String, Object?> json) {
    return TextOverlaySettings(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      promotionText: json['promotionText'] as String? ?? '',
      position: TextOverlayPosition.values.firstWhere(
        (value) => value.name == json['position'],
        orElse: () => TextOverlayPosition.bottom,
      ),
    );
  }

  TextOverlaySettings copyWith({
    String? title,
    String? subtitle,
    String? promotionText,
    TextOverlayPosition? position,
  }) {
    return TextOverlaySettings(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      promotionText: promotionText ?? this.promotionText,
      position: position ?? this.position,
    );
  }

  String buildDrawTextPreview() {
    final y = switch (position) {
      TextOverlayPosition.top => '48',
      TextOverlayPosition.center => '(h-text_h)/2',
      TextOverlayPosition.bottom => 'h-140',
    };
    final lines = [
      title,
      subtitle,
      promotionText,
    ].where((value) => value.trim().isNotEmpty).toList();
    if (lines.isEmpty) return 'No text overlay configured.';
    return lines
        .asMap()
        .entries
        .map(
          (entry) =>
              'drawtext=text="${entry.value}":x=(w-text_w)/2:y=$y+${entry.key * 42}',
        )
        .join(',\n');
  }
}
