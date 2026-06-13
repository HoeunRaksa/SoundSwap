import 'package:flutter/foundation.dart';
import 'package:soundswap/features/branding/presentation/state/branding_controller.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';
import 'package:soundswap/features/templates/data/models/project_template.dart';
import 'package:soundswap/features/templates/data/services/templates_service.dart';
import 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';

class TemplatesController extends ChangeNotifier {
  TemplatesController({TemplatesService? service})
    : _service = service ?? TemplatesService();

  final TemplatesService _service;
  List<ProjectTemplate> templates = [];
  String? message;

  String? editingTemplateId;
  bool hasUnsavedTemplateChanges = false;
  bool _isLoadingTemplate = false;

  String? get editingTemplateName {
    if (editingTemplateId == null) return null;
    final index = templates.indexWhere((t) => t.id == editingTemplateId);
    return index >= 0 ? templates[index].name : null;
  }

  Future<void> load() async {
    templates = await _service.load();
    notifyListeners();
  }

  Future<void> saveCurrent({
    required String name,
    required HomeController home,
    required BrandingController branding,
    required TextOverlayController textOverlay,
    required OverlayToolsController overlay,
  }) async {
    final overlaySettings = overlay.settings;
    final template = ProjectTemplate(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Untitled template' : name.trim(),
      createdAt: DateTime.now(),
      videoFolders: home.videoFolders,
      audioFolders: home.audioFolders,
      outputFolder: home.outputFolderPath,
      outputPrefix: home.outputNamePrefix,
      branding: home.activeBrandingSettings ?? branding.settings,
      textOverlay: home.activeTextOverlaySettings ?? textOverlay.settings,
      overlaySettings: overlaySettings,
      useBranding: home.useBranding,
      useTextOverlay: home.useTextOverlay,
      useOverlay: home.useOverlay || overlaySettings.hasContent,
      outputSize: home.outputSize,
      fitMode: home.fitMode,
    );
    templates = [template, ...templates];
    await _service.saveAll(templates);
    message = 'Template saved.';
    notifyListeners();
  }

  void markTemplateAsDirty() {
    if (editingTemplateId != null && !_isLoadingTemplate) {
      hasUnsavedTemplateChanges = true;
      notifyListeners();
    }
  }

  Future<void> beginEditingTemplate({
    required ProjectTemplate template,
    required HomeController home,
    required BrandingController branding,
    required TextOverlayController textOverlay,
    required OverlayToolsController overlay,
  }) async {
    _isLoadingTemplate = true;
    editingTemplateId = template.id;
    hasUnsavedTemplateChanges = false;

    await overlay.clearCanvas();

    await loadTemplate(
      template: template,
      home: home,
      branding: branding,
      textOverlay: textOverlay,
      overlay: overlay,
      useDeepCopyForOverlay: true,
    );

    message = 'Editing template: ${template.name}';
    _isLoadingTemplate = false;
    notifyListeners();
  }

  void cancelEditingTemplate() {
    editingTemplateId = null;
    hasUnsavedTemplateChanges = false;
    message = 'Edit cancelled.';
    notifyListeners();
  }

  Future<void> updateEditingTemplate({
    required String name,
    required HomeController home,
    required BrandingController branding,
    required TextOverlayController textOverlay,
    required OverlayToolsController overlay,
  }) async {
    if (editingTemplateId == null) return;
    
    final overlaySettings = overlay.settings.deepCopy();
    final template = ProjectTemplate(
      id: editingTemplateId!,
      name: name.trim().isEmpty ? 'Untitled template' : name.trim(),
      createdAt: DateTime.now(), // Will be overwritten if we look up existing, but let's look up existing
      videoFolders: home.videoFolders,
      audioFolders: home.audioFolders,
      outputFolder: home.outputFolderPath,
      outputPrefix: home.outputNamePrefix,
      branding: home.activeBrandingSettings ?? branding.settings,
      textOverlay: home.activeTextOverlaySettings ?? textOverlay.settings,
      overlaySettings: overlaySettings,
      useBranding: home.useBranding,
      useTextOverlay: home.useTextOverlay,
      useOverlay: home.useOverlay || overlaySettings.hasContent,
      outputSize: home.outputSize,
      fitMode: home.fitMode,
    );

    final existingIndex = templates.indexWhere((t) => t.id == editingTemplateId);
    if (existingIndex >= 0) {
      final existing = templates[existingIndex];
      final updated = ProjectTemplate(
        id: template.id,
        name: template.name,
        createdAt: existing.createdAt,
        videoFolders: template.videoFolders,
        audioFolders: template.audioFolders,
        outputFolder: template.outputFolder,
        outputPrefix: template.outputPrefix,
        branding: template.branding,
        textOverlay: template.textOverlay,
        overlaySettings: template.overlaySettings,
        useBranding: template.useBranding,
        useTextOverlay: template.useTextOverlay,
        useOverlay: template.useOverlay,
        outputSize: template.outputSize,
        fitMode: template.fitMode,
      );
      templates = [
        ...templates.sublist(0, existingIndex),
        updated,
        ...templates.sublist(existingIndex + 1),
      ];
    } else {
      templates = [template, ...templates];
    }

    await _service.saveAll(templates);
    editingTemplateId = null;
    hasUnsavedTemplateChanges = false;
    message = 'Template updated.';
    notifyListeners();
  }

  Future<void> loadTemplate({
    required ProjectTemplate template,
    required HomeController home,
    required BrandingController branding,
    required TextOverlayController textOverlay,
    required OverlayToolsController overlay,
    bool useDeepCopyForOverlay = false,
  }) async {
    await home.applyTemplateFolders(
      videoFolders: template.videoFolders,
      audioFolders: template.audioFolders,
      outputFolder: template.outputFolder,
      outputPrefix: template.outputPrefix,
    );
    await branding.update(template.branding);
    await textOverlay.update(template.textOverlay);
    
    if (useDeepCopyForOverlay) {
      await overlay.loadOverlaySettings(template.overlaySettings.deepCopy());
    } else {
      await overlay.applySettings(template.overlaySettings);
    }
    
    home.applyGeneratorSettings(
      useBranding: template.useBranding,
      useTextOverlay: template.useTextOverlay,
      useOverlay: template.useOverlay,
      outputSize: template.outputSize,
      fitMode: template.fitMode,
      brandingSettings: template.branding,
      textOverlaySettings: template.textOverlay,
      overlaySettings: template.overlaySettings,
    );
    message = 'Template loaded.';
    notifyListeners();
  }

  Future<void> renameTemplate({
    required ProjectTemplate template,
    required String name,
  }) async {
    final updatedName = name.trim();
    if (updatedName.isEmpty) return;
    templates = [
      for (final item in templates)
        if (item.id == template.id)
          ProjectTemplate(
            id: item.id,
            name: updatedName,
            createdAt: item.createdAt,
            videoFolders: item.videoFolders,
            audioFolders: item.audioFolders,
            outputFolder: item.outputFolder,
            outputPrefix: item.outputPrefix,
            branding: item.branding,
            textOverlay: item.textOverlay,
            overlaySettings: item.overlaySettings,
            useBranding: item.useBranding,
            useTextOverlay: item.useTextOverlay,
            useOverlay: item.useOverlay,
            outputSize: item.outputSize,
            fitMode: item.fitMode,
          )
        else
          item,
    ];
    await _service.saveAll(templates);
    message = 'Template renamed.';
    notifyListeners();
  }

  Future<void> deleteTemplate(ProjectTemplate template) async {
    templates = templates.where((item) => item.id != template.id).toList();
    await _service.saveAll(templates);
    message = 'Template deleted.';
    notifyListeners();
  }

  Future<void> updateTemplates(List<ProjectTemplate> nextTemplates) async {
    templates = nextTemplates;
    await _service.saveAll(templates);
    notifyListeners();
  }
}
