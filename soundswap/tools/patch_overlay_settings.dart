import 'dart:io';

void main() {
  String content = File('lib/features/overlay_tools/data/models/overlay_settings.dart').readAsStringSync();

  // Add fields
  content = content.replaceFirst(
    'this.customSafeAreaPadding,\n  });',
    'this.customSafeAreaPadding,\n    this.showFullScreenLayersPanel = true,\n    this.showFullScreenPropertiesPanel = true,\n  });'
  );

  content = content.replaceFirst(
    'final SafeAreaPadding? customSafeAreaPadding;',
    'final SafeAreaPadding? customSafeAreaPadding;\n  final bool showFullScreenLayersPanel;\n  final bool showFullScreenPropertiesPanel;'
  );

  // Add to toJson
  content = content.replaceFirst(
    "'customSafeAreaPadding': customSafeAreaPadding?.toJson(),",
    "'customSafeAreaPadding': customSafeAreaPadding?.toJson(),\n    'showFullScreenLayersPanel': showFullScreenLayersPanel,\n    'showFullScreenPropertiesPanel': showFullScreenPropertiesPanel,"
  );

  // Add to fromJson
  content = content.replaceFirst(
    "customSafeAreaPadding: json['customSafeAreaPadding'] != null\n          ? SafeAreaPadding.fromJson(\n              (json['customSafeAreaPadding'] as Map).cast<String, Object?>())\n          : null,\n    );",
    "customSafeAreaPadding: json['customSafeAreaPadding'] != null\n          ? SafeAreaPadding.fromJson(\n              (json['customSafeAreaPadding'] as Map).cast<String, Object?>())\n          : null,\n      showFullScreenLayersPanel: json['showFullScreenLayersPanel'] as bool? ?? true,\n      showFullScreenPropertiesPanel: json['showFullScreenPropertiesPanel'] as bool? ?? true,\n    );"
  );

  // Add to copyWith signature
  content = content.replaceFirst(
    "SafeAreaPadding? customSafeAreaPadding,\n  }) {",
    "SafeAreaPadding? customSafeAreaPadding,\n    bool? showFullScreenLayersPanel,\n    bool? showFullScreenPropertiesPanel,\n  }) {"
  );

  // Add to copyWith body
  content = content.replaceFirst(
    "customSafeAreaPadding: customSafeAreaPadding ?? this.customSafeAreaPadding,\n    );",
    "customSafeAreaPadding: customSafeAreaPadding ?? this.customSafeAreaPadding,\n      showFullScreenLayersPanel: showFullScreenLayersPanel ?? this.showFullScreenLayersPanel,\n      showFullScreenPropertiesPanel: showFullScreenPropertiesPanel ?? this.showFullScreenPropertiesPanel,\n    );"
  );

  File('lib/features/overlay_tools/data/models/overlay_settings.dart').writeAsStringSync(content);
  print('Patched OverlaySettings successfully');
}
