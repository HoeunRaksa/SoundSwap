import 'dart:async';
import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/product_import/data/models/product_row.dart';
import 'package:soundswap/features/product_import/presentation/state/product_import_controller.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';

class ProductImportScreen extends StatefulWidget {
  const ProductImportScreen({required this.controller, super.key});

  final ProductImportController controller;

  @override
  State<ProductImportScreen> createState() => _ProductImportScreenState();
}

class _ProductImportScreenState extends State<ProductImportScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  int _currentPage = 0;
  static const _pageSize = 25;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<ProductRow> get _filtered {
    if (_query.isEmpty) return widget.controller.rows;
    final q = _query.toLowerCase();
    return widget.controller.rows
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            r.price.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q) ||
            r.phone.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final filtered = _filtered;
        final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 9999);
        if (_currentPage >= totalPages) _currentPage = totalPages - 1;
        final start = _currentPage * _pageSize;
        final end = (start + _pageSize).clamp(0, filtered.length);
        final visible = filtered.isEmpty ? <ProductRow>[] : filtered.sublist(start, end);

        return FeaturePage(
          title: 'Product Import',
          subtitle: 'Import product CSV rows for text overlay generation.',
          children: [
            SettingsSection(
              title: 'CSV Import',
              icon: Icons.upload_file_outlined,
              children: [
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: widget.controller.importCsv,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Import CSV'),
                    ),
                    if (widget.controller.sourcePath != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.controller.sourcePath!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppResponsive.bodySize(context) - 2,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.controller.sourcePath == null)
                  Text(
                    'Expected columns: name, price, description, phone',
                    style: TextStyle(
                      fontSize: AppResponsive.bodySize(context) - 2,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (widget.controller.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 16, color: Theme.of(context).colorScheme.onErrorContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.controller.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              fontSize: AppResponsive.bodySize(context) - 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SettingsSection(
              title: widget.controller.rows.isEmpty
                  ? 'Imported Rows'
                  : 'Imported Rows (${widget.controller.rows.length})',
              icon: Icons.table_chart_outlined,
              trailing: widget.controller.rows.isNotEmpty
                  ? SizedBox(
                      width: 240,
                      child: TextField(
                        controller: _searchController,
                         onChanged: (v) {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(const Duration(milliseconds: 300), () {
                            setState(() {
                              _query = v;
                              _currentPage = 0;
                            });
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search products…',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () => setState(() {
                                    _debounce?.cancel();
                                    _searchController.clear();
                                    _query = '';
                                  }),
                                )
                              : null,
                        ),
                      ),
                    )
                  : null,
              children: [
                if (widget.controller.rows.isEmpty)
                  const SizedBox(
                    height: 200,
                    child: EmptyState(
                      icon: Icons.table_chart_outlined,
                      title: 'No products imported',
                      message: 'Import a CSV file with columns: name, price, description, phone.',
                    ),
                  )
                else if (filtered.isEmpty)
                  const SizedBox(
                    height: 160,
                    child: EmptyState(
                      icon: Icons.search_off,
                      title: 'No matching products',
                      message: 'Try a different search term.',
                      compact: true,
                    ),
                  )
                else ...[
                  _ProductsTable(rows: visible),
                  const SizedBox(height: 8),
                  // Pagination bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${start + 1}–$end of ${filtered.length}',
                        style: TextStyle(
                          fontSize: AppResponsive.bodySize(context) - 3,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 18),
                            onPressed: _currentPage > 0
                                ? () => setState(() => _currentPage--)
                                : null,
                            visualDensity: VisualDensity.compact,
                          ),
                          Text(
                            'Page ${_currentPage + 1} of $totalPages',
                            style: TextStyle(
                              fontSize: AppResponsive.bodySize(context) - 3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 18),
                            onPressed: _currentPage < totalPages - 1
                                ? () => setState(() => _currentPage++)
                                : null,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ProductsTable extends StatelessWidget {
  const _ProductsTable({required this.rows});

  final List<ProductRow> rows;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bodySize = AppResponsive.bodySize(context) - 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: AppResponsive.cardGap(context),
          headingRowColor: WidgetStatePropertyAll(
            colorScheme.surfaceContainerHighest,
          ),
          dataRowMinHeight: 36,
          dataRowMaxHeight: 48,
          headingRowHeight: 38,
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Price')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Phone')),
          ],
          rows: [
            for (final (i, row) in rows.indexed)
              DataRow(
                color: WidgetStatePropertyAll(
                  i.isOdd
                      ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                      : null,
                ),
                cells: [
                  DataCell(_Cell(text: row.name, size: bodySize)),
                  DataCell(_Cell(text: row.price, size: bodySize)),
                  DataCell(_Cell(text: row.description, size: bodySize, maxWidth: 300)),
                  DataCell(_Cell(text: row.phone, size: bodySize)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.text, required this.size, this.maxWidth = 180});
  final String text;
  final double size;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: maxWidth,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: size),
      ),
    );
  }
}
