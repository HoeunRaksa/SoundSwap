import 'package:soundswap/core/video/video_output_settings.dart';
import 'package:soundswap/features/branding/data/models/branding_settings.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_item.dart';
import 'package:soundswap/features/overlay_tools/data/models/overlay_settings.dart';
import 'package:soundswap/features/text_overlay/data/models/text_overlay_settings.dart';

class TemplateRenderData {
  static List<OverlayItem> buildItems({
    required BrandingSettings? branding,
    required TextOverlaySettings? textOverlay,
    required OverlaySettings overlaySettings,
  }) {
    final items = <OverlayItem>[];

    // 1. Branding Logo
    if (branding != null && branding.hasLogo) {
      items.add(
        OverlayItem(
          id: 'branding_logo',
          name: 'Logo',
          type: OverlayItemType.image,
          imagePath: branding.logoPath,
          position: branding.logoPosition,
          width: 0.24, // Typical default logo width
          layerOrder: 900,
          locked: true,
        ),
      );
    }

    // 2. Branding Contact Text
    if (branding != null && branding.hasContactText) {
      items.add(
        OverlayItem(
          id: 'branding_contact_text',
          name: 'Contact Info',
          type: OverlayItemType.text,
          text: branding.contactText,
          position: branding.textPosition,
          fontFamily: branding.fontFamily,
          bold: branding.bold,
          italic: branding.italic,
          fontSize: branding.fontSize,
          colorHex: branding.textColor,
          textAlignment: 'left',
          shadow: true,
          backgroundBox: true,
          layerOrder: 901,
          locked: true,
        ),
      );
    }

    // 3. Text Overlay Titles
    if (textOverlay != null && textOverlay.hasContent) {
      if (textOverlay.title.trim().isNotEmpty) {
        items.add(_buildTextItem('text_overlay_title', 'Title', textOverlay.title, textOverlay.titlePosition, textOverlay, 902));
      }
      if (textOverlay.subtitle.trim().isNotEmpty) {
        items.add(_buildTextItem('text_overlay_subtitle', 'Subtitle', textOverlay.subtitle, textOverlay.subtitlePosition, textOverlay, 903));
      }
      if (textOverlay.promotionText.trim().isNotEmpty) {
        items.add(_buildTextItem('text_overlay_promo', 'Promotion', textOverlay.promotionText, textOverlay.promotionPosition, textOverlay, 904));
      }
      if (textOverlay.priceText.trim().isNotEmpty) {
        items.add(_buildTextItem('text_overlay_price', 'Price', textOverlay.priceText, textOverlay.pricePosition, textOverlay, 905));
      }
    }

    // 4. Custom Overlays
    items.addAll(overlaySettings.items);

    // 5. Sort by layer order
    items.sort((a, b) => a.layerOrder.compareTo(b.layerOrder));

    return items;
  }

  static OverlayItem _buildTextItem(
    String id,
    String name,
    String text,
    NormalizedPosition position,
    TextOverlaySettings settings,
    int layerOrder,
  ) {
    return OverlayItem(
      id: id,
      name: name,
      type: OverlayItemType.text,
      text: text,
      position: position,
      fontFamily: settings.fontFamily,
      bold: settings.bold,
      italic: settings.italic,
      fontSize: settings.fontSize,
      colorHex: settings.textColor,
      shadow: settings.shadow,
      backgroundBox: settings.backgroundBox,
      opacity: settings.opacity,
      textAlignment: settings.textAlignment,
      layerOrder: layerOrder,
      locked: true,
    );
  }
}
