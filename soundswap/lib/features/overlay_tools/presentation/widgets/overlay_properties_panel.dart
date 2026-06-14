import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';
import 'package:soundswap/shared/widgets/color_picker_field.dart';
import 'package:soundswap/shared/widgets/font_dropdown_widget.dart';

class OverlayPropertiesPanel extends StatefulWidget {
  const OverlayPropertiesPanel({required this.controller, super.key});
  final OverlayToolsController controller;

  @override
  State<OverlayPropertiesPanel> createState() => _OverlayPropertiesPanelState();
}

class _OverlayPropertiesPanelState extends State<OverlayPropertiesPanel> {
  final _nameController = TextEditingController();
  final _textController = TextEditingController();
  final _fontSizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _widthController = TextEditingController();
  final _customHeightController = TextEditingController();
  final _opacityController = TextEditingController();
  final _lineHeightController = TextEditingController();
  final _letterSpacingController = TextEditingController();
  final _rotationController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _strokeWidthController = TextEditingController();
  final _strokeColorController = TextEditingController();
  final _scaleController = TextEditingController();

  final _nameFocus = FocusNode();
  final _textFocus = FocusNode();
  final _fontSizeFocus = FocusNode();
  final _colorFocus = FocusNode();
  final _widthFocus = FocusNode();
  final _customHeightFocus = FocusNode();
  final _opacityFocus = FocusNode();
  final _lineHeightFocus = FocusNode();
  final _letterSpacingFocus = FocusNode();
  final _rotationFocus = FocusNode();
  final _startTimeFocus = FocusNode();
  final _endTimeFocus = FocusNode();
  final _strokeWidthFocus = FocusNode();
  final _strokeColorFocus = FocusNode();
  final _scaleFocus = FocusNode();

  bool _showAdvancedTiming = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncFromState);
    _syncFromState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromState);
    _nameController.dispose();
    _textController.dispose();
    _fontSizeController.dispose();
    _colorController.dispose();
    _widthController.dispose();
    _customHeightController.dispose();
    _opacityController.dispose();
    _lineHeightController.dispose();
    _letterSpacingController.dispose();
    _rotationController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _strokeWidthController.dispose();
    _strokeColorController.dispose();
    _scaleController.dispose();
    
    _nameFocus.dispose();
    _textFocus.dispose();
    _fontSizeFocus.dispose();
    _colorFocus.dispose();
    _widthFocus.dispose();
    _customHeightFocus.dispose();
    _opacityFocus.dispose();
    _lineHeightFocus.dispose();
    _letterSpacingFocus.dispose();
    _rotationFocus.dispose();
    _startTimeFocus.dispose();
    _endTimeFocus.dispose();
    _strokeWidthFocus.dispose();
    _strokeColorFocus.dispose();
    _scaleFocus.dispose();
    super.dispose();
  }

void _syncFromState() {
    final items = widget.controller.settings.items;
    bool hasCustomTiming = false;
    for (final item in items) {
      if (item.startTime > 0 || item.endTime != null || item.animationEntrance != null || item.animationExit != null) {
        hasCustomTiming = true;
        break;
      }
    }
    if (hasCustomTiming && !_showAdvancedTiming) {
      _showAdvancedTiming = true;
    }

    if (_nameFocus.hasFocus ||
        _textFocus.hasFocus ||
        _fontSizeFocus.hasFocus ||
        _colorFocus.hasFocus ||
        _widthFocus.hasFocus ||
        _customHeightFocus.hasFocus ||
        _opacityFocus.hasFocus ||
        _lineHeightFocus.hasFocus ||
        _letterSpacingFocus.hasFocus ||
        _rotationFocus.hasFocus ||
        _startTimeFocus.hasFocus ||
        _endTimeFocus.hasFocus ||
        _strokeWidthFocus.hasFocus ||
        _strokeColorFocus.hasFocus ||
        _scaleFocus.hasFocus) {
      return;
    }
    final item = widget.controller.selectedItem;
    if (item == null) {
      _setText(_nameController, '');
      _setText(_textController, '');
      _setText(_fontSizeController, '');
      _setText(_colorController, '');
      _setText(_widthController, '');
      _setText(_customHeightController, '');
      _setText(_opacityController, '');
      _setText(_lineHeightController, '');
      _setText(_letterSpacingController, '');
      _setText(_rotationController, '');
      _setText(_startTimeController, '');
      _setText(_endTimeController, '');
      _setText(_strokeWidthController, '');
      _setText(_strokeColorController, '');
      _setText(_scaleController, '');
      return;
    }
    _setText(_nameController, item.name);
    _setText(_textController, item.text);
    _setText(_fontSizeController, item.fontSize.toStringAsFixed(0));
    _setText(_colorController, item.colorHex);
    _setText(_widthController, (item.width * 100).toStringAsFixed(0));
    _setText(_customHeightController, item.customHeight != null ? (item.customHeight! * 100).toStringAsFixed(0) : '');
    _setText(_opacityController, (item.opacity * 100).toStringAsFixed(0));
    _setText(_lineHeightController, item.lineHeight.toStringAsFixed(2));
    _setText(_letterSpacingController, item.letterSpacing.toStringAsFixed(1));
    _setText(_rotationController, item.rotation.toStringAsFixed(0));
    _setText(_startTimeController, item.startTime.toStringAsFixed(1));
    _setText(_endTimeController, (item.endTime ?? widget.controller.computedTimelineDuration).toStringAsFixed(1));
    _setText(_strokeWidthController, item.strokeWidth.toStringAsFixed(0));
    _setText(_strokeColorController, item.strokeColorHex);
    _setText(_scaleController, item.scaleX.toStringAsFixed(1));
    
  }

  void _setText(TextEditingController controller, String value) {
    if (controller.text != value) controller.text = value;
  }

  
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => _buildTransformTab(context),
    );
  }

  Widget _buildTransformTab(BuildContext context) {
    final item = widget.controller.selectedItem;
    final gap = AppResponsive.cardGap(context);

    if (item == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.layers_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'No Layer Selected',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select an overlay layer on the canvas or layers panel to adjust properties.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final isText = item.type == OverlayItemType.text;

    bool isOutOfBounds = false;
    if (widget.controller.settings.activeSafeArea != null) {
      final safe = widget.controller.settings.activeSafeArea!;
      final sLeft = safe.left / 1080.0;
      final sRight = 1.0 - (safe.right / 1080.0);
      final sTop = safe.top / 1920.0;
      final sBottom = 1.0 - (safe.bottom / 1920.0);

      final itemRight = item.position.xPercent + item.width;
      final itemBottom = item.position.yPercent + (item.lockAspectRatio ? item.width : (item.customHeight ?? item.width));

      if (item.position.xPercent < sLeft - 0.001 || 
          itemRight > sRight + 0.001 || 
          item.position.yPercent < sTop - 0.001 || 
          itemBottom > sBottom + 0.001) {
        isOutOfBounds = true;
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isOutOfBounds) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.withValues(alpha: 0.1),
                border: Border.all(color: Colors.yellow.shade700),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.yellow.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '⚠️ Overlay may be hidden by platform UI',
                      style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: gap),
          ],
          
          // SECTION 1: LAYER PROPERTIES & MANAGEMENT
          const Text(
            'Layer Info & Management',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            focusNode: _nameFocus,
            decoration: const InputDecoration(
              labelText: 'Layer Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => widget.controller.updateSelected(item.copyWith(name: value)),
          ),
          const SizedBox(height: 8),
          
          // Layer Actions Row: Visibility, Lock, Duplicate, Delete, Z-Order
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Visibility Toggle
              IconButton(
                icon: Icon(item.hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                tooltip: 'Visibility',
                color: item.hidden ? Colors.grey : Theme.of(context).colorScheme.primary,
                onPressed: () => widget.controller.toggleHidden(item.id),
              ),
              // Lock Toggle
              IconButton(
                icon: Icon(item.locked ? Icons.lock : Icons.lock_open),
                tooltip: 'Lock Layer',
                color: item.locked ? Colors.red : Colors.grey,
                onPressed: () => widget.controller.toggleLock(item.id),
              ),
              // Duplicate
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                tooltip: 'Duplicate Layer',
                onPressed: () => widget.controller.duplicateItem(item.id),
              ),
              // Delete
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete Layer',
                onPressed: () async {
                  await widget.controller.removeSelected();
                },
              ),
              // Reorder Up
              IconButton(
                icon: const Icon(Icons.arrow_upward),
                tooltip: 'Bring Forward',
                onPressed: () => widget.controller.bringForward(item.id),
              ),
              // Reorder Down
              IconButton(
                icon: const Icon(Icons.arrow_downward),
                tooltip: 'Send Backward',
                onPressed: () => widget.controller.sendBackward(item.id),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Folder Assignment Dropdown
          DropdownButtonFormField<String?>(
            value: item.folder,
            decoration: const InputDecoration(
              labelText: 'Folder Assignment',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('None (No Folder)')),
              DropdownMenuItem(value: 'Branding', child: Text('Branding')),
              DropdownMenuItem(value: 'Subtitles', child: Text('Subtitles')),
              DropdownMenuItem(value: 'Watermarks', child: Text('Watermarks')),
              DropdownMenuItem(value: 'CTA', child: Text('CTA')),
            ],
            onChanged: (value) {
              widget.controller.setItemFolder(item.id, value);
            },
          ),
          
          const Divider(height: 24),

          // SECTION 2: SPECIFIC SETTINGS (Text / Image)
          if (isText) ...[
            const Text(
              'Text Layer Properties',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              focusNode: _textFocus,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Text Content',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => widget.controller.updateSelected(item.copyWith(text: value)),
            ),
            SizedBox(height: gap),
            DropdownButtonFormField<String>(
              initialValue: item.textAlignment,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Text Alignment',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'left', child: Text('Left')),
                DropdownMenuItem(value: 'center', child: Text('Center')),
                DropdownMenuItem(value: 'right', child: Text('Right')),
              ],
              onChanged: (value) {
                if (value != null) {
                  widget.controller.updateSelected(item.copyWith(textAlignment: value));
                }
              },
            ),
            SizedBox(height: gap),
            FontDropdownWidget(
              currentFontFamily: item.fontFamily,
              onChanged: (value) {
                widget.controller.updateItem(item.copyWith(fontFamily: value));
              },
            ),
            SizedBox(height: gap),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fontSizeController,
                    focusNode: _fontSizeFocus,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Font Size',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final size = double.tryParse(value);
                      if (size != null) {
                        widget.controller.updateSelected(
                          item.copyWith(fontSize: size.clamp(10, 240).toDouble()),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ColorPickerField(
                    label: 'Text Color',
                    colorHex: item.colorHex,
                    onChanged: (val) => widget.controller.updateSelected(item.copyWith(colorHex: val)),
                  ),
                ),
              ],
            ),
            SizedBox(height: gap),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _lineHeightController,
                    focusNode: _lineHeightFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Line Height',
                      hintText: '1.2',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final val = double.tryParse(value);
                      if (val != null) {
                        widget.controller.updateSelected(item.copyWith(lineHeight: val));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _letterSpacingController,
                    focusNode: _letterSpacingFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Letter Spacing',
                      hintText: '0.0',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final val = double.tryParse(value);
                      if (val != null) {
                        widget.controller.updateSelected(item.copyWith(letterSpacing: val));
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: gap),
            
            // Text Stroke Property (strokeWidth, strokeColorHex)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stroke Width: ${item.strokeWidth.toStringAsFixed(0)}px', style: const TextStyle(fontSize: 11)),
                      Slider(
                        value: item.strokeWidth.clamp(0.0, 20.0),
                        min: 0.0,
                        max: 20.0,
                        divisions: 20,
                        onChanged: (val) {
                          widget.controller.updateSelected(item.copyWith(strokeWidth: val));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ColorPickerField(
                    label: 'Stroke Color',
                    colorHex: item.strokeColorHex,
                    onChanged: (val) => widget.controller.updateSelected(item.copyWith(strokeColorHex: val)),
                  ),
                ),
              ],
            ),
            SizedBox(height: gap),
            
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Text Shadow'),
              value: item.shadow,
              onChanged: (value) => widget.controller.updateSelected(item.copyWith(shadow: value)),
            ),
            if (item.shadow) ...[
              ColorPickerField(
                label: 'Shadow Color',
                colorHex: item.shadowColorHex,
                onChanged: (val) => widget.controller.updateSelected(item.copyWith(shadowColorHex: val)),
              ),
              SizedBox(height: gap),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Background Box'),
              value: item.backgroundBox,
              onChanged: (value) => widget.controller.updateSelected(item.copyWith(backgroundBox: value)),
            ),
            if (item.backgroundBox) ...[
              ColorPickerField(
                label: 'Box Color',
                colorHex: item.backgroundBoxColorHex,
                onChanged: (val) => widget.controller.updateSelected(item.copyWith(backgroundBoxColorHex: val)),
              ),
              SizedBox(height: gap),
            ],
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bold'),
                    value: item.bold,
                    onChanged: (value) => widget.controller.updateSelected(item.copyWith(bold: value)),
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Italic'),
                    value: item.italic,
                    onChanged: (value) => widget.controller.updateSelected(item.copyWith(italic: value)),
                  ),
                ),
              ],
            ),
            SizedBox(height: gap),
          ] else ...[
            const Text(
              'Image Layer Properties',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _buildCleanImagePath(context, item.imagePath),
            SizedBox(height: gap),
            DropdownButtonFormField<String>(
              initialValue: item.imageFitMode,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Fit Mode',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'contain', child: Text('Contain')),
                DropdownMenuItem(value: 'cover', child: Text('Cover')),
                DropdownMenuItem(value: 'stretch', child: Text('Stretch')),
              ],
              onChanged: (value) {
                if (value != null) {
                  widget.controller.updateSelected(item.copyWith(imageFitMode: value));
                }
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lock Aspect Ratio'),
              value: item.lockAspectRatio,
              onChanged: (value) {
                widget.controller.updateSelected(
                  item.copyWith(
                    lockAspectRatio: value,
                    customHeight: value ? null : item.width,
                  ),
                );
              },
            ),
            SizedBox(height: gap),
          ],

          const Divider(height: 24),

          // SECTION 3: TRANSFORM (Positioning, Width, Scale, Rotation, Opacity)
          const Text(
            'Transform & Sizing',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          
          // Precision Positioning (X & Y Pos)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('X Pos: ${(item.position.xPercent * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11)),
                    Slider(
                      value: item.position.xPercent.clamp(0.0, 1.0),
                      onChanged: (val) => widget.controller.moveItem(item.id, item.position.copyWith(xPercent: val)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Y Pos: ${(item.position.yPercent * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11)),
                    Slider(
                      value: item.position.yPercent.clamp(0.0, 1.0),
                      onChanged: (val) => widget.controller.moveItem(item.id, item.position.copyWith(yPercent: val)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: gap),
          
          // Width (and Custom Height if aspect ratio is unlocked)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _widthController,
                  focusNode: _widthFocus,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isText ? 'Wrapping Width %' : 'Width %',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final widthVal = double.tryParse(value);
                    if (widthVal != null) {
                      final nextW = widthVal / 100;
                      widget.controller.updateSelected(
                        item.copyWith(
                          width: nextW,
                          customHeight: item.lockAspectRatio ? null : (item.customHeight ?? nextW),
                        ),
                      );
                    }
                  },
                ),
              ),
              if (!isText && !item.lockAspectRatio) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _customHeightController,
                    focusNode: _customHeightFocus,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Height %',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final heightVal = double.tryParse(value);
                      if (heightVal != null) {
                        widget.controller.updateSelected(
                          item.copyWith(customHeight: heightVal / 100),
                        );
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: gap),

          // Scale (Unified vs ScaleX/Y depending on aspect ratio lock)
          if (item.lockAspectRatio) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Scale: ${item.scaleX.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 11)),
                    const Icon(Icons.link, size: 16, color: Colors.grey),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: item.scaleX.clamp(0.1, 3.0),
                        min: 0.1,
                        max: 3.0,
                        onChanged: (val) {
                          widget.controller.updateItem(item.copyWith(scaleX: val, scaleY: val));
                        },
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: _scaleController,
                        focusNode: _scaleFocus,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) {
                            final clamped = parsed.clamp(0.1, 3.0);
                            widget.controller.updateItem(item.copyWith(scaleX: clamped, scaleY: clamped));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Scale X: ${item.scaleX.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11)),
                      Slider(
                        value: item.scaleX.clamp(0.1, 3.0),
                        min: 0.1,
                        max: 3.0,
                        onChanged: (val) => widget.controller.updateItem(item.copyWith(scaleX: val)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Scale Y: ${item.scaleY.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11)),
                      Slider(
                        value: item.scaleY.clamp(0.1, 3.0),
                        min: 0.1,
                        max: 3.0,
                        onChanged: (val) => widget.controller.updateItem(item.copyWith(scaleY: val)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: gap),

          // Rotation Slider & Input
          Row(
            children: [
              const Text('Rotation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: item.rotation,
                  min: 0,
                  max: 360,
                  divisions: 360,
                  onChanged: (value) {
                    widget.controller.updateSelected(item.copyWith(rotation: value.roundToDouble()));
                  },
                ),
              ),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _rotationController,
                  focusNode: _rotationFocus,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    suffixText: '°',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final val = double.tryParse(value);
                    if (val != null) {
                      widget.controller.updateSelected(
                        item.copyWith(rotation: val.clamp(0.0, 360.0)),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: gap),

          // Opacity Slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Opacity: ${(item.opacity * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11)),
              Slider(
                value: item.opacity.clamp(0.0, 1.0),
                onChanged: (val) => widget.controller.updateItem(item.copyWith(opacity: val)),
              ),
            ],
          ),

          const Divider(height: 24),

          // SECTION 4: TIMING & ANIMATIONS
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Timing & Animations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                label: Text('Entire Video'),
                icon: Icon(Icons.video_label),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text('Custom Duration'),
                icon: Icon(Icons.timer),
              ),
            ],
            selected: {item.startTime > 0 || item.endTime != null},
            onSelectionChanged: (value) {
              final isCustom = value.first;
              if (isCustom) {
                widget.controller.updateItem(item.copyWith(
                  startTime: 0.0,
                  endTime: widget.controller.computedTimelineDuration > 5.0 ? 5.0 : widget.controller.computedTimelineDuration,
                ));
              } else {
                widget.controller.updateItem(item.copyWith(
                  startTime: 0.0,
                  clearEndTime: true,
                ));
              }
            },
          ),
          const SizedBox(height: 16),
          
          if (item.startTime > 0 || item.endTime != null) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startTimeController,
                    focusNode: _startTimeFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Start time',
                      border: OutlineInputBorder(),
                      suffixText: 's',
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        widget.controller.updateItem(item.copyWith(
                          startTime: parsed.clamp(0.0, item.endTime ?? widget.controller.computedTimelineDuration),
                        ));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _endTimeController,
                    focusNode: _endTimeFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'End time',
                      border: OutlineInputBorder(),
                      suffixText: 's',
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        widget.controller.updateItem(item.copyWith(
                          endTime: parsed.clamp(item.startTime, widget.controller.computedTimelineDuration),
                        ));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duration: ${item.startTime.toStringAsFixed(1)}s - ${(item.endTime ?? widget.controller.computedTimelineDuration).toStringAsFixed(1)}s (Total: ${((item.endTime ?? widget.controller.computedTimelineDuration) - item.startTime).toStringAsFixed(1)}s)',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                RangeSlider(
                  values: RangeValues(item.startTime, item.endTime ?? widget.controller.computedTimelineDuration),
                  min: 0.0,
                  max: widget.controller.computedTimelineDuration,
                  divisions: (widget.controller.computedTimelineDuration * 2).toInt(),
                  labels: RangeLabels(
                    '${item.startTime.toStringAsFixed(1)}s',
                    '${(item.endTime ?? widget.controller.computedTimelineDuration).toStringAsFixed(1)}s',
                  ),
                  onChanged: (values) {
                    widget.controller.updateItem(item.copyWith(
                      startTime: values.start,
                      endTime: values.end,
                    ));
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          
          // ANIMATIONS CONFIGURATION
          const Text(
            'Entrance Transition',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String?>(
            initialValue: item.animationEntrance,
            decoration: const InputDecoration(
              labelText: 'Fade In / Slide In Effect',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('None (Cut)')),
              DropdownMenuItem(value: 'fade', child: Text('Fade In')),
              DropdownMenuItem(value: 'slide_left', child: Text('Slide from Left')),
              DropdownMenuItem(value: 'slide_right', child: Text('Slide from Right')),
              DropdownMenuItem(value: 'slide_up', child: Text('Slide from Bottom')),
              DropdownMenuItem(value: 'slide_down', child: Text('Slide from Top')),
            ],
            onChanged: (val) => widget.controller.updateItem(item.copyWith(
              animationEntrance: val,
              clearAnimationEntrance: val == null,
            )),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Animation Speed (Entrance Duration):', style: TextStyle(fontSize: 11)),
              Expanded(
                child: Slider(
                  value: item.animationEntranceDuration,
                  min: 0.1,
                  max: 5.0,
                  onChanged: (val) => widget.controller.updateItem(item.copyWith(animationEntranceDuration: val)),
                ),
              ),
              Text('${item.animationEntranceDuration.toStringAsFixed(1)}s', style: const TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          
          const Text(
            'Exit Transition',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String?>(
            initialValue: item.animationExit,
            decoration: const InputDecoration(
              labelText: 'Fade Out / Slide Out Effect',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('None (Cut)')),
              DropdownMenuItem(value: 'fade', child: Text('Fade Out')),
              DropdownMenuItem(value: 'slide_left', child: Text('Slide to Left')),
              DropdownMenuItem(value: 'slide_right', child: Text('Slide to Right')),
              DropdownMenuItem(value: 'slide_up', child: Text('Slide to Top')),
              DropdownMenuItem(value: 'slide_down', child: Text('Slide to Bottom')),
            ],
            onChanged: (val) => widget.controller.updateItem(item.copyWith(
              animationExit: val,
              clearAnimationExit: val == null,
            )),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Animation Speed (Exit Duration):', style: TextStyle(fontSize: 11)),
              Expanded(
                child: Slider(
                  value: item.animationExitDuration,
                  min: 0.1,
                  max: 5.0,
                  onChanged: (val) => widget.controller.updateItem(item.copyWith(animationExitDuration: val)),
                ),
              ),
              Text('${item.animationExitDuration.toStringAsFixed(1)}s', style: const TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              widget.controller.applyTimingToAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Timing & animations applied to all overlays!')),
              );
            },
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('Apply timing to all overlays'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanImagePath(BuildContext context, String? imagePath) {
    final theme = Theme.of(context);
    if (imagePath == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.image_not_supported_outlined, size: 20),
            SizedBox(width: 8),
            Text('No image selected'),
          ],
        ),
      );
    }
    final filename = p.basename(imagePath);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.image_outlined, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  imagePath,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
