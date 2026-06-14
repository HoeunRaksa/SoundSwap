import 'package:flutter/material.dart';

class ColorPickerField extends StatefulWidget {
  const ColorPickerField({
    super.key,
    required this.label,
    required this.colorHex,
    required this.onChanged,
  });

  final String label;
  final String colorHex;
  final ValueChanged<String> onChanged;

  @override
  State<ColorPickerField> createState() => _ColorPickerFieldState();
}

class _ColorPickerFieldState extends State<ColorPickerField> {
  late TextEditingController _hexController;
  final FocusNode _focusNode = FocusNode();

  static final List<String> _recentColors = [];
  
  static const List<Map<String, String>> _presetColors = [
    {'name': 'Black', 'hex': '#000000'},
    {'name': 'White', 'hex': '#FFFFFF'},
    {'name': 'Red', 'hex': '#FF0000'},
    {'name': 'Orange', 'hex': '#FFA500'},
    {'name': 'Yellow', 'hex': '#FFFF00'},
    {'name': 'Green', 'hex': '#008000'},
    {'name': 'Blue', 'hex': '#0000FF'},
    {'name': 'Purple', 'hex': '#800080'},
    {'name': 'Pink', 'hex': '#FFC0CB'},
    {'name': 'Brown', 'hex': '#A52A2A'},
    {'name': 'Gray', 'hex': '#808080'},
    {'name': 'Canva Blue', 'hex': '#00C4FF'},
    {'name': 'Canva Purple', 'hex': '#8B3DFF'},
    {'name': 'Construction Orange', 'hex': '#FF7A00'},
  ];

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(text: widget.colorHex);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _hexController.text != widget.colorHex) {
        _submitHex(_hexController.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ColorPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.colorHex != oldWidget.colorHex && !_focusNode.hasFocus) {
      _hexController.text = widget.colorHex;
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitHex(String hex) {
    String formatted = hex.toUpperCase();
    if (!formatted.startsWith('#')) {
      formatted = '#$formatted';
    }
    // Very basic hex validation
    if (formatted.length == 7 || formatted.length == 9) {
      widget.onChanged(formatted);
      _addToRecents(formatted);
    }
  }

  void _addToRecents(String hex) {
    final clean = hex.toUpperCase();
    if (_recentColors.contains(clean)) {
      _recentColors.remove(clean);
    }
    _recentColors.insert(0, clean);
    if (_recentColors.length > 8) {
      _recentColors.removeLast();
    }
  }

  Color _colorFromHex(String hex) {
    String cleanHex = hex.replaceAll('#', '').trim();
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    final int? value = int.tryParse(cleanHex, radix: 16);
    return value == null ? Colors.transparent : Color(value);
  }

  Future<void> _showColorPickerDialog() async {
    final newColor = await showDialog<String>(
      context: context,
      builder: (context) => _ColorPickerDialog(
        initialColorHex: widget.colorHex,
        recentColors: _recentColors,
        presetColors: _presetColors,
      ),
    );

    if (newColor != null && newColor != widget.colorHex) {
      widget.onChanged(newColor);
      _addToRecents(newColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _colorFromHex(widget.colorHex);

    return Row(
      children: [
        GestureDetector(
          onTap: _showColorPickerDialog,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: currentColor,
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _hexController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: _submitHex,
          ),
        ),
      ],
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({
    required this.initialColorHex,
    required this.recentColors,
    required this.presetColors,
  });

  final String initialColorHex;
  final List<String> recentColors;
  final List<Map<String, String>> presetColors;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late TextEditingController _dialogHexController;
  late String _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColorHex;
    _dialogHexController = TextEditingController(text: _currentColor);
  }

  @override
  void dispose() {
    _dialogHexController.dispose();
    super.dispose();
  }

  void _selectColor(String hex) {
    setState(() {
      _currentColor = hex;
      _dialogHexController.text = hex;
    });
  }

  Color _colorFromHex(String hex) {
    String cleanHex = hex.replaceAll('#', '').trim();
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    final int? value = int.tryParse(cleanHex, radix: 16);
    return value == null ? Colors.transparent : Color(value);
  }

  Widget _buildColorSwatch(String hex, {String? tooltip}) {
    final isSelected = _currentColor.toUpperCase() == hex.toUpperCase();
    return Tooltip(
      message: tooltip ?? hex,
      child: GestureDetector(
        onTap: () => _selectColor(hex),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _colorFromHex(hex),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? const Color(0xFF00C4FF) : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 3.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Color'),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _dialogHexController,
                decoration: const InputDecoration(
                  labelText: 'Hex Color',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                onChanged: (val) {
                  if (val.length >= 7) {
                    setState(() {
                      _currentColor = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              if (widget.recentColors.isNotEmpty) ...[
                const Text('Recent Colors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.recentColors.map((hex) => _buildColorSwatch(hex)).toList(),
                ),
                const SizedBox(height: 24),
              ],
              const Text('Preset Palette', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.presetColors.map((preset) {
                  return _buildColorSwatch(preset['hex']!, tooltip: preset['name']);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_currentColor),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
