import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/product_import/data/models/product_row.dart';
import 'package:soundswap/features/product_import/presentation/state/product_import_controller.dart';
import 'package:soundswap/shared/widgets/empty_state.dart';
import 'package:soundswap/shared/widgets/feature_page.dart';

class ProductImportScreen extends StatelessWidget {
  const ProductImportScreen({required this.controller, super.key});

  final ProductImportController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return FeaturePage(
          title: 'Product Import',
          subtitle:
              'Import product CSV rows for future text overlay generation.',
          children: [
            SettingsSection(
              title: 'CSV import',
              icon: Icons.upload_file_outlined,
              children: [
                OutlinedButton.icon(
                  onPressed: controller.importCsv,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import CSV'),
                ),
                Text(
                  controller.sourcePath ??
                      'Expected columns: name, price, description, phone',
                  style: TextStyle(fontSize: AppResponsive.bodySize(context)),
                ),
                if (controller.errorMessage != null)
                  Text(
                    controller.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
            SettingsSection(
              title: 'Imported rows',
              icon: Icons.list_alt,
              children: [
                if (controller.rows.isEmpty)
                  const SizedBox(
                    height: 180,
                    child: EmptyState(
                      icon: Icons.table_chart_outlined,
                      title: 'No products imported',
                      message: 'Import a CSV file to preview product rows.',
                    ),
                  )
                else
                  _ProductsTable(rows: controller.rows),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: AppResponsive.cardGap(context),
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Price')),
          DataColumn(label: Text('Description')),
          DataColumn(label: Text('Phone')),
        ],
        rows: [
          for (final row in rows)
            DataRow(
              cells: [
                DataCell(Text(row.name)),
                DataCell(Text(row.price)),
                DataCell(Text(row.description)),
                DataCell(Text(row.phone)),
              ],
            ),
        ],
      ),
    );
  }
}
