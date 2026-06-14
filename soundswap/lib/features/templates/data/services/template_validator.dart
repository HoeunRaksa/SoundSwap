import 'dart:io';

import 'package:soundswap/features/home/data/models/soundswap_job.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/templates/data/models/project_template.dart';

enum AssetType {
  logo,
  imageOverlay,
}

class MissingAsset {
  const MissingAsset({
    required this.templateId,
    required this.templateName,
    required this.assetPath,
    required this.assetType,
    this.layerId,
    this.layerName,
  });

  final String templateId;
  final String templateName;
  final String assetPath;
  final AssetType assetType;
  final String? layerId;
  final String? layerName;
}

class TemplateValidationResult {
  const TemplateValidationResult({
    required this.resolvedTemplates,
    required this.saveToDisk,
  });

  /// Maps template ID to the resolved template. 
  /// If the user chose to skip the template, the value will be null.
  final Map<String, ProjectTemplate?> resolvedTemplates;
  final bool saveToDisk;
}

class TemplateValidator {
  static List<MissingAsset> validateBatchTemplates(List<SoundSwapJob> jobs) {
    final missingAssets = <MissingAsset>[];
    final checkedTemplates = <String>{};

    for (final job in jobs) {
      final t = job.template;
      if (t == null) continue;
      if (checkedTemplates.contains(t.id)) continue;
      checkedTemplates.add(t.id);
      
      missingAssets.addAll(validateTemplate(t));
    }
    return missingAssets;
  }

  static List<MissingAsset> validateTemplate(ProjectTemplate t) {
    final missingAssets = <MissingAsset>[];

    // Check logo
    if (t.useBranding && t.branding.logoPath != null && t.branding.logoPath!.isNotEmpty) {
      final f = File(t.branding.logoPath!);
      if (!f.existsSync()) {
        missingAssets.add(
          MissingAsset(
            templateId: t.id,
            templateName: t.name,
            assetPath: t.branding.logoPath!,
            assetType: AssetType.logo,
          ),
        );
      }
    }

    // Check image overlays
    if (t.useOverlay) {
      for (final item in t.overlaySettings.items) {
        if (item.type == OverlayItemType.image && item.imagePath != null && item.imagePath!.isNotEmpty) {
          final f = File(item.imagePath!);
          if (!f.existsSync()) {
            missingAssets.add(
              MissingAsset(
                templateId: t.id,
                templateName: t.name,
                assetPath: item.imagePath!,
                assetType: AssetType.imageOverlay,
                layerId: item.id,
                layerName: item.name.isNotEmpty ? item.name : 'Image Overlay',
              ),
            );
          }
        }
      }
    }

    return missingAssets;
  }
}
