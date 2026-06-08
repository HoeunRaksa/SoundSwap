import 'package:flutter/foundation.dart';
import 'package:soundswap/features/branding/presentation/state/branding_controller.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/templates/data/models/project_template.dart';
import 'package:soundswap/features/templates/data/services/templates_service.dart';
import 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';

class TemplatesController extends ChangeNotifier {
  TemplatesController({TemplatesService? service})
    : _service = service ?? TemplatesService();

  final TemplatesService _service;
  List<ProjectTemplate> templates = [];
  String? message;

  Future<void> load() async {
    templates = await _service.load();
    notifyListeners();
  }

  Future<void> saveCurrent({
    required String name,
    required HomeController home,
    required BrandingController branding,
    required TextOverlayController textOverlay,
  }) async {
    final template = ProjectTemplate(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Untitled template' : name.trim(),
      createdAt: DateTime.now(),
      videoFolder: home.videoFolderPath,
      audioFolder: home.audioFolderPath,
      outputFolder: home.outputFolderPath,
      outputPrefix: home.outputNamePrefix,
      branding: branding.settings,
      textOverlay: textOverlay.settings,
    );
    templates = [template, ...templates];
    await _service.saveAll(templates);
    message = 'Template saved.';
    notifyListeners();
  }

  Future<void> loadTemplate({
    required ProjectTemplate template,
    required HomeController home,
    required BrandingController branding,
    required TextOverlayController textOverlay,
  }) async {
    await home.applyTemplateFolders(
      videoFolder: template.videoFolder,
      audioFolder: template.audioFolder,
      outputFolder: template.outputFolder,
      outputPrefix: template.outputPrefix,
    );
    await branding.update(template.branding);
    await textOverlay.update(template.textOverlay);
    message = 'Template loaded.';
    notifyListeners();
  }
}
