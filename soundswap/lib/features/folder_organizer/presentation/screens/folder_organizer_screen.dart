// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/folder_organizer/data/models/organizer_options.dart';
import 'package:soundswap/features/folder_organizer/data/models/organizer_file_item.dart';
import 'package:soundswap/features/folder_organizer/data/models/organizer_history_record.dart';
import 'package:soundswap/features/folder_organizer/presentation/state/folder_organizer_controller.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';
import 'package:path/path.dart' as p;

class FolderOrganizerScreen extends StatefulWidget {
  const FolderOrganizerScreen({required this.controller, super.key});

  final FolderOrganizerController controller;

  @override
  State<FolderOrganizerScreen> createState() => _FolderOrganizerScreenState();
}

class _FolderOrganizerScreenState extends State<FolderOrganizerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _customImagePrefixController = TextEditingController();
  final TextEditingController _customVideoPrefixController = TextEditingController();
  final TextEditingController _startNumberController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _qualityWidthController = TextEditingController();
  final TextEditingController _qualityHeightController = TextEditingController();

  String _selectedFilter = 'All'; // 'All', 'Move', 'Rename', 'Duplicate', 'Skip', 'Error'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    widget.controller.load();
    _initTextControllers();
    widget.controller.addListener(_onControllerChanged);
  }

  void _initTextControllers() {
    final opts = widget.controller.options;
    _customImagePrefixController.text = opts.customImagePrefix;
    _customVideoPrefixController.text = opts.customVideoPrefix;
    _startNumberController.text = opts.startNumber.toString();
    _qualityWidthController.text = opts.qualityWidth.toString();
    _qualityHeightController.text = opts.qualityHeight.toString();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _tabController.dispose();
    _customImagePrefixController.dispose();
    _customVideoPrefixController.dispose();
    _startNumberController.dispose();
    _searchController.dispose();
    _qualityWidthController.dispose();
    _qualityHeightController.dispose();
    super.dispose();
  }

  void _updateOptions() {
    final startNum = int.tryParse(_startNumberController.text) ?? 1;
    final qWidth = int.tryParse(_qualityWidthController.text) ?? 1080;
    final qHeight = int.tryParse(_qualityHeightController.text) ?? 1920;
    widget.controller.updateOptions(
      widget.controller.options.copyWith(
        customImagePrefix: _customImagePrefixController.text,
        customVideoPrefix: _customVideoPrefixController.text,
        startNumber: startNum,
        qualityWidth: qWidth,
        qualityHeight: qHeight,
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gap = AppResponsive.cardGap(context);
    final controller = widget.controller;

    return FeaturePage(
      title: 'Folder Organizer',
      subtitle: 'Organize files, rename with custom prefixes, and safely manage duplicates across folders.',
      children: [
        // Error & Success Banners
        if (controller.errorMessage != null)
          InlineBanner(
            message: controller.errorMessage!,
            type: BannerType.error,
            onDismiss: () => setState(() => controller.errorMessage = null),
          ),
        if (controller.successMessage != null)
          InlineBanner(
            message: controller.successMessage!,
            type: BannerType.success,
            onDismiss: () => setState(() => controller.successMessage = null),
          ),
        if (controller.infoMessage != null)
          InlineBanner(
            message: controller.infoMessage!,
            type: BannerType.info,
            onDismiss: () => setState(() => controller.infoMessage = null),
          ),

        // Navigation Tabs (Organizer vs History)
        TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(text: 'Organizer Tool', icon: Icon(Icons.folder_copy_outlined)),
            Tab(text: 'History & Undo', icon: Icon(Icons.history_outlined)),
          ],
        ),
        SizedBox(height: gap),

        SizedBox(
          height: 800, // Fixed height area for scrollable tab content
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOrganizerTab(),
              _buildHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizerTab() {
    final controller = widget.controller;
    final gap = AppResponsive.cardGap(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Folder Selection & Scan Control
          _buildFolderSelectionCard(),
          SizedBox(height: gap),

          // Row 2: Scan Options & Stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: _buildOptionsCard(),
              ),
              if (controller.scanStatus != 'idle' || controller.scannedItems.isNotEmpty) ...[
                SizedBox(width: gap),
                Expanded(
                  flex: 3,
                  child: _buildStatsCard(),
                ),
              ],
            ],
          ),
          SizedBox(height: gap),

          // Row 3: Progress indicators (when applying or scanning)
          if (controller.isApplying || controller.isScanning) ...[
            _buildProgressCard(),
            SizedBox(height: gap),
          ],

          // Row 4: Preview system
          if (controller.scannedItems.isNotEmpty) ...[
            _buildPreviewCard(),
            SizedBox(height: gap),
          ],
        ],
      ),
    );
  }

  Widget _buildFolderSelectionCard() {
    final controller = widget.controller;
    final colorScheme = Theme.of(context).colorScheme;
    final gap = AppResponsive.cardGap(context);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target Root Folder',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.rootFolderPath ?? 'Select the directory you want to clean and organize...',
                    style: TextStyle(
                      fontSize: 13,
                      color: controller.rootFolderPath != null
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontFamily: controller.rootFolderPath != null ? 'Consolas' : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: controller.isScanning || controller.isApplying
                  ? null
                  : () => controller.pickRootFolder(),
              icon: const Icon(Icons.folder_open),
              label: const Text('Pick Folder'),
            ),
            if (controller.rootFolderPath != null) ...[
              if (controller.isScanning)
                FilledButton.icon(
                  onPressed: controller.isScanCancelled ? null : () => controller.cancelScan(),
                  icon: controller.isScanCancelled
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.stop),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  label: Text(controller.isScanCancelled ? 'Stopping...' : 'Stop Scan'),
                )
              else
                FilledButton.icon(
                  onPressed: controller.isApplying
                      ? null
                      : () => controller.startScan(),
                  icon: const Icon(Icons.search),
                  label: const Text('Scan Folder'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsCard() {
    final controller = widget.controller;
    final opts = controller.options;
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsSection(
      title: 'Scan & Operation Settings',
      icon: Icons.settings_outlined,
      children: [
        // Basic scan controls
        CheckboxListTile(
          title: const Text('Keep folder structure'),
          subtitle: const Text(
            'ON: organize media inside each folder where it was found (PageA/videos/, PageA/images/…)\n'
            'OFF: collect ALL media from subfolders and organize directly under the selected root folder.',
          ),
          value: opts.keepFolderStructure,
          onChanged: controller.isScanning || controller.isApplying
              ? null
              : (val) => controller.updateOptions(
                    opts.copyWith(
                      keepFolderStructure: val,
                      // Auto-toggle removeEmptyFolders: ON when flattening, OFF when keeping structure
                      removeEmptyFolders: val == false ? true : false,
                    ),
                  ),
          contentPadding: EdgeInsets.zero,
          isThreeLine: true,
        ),
        CheckboxListTile(
          title: const Text('Remove empty folders after organizing'),
          subtitle: Text(
            opts.keepFolderStructure
                ? 'Only removes folders that become completely empty during organization.'
                : 'Removes empty source subfolders after all files have been moved to the root.',
          ),
          value: opts.removeEmptyFolders,
          onChanged: controller.isScanning || controller.isApplying
              ? null
              : (val) => controller.updateOptions(opts.copyWith(removeEmptyFolders: val)),
          contentPadding: EdgeInsets.zero,
          isThreeLine: true,
        ),
        CheckboxListTile(
          title: const Text('Include hidden files/folders'),
          subtitle: const Text('Scan folders/files starting with a dot (e.g. .github)'),
          value: opts.includeHiddenFolders,
          onChanged: controller.isScanning || controller.isApplying
              ? null
              : (val) => controller.updateOptions(opts.copyWith(includeHiddenFolders: val)),
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('Convert HEIC/HEIF to PNG'),
          subtitle: const Text('Convert HEIC/HEIF files to PNG format during organization'),
          value: opts.convertHeicToPng,
          onChanged: controller.isScanning || controller.isApplying
              ? null
              : (val) => controller.updateOptions(opts.copyWith(
                    convertHeicToPng: val,
                    deleteOriginalHeic: val == false ? false : opts.deleteOriginalHeic,
                  )),
          contentPadding: EdgeInsets.zero,
        ),
        if (opts.convertHeicToPng)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: CheckboxListTile(
              title: const Text('Delete original HEIC after successful conversion'),
              subtitle: const Text('Permanently deletes the original HEIC file once PNG verification succeeds'),
              value: opts.deleteOriginalHeic,
              onChanged: controller.isScanning || controller.isApplying
                  ? null
                  : (val) => controller.updateOptions(opts.copyWith(deleteOriginalHeic: val)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        CheckboxListTile(
          title: const Text('Detect duplicate media content'),
          subtitle: const Text('Uses MD5 content hashing (not by filename)'),
          value: opts.detectDuplicates,
          onChanged: controller.isScanning || controller.isApplying
              ? null
              : (val) => controller.updateOptions(opts.copyWith(detectDuplicates: val)),
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('Prefer visual orientation detection'),
          subtitle: const Text('Detects vertical content visually (e.g. pillarboxed video inside landscape frame)'),
          value: opts.preferVisualOrientation,
          onChanged: controller.isScanning || controller.isApplying
              ? null
              : (val) => controller.updateOptions(opts.copyWith(preferVisualOrientation: val)),
          contentPadding: EdgeInsets.zero,
        ),
        
        const Divider(height: 24),
        
        // Auto organization checkbox
        CheckboxListTile(
          title: const Text('Auto-organize files'),
          subtitle: const Text(
            'Type Mode: moves to images/ and videos/\n'
            'Quality Mode: moves to quality subfolders (portrait/highQuality, landscape/highQuality, square/highQuality, portrait/lowQuality, landscape/lowQuality, square/lowQuality)',
          ),
          value: opts.organizeFiles,
          onChanged: controller.isScanning || controller.isApplying
              ? null
              : (val) => controller.updateOptions(opts.copyWith(organizeFiles: val)),
          contentPadding: EdgeInsets.zero,
          isThreeLine: true,
        ),

        if (opts.organizeFiles) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Organization Mode:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Radio<OrganizerMode>(
                      value: OrganizerMode.typeOnly,
                      groupValue: opts.organizeMode,
                      onChanged: controller.isScanning || controller.isApplying
                          ? null
                          : (val) => controller.updateOptions(opts.copyWith(organizeMode: val)),
                    ),
                    const Text('Organize by Type'),
                    const SizedBox(width: 16),
                    Radio<OrganizerMode>(
                      value: OrganizerMode.byQuality,
                      groupValue: opts.organizeMode,
                      onChanged: controller.isScanning || controller.isApplying
                          ? null
                          : (val) => controller.updateOptions(opts.copyWith(organizeMode: val)),
                    ),
                    const Text('Organize by Quality'),
                  ],
                ),
                if (opts.organizeMode == OrganizerMode.byQuality) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.primaryContainer),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.hd_outlined, size: 16, color: colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Quality Threshold (High Quality = ≥ W × H)',
                              style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _qualityWidthController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Min Width (px)',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  hintText: '1080',
                                ),
                                onChanged: (_) => _updateOptions(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _qualityHeightController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Min Height (px)',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  hintText: '1920',
                                ),
                                onChanged: (_) => _updateOptions(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Quality classification rules:\n'
                          '  portrait/highQuality: Portrait (height > width) AND width ≥ 1080 AND height ≥ 1920\n'
                          '  landscape/highQuality: Landscape (width > height) AND width ≥ 1920 AND height ≥ 1080\n'
                          '  square/highQuality: Square (width = height) AND width ≥ 1080 AND height ≥ 1080\n'
                          '  portrait/lowQuality: Portrait (height > width) otherwise\n'
                          '  landscape/lowQuality: Landscape (width > height) otherwise\n'
                          '  square/lowQuality: Square (width = height) otherwise\n'
                          '  Unknown resolution: default to landscape/lowQuality.',
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        const Divider(height: 24),

        // Auto renaming config
        CheckboxListTile(
          title: const Text('Rename files during operation'),
          subtitle: const Text('Paddings and custom prefixes will be applied'),
          value: opts.renameFiles,
          onChanged: controller.isScanning || controller.isApplying
              ? null
              : (val) => controller.updateOptions(opts.copyWith(renameFiles: val)),
          contentPadding: EdgeInsets.zero,
        ),

        if (opts.renameFiles) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rename Mode:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Row(
                  children: [
                    Radio<RenameMode>(
                      value: RenameMode.keepPrefix,
                      groupValue: opts.renameMode,
                      onChanged: (val) => controller.updateOptions(opts.copyWith(renameMode: val)),
                    ),
                    const Text('Keep original prefix'),
                    const SizedBox(width: 16),
                    Radio<RenameMode>(
                      value: RenameMode.custom,
                      groupValue: opts.renameMode,
                      onChanged: (val) => controller.updateOptions(opts.copyWith(renameMode: val)),
                    ),
                    const Text('Custom Prefix'),
                  ],
                ),
                if (opts.renameMode == RenameMode.custom) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customImagePrefixController,
                          decoration: const InputDecoration(
                            labelText: 'Image Prefix',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _updateOptions(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _customVideoPrefixController,
                          decoration: const InputDecoration(
                            labelText: 'Video Prefix',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _updateOptions(),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startNumberController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Start Number',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _updateOptions(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: opts.numberPadding,
                        decoration: const InputDecoration(
                          labelText: 'Padding digits',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 3, child: Text('3 (e.g. 001)')),
                          DropdownMenuItem(value: 4, child: Text('4 (e.g. 0001)')),
                          DropdownMenuItem(value: 5, child: Text('5 (e.g. 00001)')),
                        ],
                        onChanged: (val) => controller.updateOptions(opts.copyWith(numberPadding: val)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        if (opts.detectDuplicates) ...[
          const Divider(height: 24),
          const Text('Duplicate Action Plan', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<DuplicateAction>(
            initialValue: opts.duplicateAction,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: DuplicateAction.move,
                child: Text('Move duplicates to Duplicates/ directory'),
              ),
              const DropdownMenuItem(
                value: DuplicateAction.skip,
                child: Text('Skip duplicates (no action)'),
              ),
              DropdownMenuItem(
                value: DuplicateAction.delete,
                child: Text(
                  'Delete duplicates permanently (Warning: cannot undo)',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ],
            onChanged: (val) => controller.updateOptions(opts.copyWith(duplicateAction: val)),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            title: const Text('Export duplication & action report'),
            subtitle: const Text('Creates reports/organizer-report.txt automatically'),
            value: opts.exportReport,
            onChanged: (val) => controller.updateOptions(opts.copyWith(exportReport: val)),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ],
    );
  }

  Widget _buildStatsCard() {
    final controller = widget.controller;
    final colorScheme = Theme.of(context).colorScheme;
    final gap = AppResponsive.cardGap(context);

    // Calculate duplicate statistics
    final duplicateItems = controller.scannedItems.where((i) => i.isDuplicate).toList();

    return SettingsSection(
      title: 'Scanned Statistics',
      icon: Icons.analytics_outlined,
      children: [
        Container(
          padding: EdgeInsets.all(gap),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildStatRow('Folders scanned', '${controller.foldersScanned}', Icons.folder),
              const Divider(height: 12),
              _buildStatRow('Total files scanned', '${controller.filesScanned}', Icons.description),
              const Divider(height: 12),
              _buildStatRow('Images found', '${controller.imagesCount}', Icons.image, Colors.blue),
              const Divider(height: 12),
              _buildStatRow('Videos found', '${controller.videosCount}', Icons.movie, Colors.purple),
              if (controller.heicFound > 0) ...[
                const Divider(height: 12),
                _buildStatRow('HEIC files found', '${controller.heicFound}', Icons.image_search_outlined, Colors.teal),
              ],
              if (controller.options.detectDuplicates) ...[
                const Divider(height: 12),
                _buildStatRow(
                  'Duplicates candidates',
                  '${duplicateItems.length}',
                  Icons.copy,
                  duplicateItems.isNotEmpty ? Colors.orange : Colors.grey,
                ),
              ],
            ],
          ),
        ),
        if (controller.scanDuration != null) ...[
          const SizedBox(height: 12),
          Text(
            'Scan completed in ${controller.scanDuration!.inSeconds} seconds',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, [Color? color]) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? colorScheme.primary),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    final controller = widget.controller;
    final gap = AppResponsive.cardGap(context);

    final isScanning = controller.isScanning;
    final statusText = isScanning
        ? (controller.scanStatus == 'hashing'
            ? 'Calculating file hashes (${controller.hashedCount} / ${controller.totalToHash})...'
            : controller.scanStatus == 'probing'
                ? 'Probing file resolutions (${controller.probedCount} / ${controller.totalToProbe})...'
                : 'Scanning directories recursively...')
        : 'Applying changes (${(controller.applyProgress * 100).toStringAsFixed(0)}%)...';

    final value = isScanning
        ? (controller.scanStatus == 'hashing' && controller.totalToHash > 0
            ? controller.hashedCount / controller.totalToHash
            : controller.scanStatus == 'probing' && controller.totalToProbe > 0
                ? controller.probedCount / controller.totalToProbe
                : null)
        : controller.applyProgress;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: value,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  statusText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: value),
            if (!isScanning) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text('Moved Images: ${controller.imagesMoved}', style: const TextStyle(fontSize: 12)),
                  Text('Moved Videos: ${controller.videosMoved}', style: const TextStyle(fontSize: 12)),
                  Text('Renamed: ${controller.filesRenamed}', style: const TextStyle(fontSize: 12)),
                  Text('Duplicates Moved: ${controller.duplicatesMoved}', style: const TextStyle(fontSize: 12)),
                  Text('Duplicates Deleted: ${controller.duplicatesDeleted}', style: const TextStyle(fontSize: 12)),
                  Text('Skipped: ${controller.skippedCount}', style: const TextStyle(fontSize: 12)),
                  Text('Failed: ${controller.failedCount}', style: const TextStyle(fontSize: 12)),
                  if (controller.heicFound > 0) ...[
                    Text('HEIC Converted: ${controller.heicConverted}', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                    Text('HEIC Deleted: ${controller.heicDeleted}', style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                    Text('HEIC Failed: ${controller.heicFailed}', style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final controller = widget.controller;
    final colorScheme = Theme.of(context).colorScheme;

    // Apply filtering & search
    final query = _searchController.text.toLowerCase();
    final items = controller.scannedItems.where((item) {
      final nameMatches = item.fileName.toLowerCase().contains(query) ||
          item.originalPath.toLowerCase().contains(query) ||
          (item.newPath != null && item.newPath!.toLowerCase().contains(query));
      
      if (!nameMatches) return false;

      if (_selectedFilter == 'All') {
        return true;
      }
      if (_selectedFilter == 'Move' &&
          (item.action == FileItemAction.move || item.action == FileItemAction.moveAndRename)) {
        return true;
      }
      if (_selectedFilter == 'Rename' &&
          (item.action == FileItemAction.rename || item.action == FileItemAction.moveAndRename)) {
        return true;
      }
      if (_selectedFilter == 'Duplicate' &&
          (item.action == FileItemAction.duplicateMove || item.action == FileItemAction.duplicateDelete)) {
        return true;
      }
      if (_selectedFilter == 'Skip' && item.action == FileItemAction.skip) {
        return true;
      }
      if (_selectedFilter == 'Already Organized' && item.action == FileItemAction.alreadyOrganized) {
        return true;
      }
      if (_selectedFilter == 'Error' && item.action == FileItemAction.error) {
        return true;
      }

      return false;
    }).toList();

    return SettingsSection(
      title: 'Action Preview Planning',
      icon: Icons.preview_outlined,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Clear Button
          TextButton.icon(
            onPressed: controller.isApplying || controller.isScanning
                ? null
                : () {
                    setState(() {
                      controller.scannedItems.clear();
                      controller.scanStatus = 'idle';
                    });
                  },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Preview'),
          ),
          const SizedBox(width: 8),
          // Apply Button
          FilledButton.icon(
            onPressed: controller.isApplying || controller.isScanning ? null : _confirmAndApply,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Apply Operations'),
          ),
        ],
      ),
      children: [
        // Filter bar & Search
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search files or paths...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Wrap(
                spacing: 4,
                children: [
                  _buildFilterChip('All'),
                  _buildFilterChip('Move'),
                  _buildFilterChip('Rename'),
                  if (controller.options.detectDuplicates) _buildFilterChip('Duplicate'),
                  _buildFilterChip('Already Organized'),
                  _buildFilterChip('Skip'),
                  _buildFilterChip('Error'),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),

        // Preview Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          child: Row(
            children: const [
              Expanded(flex: 3, child: Text('File / Current Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 8),
              Expanded(flex: 3, child: Text('Action / Target Path', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 8),
              SizedBox(width: 60, child: Text('Raw Width', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 8),
              SizedBox(width: 60, child: Text('Raw Height', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 8),
              SizedBox(width: 55, child: Text('Rotation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 8),
              SizedBox(width: 75, child: Text('Display Width', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 8),
              SizedBox(width: 75, child: Text('Display Height', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 8),
              SizedBox(width: 80, child: Text('Visual Orient', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 8),
              SizedBox(width: 80, child: Text('Final Orient', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 8),
              SizedBox(width: 100, child: Text('Quality Folder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 8),
              Expanded(flex: 2, child: Text('Reason', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 8),
              SizedBox(width: 56, child: Text('Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
        ),

        // Lazy-loaded files list
        Container(
          height: 380,
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
          ),
          child: items.isEmpty
              ? const Center(child: Text('No files matching current filters'))
              : ListView.builder(
                  itemCount: items.length,
                  itemExtent: 65,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildPreviewRow(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() => _selectedFilter = label);
        }
      },
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildPreviewRow(OrganizerFileItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    
    IconData fileIcon = Icons.insert_drive_file_outlined;
    Color iconColor = colorScheme.onSurfaceVariant;
    if (item.fileType == FileItemType.image) {
      fileIcon = Icons.image_outlined;
      iconColor = Colors.blue.shade700;
    } else if (item.fileType == FileItemType.video) {
      fileIcon = Icons.movie_outlined;
      iconColor = Colors.purple.shade700;
    }

    // Determine badge and color based on action
    Color badgeColor = Colors.grey;
    String badgeText = 'Skip';
    switch (item.action) {
      case FileItemAction.move:
        badgeColor = Colors.blue;
        badgeText = 'Move';
        break;
      case FileItemAction.rename:
        badgeColor = Colors.orange;
        badgeText = 'Rename';
        break;
      case FileItemAction.moveAndRename:
        badgeColor = Colors.teal;
        badgeText = 'Move & Rename';
        break;
      case FileItemAction.duplicateMove:
        badgeColor = Colors.indigo;
        badgeText = 'Duplicate Move';
        break;
      case FileItemAction.duplicateDelete:
        badgeColor = Colors.red;
        badgeText = 'Duplicate Delete';
        break;
      case FileItemAction.alreadyOrganized:
        badgeColor = Colors.green;
        badgeText = 'Already Organized';
        break;
      case FileItemAction.convert:
        badgeColor = Colors.deepPurple;
        badgeText = 'Convert';
        break;
      case FileItemAction.error:
        badgeColor = colorScheme.error;
        badgeText = 'Error';
        break;
      default:
        break;
    }

    final relativeOriginal = widget.controller.rootFolderPath != null
        ? item.originalPath.replaceFirst(widget.controller.rootFolderPath!, '')
        : item.originalPath;

    final relativeNew = item.newPath != null && widget.controller.rootFolderPath != null
        ? item.newPath!.replaceFirst(widget.controller.rootFolderPath!, '')
        : (item.newPath ?? 'DELETED');

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Original path & Icon
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(fileIcon, size: 20, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildSmallBadge(
                            text: p.extension(item.originalPath).replaceAll('.', '').toUpperCase(),
                            color: Colors.blueGrey,
                          ),
                        ],
                      ),
                      Text(
                        relativeOriginal,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11, fontFamily: 'Consolas'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),

          // Target Action & Path
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: badgeColor, width: 0.5),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (item.action != FileItemAction.duplicateDelete)
                      _buildSmallBadge(
                        text: item.newPath != null
                            ? p.extension(item.newPath!).replaceAll('.', '').toUpperCase()
                            : '—',
                        color: Colors.teal.shade700,
                      ),
                    if (item.isDuplicate) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Duplicate of ${p.basename(item.duplicateOfPath ?? "")}',
                        child: Icon(Icons.copy, size: 12, color: Colors.orange.shade700),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  relativeNew,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.action == FileItemAction.duplicateDelete
                        ? colorScheme.error
                        : colorScheme.primary,
                    fontSize: 11,
                    fontFamily: 'Consolas',
                  ),
                ),
              ],
            ),
          ),

          // Raw Width
          SizedBox(
            width: 60,
            child: Text(
              item.width != null ? '${item.width}' : '—',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontFamily: 'Consolas'),
            ),
          ),

          const SizedBox(width: 8),

          // Raw Height
          SizedBox(
            width: 60,
            child: Text(
              item.height != null ? '${item.height}' : '—',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontFamily: 'Consolas'),
            ),
          ),

          const SizedBox(width: 8),

          // Rotation
          SizedBox(
            width: 55,
            child: Text(
              item.rotation != null ? '${item.rotation}°' : '0°',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontFamily: 'Consolas'),
            ),
          ),

          const SizedBox(width: 8),

          // Display Width
          SizedBox(
            width: 75,
            child: Text(
              item.displayWidth != null ? '${item.displayWidth}' : '—',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontFamily: 'Consolas'),
            ),
          ),

          const SizedBox(width: 8),

          // Display Height
          SizedBox(
            width: 75,
            child: Text(
              item.displayHeight != null ? '${item.displayHeight}' : '—',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontFamily: 'Consolas'),
            ),
          ),

          const SizedBox(width: 8),

          // Visual Orientation badge
          SizedBox(
            width: 80,
            child: item.visualOrientation != null
                ? _buildSmallBadge(
                    text: item.visualOrientation == MediaOrientation.vertical
                        ? 'Portrait'
                        : item.visualOrientation == MediaOrientation.landscape
                            ? 'Landscape'
                            : 'Square',
                    color: item.visualOrientation == MediaOrientation.vertical
                        ? Colors.purple
                        : item.visualOrientation == MediaOrientation.landscape
                            ? Colors.blue
                            : Colors.teal,
                  )
                : const Text('—', style: TextStyle(fontSize: 11), textAlign: TextAlign.center),
          ),

          const SizedBox(width: 8),

          // Final Orientation badge
          SizedBox(
            width: 80,
            child: item.finalOrientation != null
                ? _buildSmallBadge(
                    text: item.finalOrientation == MediaOrientation.vertical
                        ? 'Portrait'
                        : item.finalOrientation == MediaOrientation.landscape
                            ? 'Landscape'
                            : 'Square',
                    color: item.finalOrientation == MediaOrientation.vertical
                        ? Colors.purple
                        : item.finalOrientation == MediaOrientation.landscape
                            ? Colors.blue
                            : Colors.teal,
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(width: 8),

          // Quality Folder badge
          SizedBox(
            width: 100,
            child: item.qualityGroup != null
                ? _buildSmallBadge(
                    text: _getQualityLabel(item.qualityGroup!),
                    color: _getQualityColor(item.qualityGroup!),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(width: 8),

          // Reason
          Expanded(
            flex: 2,
            child: Text(
              item.reason ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
            ),
          ),

          const SizedBox(width: 8),

          // File Size
          SizedBox(
            width: 56,
            child: Text(
              _formatSize(item.sizeBytes),
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge({required String text, required Color color}) {
    // Darken text by using the color with no alpha adjustment
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.5),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _getQualityLabel(String quality) {
    switch (quality) {
      case 'portrait/highQuality':
        return 'Portrait | High Quality';
      case 'landscape/highQuality':
        return 'Landscape | High Quality';
      case 'square/highQuality':
        return 'Square | High Quality';
      case 'portrait/lowQuality':
        return 'Portrait | Low Quality';
      case 'landscape/lowQuality':
        return 'Landscape | Low Quality';
      case 'square/lowQuality':
        return 'Square | Low Quality';
      default:
        return quality;
    }
  }

  Color _getQualityColor(String quality) {
    switch (quality) {
      case 'portrait/highQuality':
        return Colors.green;
      case 'landscape/highQuality':
        return Colors.blue;
      case 'square/highQuality':
        return Colors.teal;
      case 'portrait/lowQuality':
        return Colors.amber;
      case 'landscape/lowQuality':
        return Colors.orange;
      case 'square/lowQuality':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _confirmAndApply() {
    final controller = widget.controller;
    final movesCount = controller.scannedItems.where((i) => i.action == FileItemAction.move || i.action == FileItemAction.moveAndRename).length;
    final renamesCount = controller.scannedItems.where((i) => i.action == FileItemAction.rename || i.action == FileItemAction.moveAndRename).length;
    final dupMovesCount = controller.scannedItems.where((i) => i.action == FileItemAction.duplicateMove).length;
    final dupDeletesCount = controller.scannedItems.where((i) => i.action == FileItemAction.duplicateDelete).length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Organization Operations'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('SoundSwap will apply the following operations to your folder:'),
              const SizedBox(height: 16),
              if (movesCount > 0)
                _buildConfirmBullet('Move $movesCount files to organized images/ and videos/ subfolders'),
              if (renamesCount > 0)
                _buildConfirmBullet('Rename $renamesCount files using padding and prefixes'),
              if (dupMovesCount > 0)
                _buildConfirmBullet('Move $dupMovesCount identical duplicate files to Duplicates/ folder'),
              if (dupDeletesCount > 0) ...[
                _buildConfirmBullet('PERMANENTLY DELETE $dupDeletesCount duplicate files', true),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Warning: Permanently deleted duplicate files cannot be undone or recovered!',
                          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Are you sure you want to proceed?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.applyChanges();
            },
            child: const Text('Apply Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmBullet(String text, [bool isDanger = false]) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDanger ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 16,
            color: isDanger ? colorScheme.error : colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isDanger ? FontWeight.bold : null,
                color: isDanger ? colorScheme.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final controller = widget.controller;
    final records = controller.historyRecords;

    final hasRecords = records.isNotEmpty;
    final hasApplied = records.any((r) => !r.undoApplied);
    final hasReverted = records.any((r) => r.undoApplied);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              FilledButton.icon(
                onPressed: hasRecords
                    ? () => _confirmClearOrganizerHistory(context)
                    : null,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Clear History'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: hasApplied
                    ? () => _confirmClearAppliedSessions(context)
                    : null,
                icon: const Icon(Icons.done_all),
                label: const Text('Clear Applied'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: hasReverted
                    ? () => _confirmClearRevertedSessions(context)
                    : null,
                icon: const Icon(Icons.undo),
                label: const Text('Clear Reverted'),
              ),
            ],
          ),
        ),
        Expanded(
          child: records.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No organizer history found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'After you apply organization operations, they will show up here.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, idx) {
                    final record = records[idx];
                    return _buildHistoryCard(record);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(OrganizerHistoryRecord record) {
    final controller = widget.controller;
    final colorScheme = Theme.of(context).colorScheme;
    final gap = AppResponsive.cardGap(context);

    final movedCount = record.entries.where((e) => e.action == 'move' || e.action == 'moveAndRename').length;
    final renamedCount = record.entries.where((e) => e.action == 'rename' || e.action == 'moveAndRename').length;
    final duplicateMoves = record.entries.where((e) => e.action == 'duplicateMove').length;
    final duplicateDeletes = record.entries.where((e) => e.action == 'duplicateDelete').length;
    final errorsCount = record.entries.where((e) => e.action == 'error').length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: ID, Date & Undo status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session: ${record.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Executed: ${record.timestamp.toLocal()}',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (record.undoApplied)
                  StatusBadge(label: 'Undone', color: Colors.orange.shade700, icon: Icons.undo)
                else
                  StatusBadge(label: 'Applied', color: Colors.green.shade700, icon: Icons.check),
              ],
            ),
            const Divider(height: 20),
            
            // Stats summary
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _buildHistoryStat('Moved', movedCount),
                _buildHistoryStat('Renamed', renamedCount),
                _buildHistoryStat('Duplicates Moved', duplicateMoves),
                _buildHistoryStat('Duplicates Deleted', duplicateDeletes),
                _buildHistoryStat('Errors', errorsCount, errorsCount > 0 ? colorScheme.error : null),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              'Folder path: ${record.rootFolder}',
              style: TextStyle(fontSize: 11, fontFamily: 'Consolas', color: colorScheme.onSurfaceVariant),
            ),
            
            const Divider(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Export report
                TextButton.icon(
                  onPressed: () => _exportReport(record),
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV Report'),
                ),
                const SizedBox(width: 8),

                // Revert/Undo
                OutlinedButton.icon(
                  onPressed: record.undoApplied || controller.isUndoing
                      ? null
                      : () => _confirmAndUndo(record),
                  icon: controller.isUndoing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.undo),
                  label: const Text('Revert Operations'),
                ),
                const SizedBox(width: 8),

                // Delete Record
                TextButton.icon(
                  onPressed: () => _confirmDeleteRecord(context, record),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Delete Record',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryStat(String label, int count, [Color? valueColor]) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  void _exportReport(OrganizerHistoryRecord record) async {
    final reportCsv = widget.controller.getReportContent(record, 'csv');
    
    // We can write it to the Downloads or Documents directory using file picker
    // For now we'll write it directly into the selected folder under 'Reports' and show a dialog or snackbar
    try {
      final reportDir = Directory(p.join(record.rootFolder, 'Reports'));
      if (!reportDir.existsSync()) {
        await reportDir.create(recursive: true);
      }
      final file = File(p.join(reportDir.path, 'organizer-report-${record.id}.csv'));
      await file.writeAsString(reportCsv);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report exported to: ${file.path}')),
      );
      
      // Open in explorer
      await Process.start('explorer.exe', ['/select,', file.path]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export CSV report: $e')),
      );
    }
  }

  void _confirmAndUndo(OrganizerHistoryRecord record) {
    final controller = widget.controller;
    final containsDeletes = record.entries.any((e) => e.action == 'duplicateDelete');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Undo Folder Organization?'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will revert moved/renamed files back to their original names and locations.'),
            if (containsDeletes) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: Permanently deleted duplicate files cannot be restored. All other files will be moved back.',
                        style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text('Do you want to proceed with reversing these operations?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.undoOperation(record);
            },
            child: const Text('Revert Now'),
          ),
        ],
      ),
    );
  }

  void _confirmClearOrganizerHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Organizer History?'),
        content: const Text(
          'This will permanently delete all organizer logs and undo history cards.\n\n'
          'WARNING: This action only clears history logs. It will NOT affect your actual media files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.controller.clearOrganizerHistory();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAppliedSessions(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Applied Sessions?'),
        content: const Text(
          'This will permanently delete history logs for all applied sessions.\n\n'
          'WARNING: This action only clears history logs. It will NOT affect your actual media files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.controller.clearAppliedSessions();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Clear Applied'),
          ),
        ],
      ),
    );
  }

  void _confirmClearRevertedSessions(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Reverted Sessions?'),
        content: const Text(
          'This will permanently delete history logs for all reverted/undone sessions.\n\n'
          'WARNING: This action only clears history logs. It will NOT affect your actual media files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.controller.clearRevertedSessions();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Clear Reverted'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRecord(BuildContext context, OrganizerHistoryRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete History Record?'),
        content: Text(
          'This will permanently remove the history card for session: ${record.id}.\n\n'
          'WARNING: This action only deletes the history log. It will NOT revert or delete any media files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.controller.deleteHistoryRecord(record);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
