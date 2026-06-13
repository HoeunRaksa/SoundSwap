import 'package:flutter/material.dart';
import 'package:soundswap/core/responsive/app_responsive.dart';
import 'package:soundswap/features/overlay_tools/presentation/state/overlay_tools_controller.dart';
import 'package:soundswap/features/templates/presentation/state/templates_controller.dart';
import '../widgets/overlay_templates_panel.dart';
import 'full_screen_editor_screen.dart';
import 'package:soundswap/features/home/presentation/state/home_controller.dart';
import 'package:soundswap/features/branding/presentation/state/branding_controller.dart';
import 'package:soundswap/features/text_overlay/presentation/state/text_overlay_controller.dart';
import 'package:soundswap/core/video/video_output_settings.dart';

class OverlayToolsScreen extends StatefulWidget {
  const OverlayToolsScreen({
    required this.controller,
    required this.templatesController,
    required this.homeController,
    required this.brandingController,
    required this.textOverlayController,
    super.key,
  });

  final OverlayToolsController controller;
  final TemplatesController templatesController;
  final HomeController homeController;
  final BrandingController brandingController;
  final TextOverlayController textOverlayController;

  @override
  State<OverlayToolsScreen> createState() => _OverlayToolsScreenState();
}

class _OverlayToolsScreenState extends State<OverlayToolsScreen> {
  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.cardGap(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: widget.templatesController,
          builder: (context, _) {

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (similar to FeaturePage but bounded)
                Padding(
                  padding: EdgeInsets.fromLTRB(gap * 2, gap * 2, gap * 2, gap),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overlay & Templates Studio',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontSize: AppResponsive.titleSize(context),
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                      SizedBox(height: gap / 4),
                      Text(
                        'Design overlays with layer folders, precise transforms, alignment tools, asset libraries, workspaces, and timeline animations.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: AppResponsive.bodySize(context),
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),

                // Top Canva-style Toolbar Card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: gap * 2),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Wrap(
                        spacing: gap,
                        runSpacing: gap / 2,
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              widget.templatesController.cancelEditingTemplate();
                              widget.controller.clearCanvas();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => FullScreenEditorScreen(
                                    controller: widget.controller,
                                    templatesController: widget.templatesController,
                                    homeController: widget.homeController,
                                    brandingController: widget.brandingController,
                                    textOverlayController: widget.textOverlayController,
                                    outputSize: VideoOutputSize.vertical1080,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Template'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => FullScreenEditorScreen(
                                    controller: widget.controller,
                                    templatesController: widget.templatesController,
                                    homeController: widget.homeController,
                                    brandingController: widget.brandingController,
                                    textOverlayController: widget.textOverlayController,
                                    outputSize: VideoOutputSize.vertical1080,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.fullscreen),
                            label: const Text('Open Full Screen Editor'),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: gap),

                // Main Workspace: Full Width Template Browser
                Expanded(
                  child: OverlayTemplatesPanel(
                    controller: widget.controller,
                    templatesController: widget.templatesController,
                    homeController: widget.homeController,
                    brandingController: widget.brandingController,
                    textOverlayController: widget.textOverlayController,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
