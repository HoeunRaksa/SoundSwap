import 'package:flutter/material.dart';
import 'package:soundswap/features/fonts/data/services/font_service.dart';
import 'package:soundswap/features/fonts/presentation/screens/fonts_screen.dart';
import 'package:soundswap/features/fonts/presentation/state/fonts_controller.dart';

class FontDropdownWidget extends StatefulWidget {
  final String currentFontFamily;
  final ValueChanged<String> onChanged;

  const FontDropdownWidget({
    super.key,
    required this.currentFontFamily,
    required this.onChanged,
  });

  @override
  State<FontDropdownWidget> createState() => _FontDropdownWidgetState();
}

class _FontDropdownWidgetState extends State<FontDropdownWidget> {
  // Key to force rebuild when reverting "Manage Fonts..."
  Key _dropdownKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FontService(),
      builder: (context, _) {
        final favoriteFamilies = FontService()
            .favoriteFonts
            .map((f) => f.familyName)
            .toSet()
            .toList();

        // Always ensure the currently selected font is in the list to avoid crash
        if (!favoriteFamilies.contains(widget.currentFontFamily)) {
          favoriteFamilies.add(widget.currentFontFamily);
        }

        final items = favoriteFamilies.map((font) {
          return DropdownMenuItem<String>(
            value: font,
            child: Text(font),
          );
        }).toList();

        items.add(const DropdownMenuItem<String>(
          value: '__manage_fonts__',
          child: Text('Manage Fonts...', style: TextStyle(color: Colors.blue)),
        ));

        return DropdownButtonFormField<String>(
          key: _dropdownKey,
          initialValue: widget.currentFontFamily,
          decoration: const InputDecoration(
            labelText: 'Font family',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          isExpanded: true,
          items: items,
          onChanged: (value) {
            if (value == '__manage_fonts__') {
              // Revert dropdown visual selection by changing key
              setState(() {
                _dropdownKey = UniqueKey();
              });
              
              // Navigate to Font Manager
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => FontsScreen(fontsController: FontsController()),
              ));
            } else if (value != null && value != widget.currentFontFamily) {
              widget.onChanged(value);
            }
          },
        );
      },
    );
  }
}
