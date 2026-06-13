import 'package:flutter/material.dart';
import 'package:soundswap/features/fonts/data/services/font_service.dart';


class FontDebugScreen extends StatefulWidget {
  const FontDebugScreen({super.key});

  @override
  State<FontDebugScreen> createState() => _FontDebugScreenState();
}

class _FontDebugScreenState extends State<FontDebugScreen> {
  String? selectedFont;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allFamilies = FontService().allFonts;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Font Debug Screen'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: Font list
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: allFamilies.length,
                      itemBuilder: (context, index) {
                        final family = allFamilies[index];
                        final isSelected = family == selectedFont;
                        return ListTile(
                          title: Text(family),
                          selected: isSelected,
                          onTap: () => setState(() => selectedFont = family),
                        );
                      },
                    ),
                  ),
                ),
                // Right side: Preview
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selected Font Family: $selectedFont', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 32),
                        const Text('Preview:', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        if (selectedFont != null) ...[
                          Text(
                            'សំណង់ទំនើប\n096 388 5024\nSpecial Promotion',
                            style: TextStyle(
                              fontFamily: selectedFont,
                              fontFamilyFallback: const ['Battambang'],
                              fontSize: 48,
                              color: theme.colorScheme.onSurface,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text('Bold & Italic Test:', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 16),
                          Text(
                            'សំណង់ទំនើប\n096 388 5024\nSpecial Promotion',
                            style: TextStyle(
                              fontFamily: selectedFont,
                              fontFamilyFallback: const ['Battambang'],
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurface,
                              height: 1.5,
                            ),
                          ),
                        ] else
                          const Text('Please select a font from the list to preview.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
