import 'package:flutter/material.dart';
import 'package:soundswap/features/fonts/presentation/state/fonts_controller.dart';
import 'package:soundswap/features/fonts/data/services/font_service.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';
import 'package:soundswap/features/fonts/presentation/screens/font_debug_screen.dart';

class FontsScreen extends StatefulWidget {
  const FontsScreen({
    super.key,
    required this.fontsController,
  });

  final FontsController fontsController;

  @override
  State<FontsScreen> createState() => _FontsScreenState();
}

class _FontsScreenState extends State<FontsScreen> {
  @override
  void initState() {
    super.initState();
    widget.fontsController.addListener(_onStateChange);
    if (widget.fontsController.selectedFont == null && 
        widget.fontsController.builtInFonts.isNotEmpty) {
      widget.fontsController.selectFont(widget.fontsController.builtInFonts.first.familyName);
    }
  }

  @override
  void dispose() {
    widget.fontsController.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) {
      setState(() {});
      if (widget.fontsController.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.fontsController.message!)),
        );
        widget.fontsController.clearMessage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredFonts = widget.fontsController.filteredFonts;

    Widget content = FeaturePage(
      title: 'Fonts',
      subtitle: 'Manage fonts. Favorite fonts appear in your Overlay dropdowns.',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              icon: widget.fontsController.isImporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: const Text('Import Custom Font'),
              onPressed: widget.fontsController.isImporting
                  ? null
                  : widget.fontsController.importFont,
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Debug'),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const FontDebugScreen(),
                    ));
                  },
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: widget.fontsController.isScanning
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh),
                  label: const Text('Refresh System Fonts'),
                  onPressed: widget.fontsController.isScanning ? null : widget.fontsController.refresh,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Filters & Search
        Material(
          color: Colors.transparent,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search fonts...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: widget.fontsController.setSearchQuery,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: FontFilter.values.map((filter) {
                      final label = filter.name[0].toUpperCase() + filter.name.substring(1);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: widget.fontsController.currentFilter == filter,
                          onSelected: (val) {
                            if (val) widget.fontsController.setFilter(filter);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 600, // Fixed height for content area
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: List
              Expanded(
                flex: 1,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: filteredFonts.isEmpty
                        ? const Center(child: Text('No fonts found.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: filteredFonts.length,
                            itemBuilder: (context, index) {
                              return _FontListTile(
                                font: filteredFonts[index],
                                controller: widget.fontsController,
                              );
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Right Column: Preview
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preview',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      if (widget.fontsController.selectedFont != null) ...[
                        Text(
                          'Font: ${widget.fontsController.selectedFont}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'សំណង់ទំនើប\n096 388 5024\nSpecial Promotion',
                          style: TextStyle(
                            fontFamily: widget.fontsController.selectedFont,
                            fontFamilyFallback: const ['Battambang'],
                            fontSize: 32,
                            color: theme.colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ] else
                        const Text('Select a font to preview.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final isPushed = ModalRoute.of(context)?.isFirst == false;
    if (isPushed) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        backgroundColor: theme.colorScheme.surface,
        body: content,
      );
    }

    return content;
  }
}

class _FontListTile extends StatefulWidget {
  final AppFont font;
  final FontsController controller;

  const _FontListTile({
    required this.font,
    required this.controller,
  });

  @override
  State<_FontListTile> createState() => _FontListTileState();
}

class _FontListTileState extends State<_FontListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.controller.selectedFont == widget.font.familyName;
    final isFavorite = widget.controller.isFavorite(widget.font.familyName);
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: ListTile(
        title: Text(widget.font.familyName),
        subtitle: widget.font.source == FontSource.windows 
            ? Text(widget.font.filePath, style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis) 
            : null,
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primaryContainer,
        selectedColor: theme.colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        onTap: () {
          widget.controller.selectFont(widget.font.familyName);
        },
        trailing: _isHovered || isFavorite
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? Colors.orange : Colors.grey,
                    ),
                    tooltip: isFavorite ? 'Remove Favorite' : 'Add Favorite',
                    onPressed: () => widget.controller.toggleFavorite(widget.font),
                  ),
                  if (widget.font.source == FontSource.imported)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete font',
                      onPressed: () => _confirmDelete(context, widget.font.familyName),
                    ),
                ],
              )
            : (widget.font.source == FontSource.windows 
                ? const Tooltip(
                    message: 'Windows system font',
                    child: Icon(Icons.computer, size: 16, color: Colors.grey),
                  )
                : null),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String familyName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Font'),
        content: Text('Are you sure you want to delete "$familyName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.controller.deleteFont(familyName);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
