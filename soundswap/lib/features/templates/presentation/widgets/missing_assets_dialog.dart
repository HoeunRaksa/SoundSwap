import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:soundswap/features/templates/data/models/project_template.dart';
import 'package:soundswap/features/templates/data/services/template_validator.dart';

class MissingAssetsDialog extends StatefulWidget {
  const MissingAssetsDialog({
    required this.initialMissingAssets,
    required this.initialTemplates,
    super.key,
  });

  final List<MissingAsset> initialMissingAssets;
  final Map<String, ProjectTemplate> initialTemplates;

  @override
  State<MissingAssetsDialog> createState() => _MissingAssetsDialogState();
}

class _MissingAssetsDialogState extends State<MissingAssetsDialog> {
  late List<MissingAsset> _missingAssets;
  late Map<String, ProjectTemplate?> _workingTemplates;
  bool _saveToDisk = false;
  MissingAsset? _selectedAsset;

  @override
  void initState() {
    super.initState();
    _missingAssets = List.from(widget.initialMissingAssets);
    _workingTemplates = Map.from(widget.initialTemplates);
  }

  void _replaceSelectedAsset() async {
    if (_selectedAsset == null) return;
    final asset = _selectedAsset!;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      dialogTitle: 'Select Replacement Image',
    );

    if (result == null || result.files.isEmpty) return;
    final newPath = result.files.first.path;
    if (newPath == null) return;

    setState(() {
      final t = _workingTemplates[asset.templateId];
      if (t != null) {
        if (asset.assetType == AssetType.logo) {
          _workingTemplates[asset.templateId] = t.copyWith(
            branding: t.branding.copyWith(logoPath: newPath),
          );
        } else if (asset.assetType == AssetType.imageOverlay && asset.layerId != null) {
          final newItems = t.overlaySettings.items.map((i) {
            if (i.id == asset.layerId) {
              return i.copyWith(imagePath: newPath);
            }
            return i;
          }).toList();
          _workingTemplates[asset.templateId] = t.copyWith(
            overlaySettings: t.overlaySettings.copyWith(items: newItems),
          );
        }
      }
      _missingAssets.remove(asset);
      _selectedAsset = null;
    });
  }

  void _removeSelectedLayer() {
    if (_selectedAsset == null) return;
    final asset = _selectedAsset!;

    setState(() {
      final t = _workingTemplates[asset.templateId];
      if (t != null) {
        if (asset.assetType == AssetType.logo) {
          _workingTemplates[asset.templateId] = t.copyWith(
            useBranding: false,
          );
        } else if (asset.assetType == AssetType.imageOverlay && asset.layerId != null) {
          final newItems = t.overlaySettings.items.where((i) => i.id != asset.layerId).toList();
          _workingTemplates[asset.templateId] = t.copyWith(
            overlaySettings: t.overlaySettings.copyWith(items: newItems),
          );
        }
      }
      _missingAssets.remove(asset);
      _selectedAsset = null;
    });
  }

  void _removeAllMissingLayers() {
    setState(() {
      for (final asset in _missingAssets) {
        final t = _workingTemplates[asset.templateId];
        if (t != null) {
          if (asset.assetType == AssetType.logo) {
            _workingTemplates[asset.templateId] = t.copyWith(
              useBranding: false,
            );
          } else if (asset.assetType == AssetType.imageOverlay && asset.layerId != null) {
            final newItems = t.overlaySettings.items.where((i) => i.id != asset.layerId).toList();
            _workingTemplates[asset.templateId] = t.copyWith(
              overlaySettings: t.overlaySettings.copyWith(items: newItems),
            );
          }
        }
      }
      _missingAssets.clear();
      _selectedAsset = null;
    });
  }

  void _skipTemplate() {
    if (_selectedAsset == null) return;
    final templateId = _selectedAsset!.templateId;

    setState(() {
      _workingTemplates[templateId] = null;
      _missingAssets.removeWhere((a) => a.templateId == templateId);
      _selectedAsset = null;
    });
  }

  void _submit() {
    Navigator.of(context).pop(
      TemplateValidationResult(
        resolvedTemplates: _workingTemplates,
        saveToDisk: _saveToDisk,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Template Assets Missing'),
      content: SizedBox(
        width: 800,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Some templates selected for this batch have missing assets. Please resolve them before starting.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: _missingAssets.length,
                  itemBuilder: (context, index) {
                    final asset = _missingAssets[index];
                    final isSelected = _selectedAsset == asset;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                      title: Text('Template: ${asset.templateName}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('File: ${asset.assetPath}', style: const TextStyle(color: Colors.red)),
                          Text('Layer: ${asset.layerName ?? "Logo"} (${asset.assetType == AssetType.logo ? "Logo" : "Image Overlay"})'),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _selectedAsset = asset;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _selectedAsset == null ? null : _replaceSelectedAsset,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Replace Selected'),
                ),
                OutlinedButton.icon(
                  onPressed: _selectedAsset == null ? null : _removeSelectedLayer,
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove Selected Layer'),
                ),
                OutlinedButton.icon(
                  onPressed: _selectedAsset == null ? null : _skipTemplate,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Skip Template for Batch'),
                ),
                OutlinedButton.icon(
                  onPressed: _missingAssets.isEmpty ? null : _removeAllMissingLayers,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Remove ALL Missing Layers'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Save these fixes to the original template?'),
              subtitle: const Text('Default is to fix the batch copy only.'),
              value: _saveToDisk,
              onChanged: (val) {
                setState(() => _saveToDisk = val ?? false);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Returns null -> Cancel batch
          child: const Text('Cancel Batch'),
        ),
        FilledButton(
          onPressed: _missingAssets.isEmpty ? _submit : null,
          child: const Text('Continue Batch'),
        ),
      ],
    );
  }
}
