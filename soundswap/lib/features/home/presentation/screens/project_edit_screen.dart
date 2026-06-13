import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';
import 'package:soundswap/features/home/data/models/batch_profile.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/overlay_tools/data/services/overlay_settings_service.dart';
import 'package:soundswap/shared/services/folder_picker_service.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';
import 'package:soundswap/shared/widgets/overlay_preview_canvas.dart';

class ProjectEditScreen extends StatefulWidget {
  const ProjectEditScreen({
    required this.profile,
    required this.homeController,
    super.key,
  });

  final BatchProfile profile;
  final HomeController homeController;

  @override
  State<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends State<ProjectEditScreen> {
  late final OverlayToolsController _overlayController;
  late final TextEditingController _nameController;
  late final TextEditingController _prefixController;
  
  late List<String> _videoFolders;
  late List<String> _audioFolders;
  String _outputFolder = '';
  late VideoOutputSize _outputSize;
  late VideoFitMode _fitMode;

  final _dialogFolderPicker = FolderPickerService();
  
  final bool _showGrid = false;
  String _safeAreaMode = 'none';
  final bool _enableSnapping = true;
  double _zoomScale = 1.0;

  @override
  void initState() {
    super.initState();
    _overlayController = OverlayToolsController(
      settingsService: _IsolatedOverlaySettingsService(widget.profile.overlaySettings),
    );
    _overlayController.settings = widget.profile.overlaySettings;
    _nameController = TextEditingController(text: widget.profile.name);
    _prefixController = TextEditingController(text: widget.profile.outputPrefix);
    
    _videoFolders = List.from(widget.profile.videoFolders);
    _audioFolders = List.from(widget.profile.audioFolders);
    _outputFolder = widget.profile.outputFolderPath ?? '';
    _outputSize = widget.profile.outputSize;
    _fitMode = widget.profile.fitMode;
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _nameController.dispose();
    _prefixController.dispose();
    super.dispose();
  }

  BatchProfile _buildUpdatedProfile() {
    return widget.profile.copyWith(
      name: _nameController.text.trim(),
      outputPrefix: _prefixController.text.trim(),
      videoFolders: _videoFolders,
      audioFolders: _audioFolders,
      outputFolderPath: _outputFolder,
      outputSize: _outputSize,
      fitMode: _fitMode,
      overlaySettings: _overlayController.settings,
      useOverlay: _overlayController.settings.items.isNotEmpty,
    );
  }

  Future<void> _handleSave() async {
    final updated = _buildUpdatedProfile();
    await widget.homeController.updateBatchProfile(updated);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _handleSaveAsNew() async {
    final updated = _buildUpdatedProfile();
    await widget.homeController.createBatchProfileFromExisting(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Project: ${widget.profile.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            onPressed: _handleSaveAsNew,
            icon: const Icon(Icons.copy),
            label: const Text('Save As New'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _handleSave,
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListenableBuilder(
        listenable: _overlayController,
        builder: (context, _) {
          return FeaturePage(
            title: '',
            subtitle: '',
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Wrap(
                    spacing: gap,
                    runSpacing: gap / 2,
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _overlayController.addText,
                        icon: const Icon(Icons.text_fields),
                        label: const Text('Add Text'),
                      ),
                      FilledButton.icon(
                        onPressed: _overlayController.addImage,
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Add Image'),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<VideoOutputSize>(
                        value: _outputSize,
                        items: [
                          for (final size in VideoOutputSize.values)
                            DropdownMenuItem(value: size, child: Text(size.label)),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _outputSize = value);
                        },
                      ),
                      DropdownButton<double>(
                        value: _zoomScale,
                        items: const [
                          DropdownMenuItem(value: 0.5, child: Text('Zoom: 50%')),
                          DropdownMenuItem(value: 1.0, child: Text('Zoom: 100%')),
                          DropdownMenuItem(value: 1.5, child: Text('Zoom: 150%')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _zoomScale = value);
                        },
                      ),
                      DropdownButton<String>(
                        value: _safeAreaMode,
                        items: const [
                          DropdownMenuItem(value: 'none', child: Text('No guides')),
                          DropdownMenuItem(value: 'tiktok', child: Text('TikTok guides')),
                          DropdownMenuItem(value: 'shorts', child: Text('Shorts guides')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _safeAreaMode = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              ResponsiveLayout(
                small: Column(
                  children: [
                    _buildPreview(),
                    SizedBox(height: gap),
                    _buildSettingsPanel(),
                  ],
                ),
                medium: _TwoColumn(
                  left: _buildPreview(),
                  right: _buildSettingsPanel(),
                ),
                large: _TwoColumn(
                  left: _buildPreview(),
                  right: _buildSettingsPanel(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPreview() {
    final gap = AppResponsive.cardGap(context);
    final items = [
      for (final item in _overlayController.settings.items)
        PreviewOverlayItem(
          id: item.id,
          label: item.name.isEmpty ? (item.type == OverlayItemType.image ? 'Image' : 'Text') : item.name,
          kind: item.type == OverlayItemType.image ? PreviewOverlayKind.logo : PreviewOverlayKind.text,
          position: item.position,
          text: item.text,
          imagePath: item.imagePath,
          colorHex: item.colorHex,
          fontSize: item.fontSize,
          width: item.width,
          customHeight: item.customHeight,
          lockAspectRatio: item.lockAspectRatio,
          backgroundBox: item.backgroundBox,
          shadow: item.shadow,
          selected: item.id == _overlayController.selectedItemId || _overlayController.selectedItemIds.contains(item.id),
          opacity: item.opacity,
          layerOrder: item.layerOrder,
          textAlignment: item.textAlignment,
          imageFitMode: item.imageFitMode,
          rotation: item.rotation,
          locked: item.locked,
          hidden: item.hidden,
          folder: item.folder,
          scaleX: item.scaleX,
          scaleY: item.scaleY,
          startTime: item.startTime,
          endTime: item.endTime,
          animationEntrance: item.animationEntrance,
          animationEntranceDuration: item.animationEntranceDuration,
          animationExit: item.animationExit,
          animationExitDuration: item.animationExitDuration,
        ),
    ];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.aspect_ratio, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Live Project Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RepaintBoundary(
              child: OverlayPreviewCanvas(
                outputSize: _outputSize,
                items: items,
                onSelected: _overlayController.selectItem,
                onPositionChanged: _overlayController.moveItem,
                onWidthChanged: _overlayController.resizeItem,
                showGrid: _showGrid,
                safeAreaMode: _safeAreaMode,
                enableSnapping: _enableSnapping,
                zoomScale: _zoomScale,
                currentTime: _overlayController.currentTime,
                selectedItemIds: _overlayController.selectedItemIds,
                onMultiPositionChanged: (positions) {
                  positions.forEach((id, pos) {
                    _overlayController.moveItem(id, pos);
                  });
                },
                onSizeChanged: (id, w, h) {
                  final match = _overlayController.settings.items.firstWhere((e) => e.id == id);
                  _overlayController.updateItem(match.copyWith(width: w, customHeight: h));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Card(
      child: DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Settings'),
                Tab(text: 'Folders'),
                Tab(text: 'Overlays'),
              ],
            ),
            SizedBox(
              height: 600,
              child: TabBarView(
                children: [
                  _buildBasicSettings(),
                  _buildFoldersPanel(),
                  _buildOverlaysPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSettings() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Project Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _prefixController,
            decoration: const InputDecoration(labelText: 'Output Name Prefix', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<VideoFitMode>(
            initialValue: _fitMode,
            decoration: const InputDecoration(labelText: 'Video Fit Mode', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: VideoFitMode.keepOriginal, child: Text('Keep Original')),
              DropdownMenuItem(value: VideoFitMode.fitInsideBlurred, child: Text('Fit Inside Blurred Background')),
              DropdownMenuItem(value: VideoFitMode.fillCrop, child: Text('Fill & Crop')),
              DropdownMenuItem(value: VideoFitMode.stretch, child: Text('Stretch')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _fitMode = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProjectEditMultiFolderPicker(
              label: 'Video Folders',
              paths: _videoFolders,
              onAdd: () async {
                final path = await _dialogFolderPicker.pickFolder(dialogTitle: 'Select video folder');
                if (path != null && mounted) {
                  setState(() {
                    if (!_videoFolders.contains(path)) _videoFolders.add(path);
                  });
                }
              },
              onRemove: (path) => setState(() => _videoFolders.remove(path)),
            ),
            const SizedBox(height: 16),
            _ProjectEditMultiFolderPicker(
              label: 'Audio Folders',
              paths: _audioFolders,
              onAdd: () async {
                final path = await _dialogFolderPicker.pickFolder(dialogTitle: 'Select audio folder');
                if (path != null && mounted) {
                  setState(() {
                    if (!_audioFolders.contains(path)) _audioFolders.add(path);
                  });
                }
              },
              onRemove: (path) => setState(() => _audioFolders.remove(path)),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ListTile(
                title: const Text('Output Folder', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_outputFolder.isEmpty ? 'Not set' : _outputFolder),
                trailing: IconButton(
                  icon: const Icon(Icons.folder_copy_outlined),
                  onPressed: () async {
                    final path = await _dialogFolderPicker.pickFolder(dialogTitle: 'Select output folder');
                    if (path != null && mounted) {
                      setState(() => _outputFolder = path);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlaysPanel() {
    if (_overlayController.settings.items.isEmpty) {
      return const Center(
        child: Text('No overlays configured.\nUse the toolbar buttons to add Text or Image.'),
      );
    }
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: _overlayController.settings.items.length,
      onReorder: _overlayController.reorderItems,
      itemBuilder: (context, index) {
        final overlay = _overlayController.settings.items[index];
        final isSelected = _overlayController.selectedItemIds.contains(overlay.id);

        return Card(
          key: ValueKey(overlay.id),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_indicator),
            ),
            title: Text(overlay.name.isNotEmpty ? overlay.name : (overlay.type == OverlayItemType.text ? overlay.text : 'Image')),
            subtitle: Text(overlay.type == OverlayItemType.text ? 'Text Layer' : 'Image Layer'),
            selected: isSelected,
            onTap: () => _overlayController.selectItem(overlay.id),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                _overlayController.selectItem(overlay.id);
                await _overlayController.removeSelected();
              },
            ),
          ),
        );
      },
    );
  }
}

class _ProjectEditMultiFolderPicker extends StatelessWidget {
  const _ProjectEditMultiFolderPicker({
    required this.label,
    required this.paths,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final List<String> paths;
  final VoidCallback onAdd;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.create_new_folder_outlined),
              onPressed: onAdd,
            ),
          ),
          if (paths.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final path in paths)
                    Chip(
                      label: Text(path, style: const TextStyle(fontSize: 12)),
                      onDeleted: () => onRemove(path),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: left),
        SizedBox(width: AppResponsive.cardGap(context)),
        Expanded(flex: 2, child: right),
      ],
    );
  }
}

class _IsolatedOverlaySettingsService extends OverlaySettingsService {
  _IsolatedOverlaySettingsService(this.initialSettings);
  final OverlaySettings initialSettings;

  @override
  Future<OverlaySettings> load() async => initialSettings;

  @override
  Future<void> save(OverlaySettings settings) async {}
}
