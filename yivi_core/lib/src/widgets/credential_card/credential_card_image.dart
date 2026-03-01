import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/flutter_svg.dart";

import "../../../package_name.dart";
import "../../models/attribute.dart";
import "../../models/attribute_value.dart";
import "../../models/irma_configuration.dart";

/// Maps credential type fullIds to their corresponding SVG card assets.
/// Falls back to a generic card if no specific card exists.
class CredentialCardImage extends StatefulWidget {
  final CredentialType credentialType;
  final List<Attribute>? attributes;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CredentialCardImage({
    super.key,
    required this.credentialType,
    this.attributes,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  /// Maps credential type IDs to SVG file names.
  /// Format: schemeManagerId.issuerId.credentialId
  static const Map<String, String> _credentialTypeToCard = {
    // PBDF issuer credentials
    "pbdf.pbdf.email": "card_email.svg",
    "pbdf.pbdf.mobilenumber": "card_mobilenumber.svg",
    "pbdf.pbdf.ideal": "card_iban.svg",
    "pbdf.pbdf.idin": "card_iban.svg",

    // SIDN-PBDF issuer credentials
    "pbdf.sidn-pbdf.email": "card_email.svg",
    "pbdf.sidn-pbdf.mobilenumber": "card_mobilenumber.svg",
    "pbdf.sidn-pbdf.irma": "card_generic.svg",

    // Gemeente issuer credentials
    "pbdf.gemeente.personalData": "card_personalData.svg",
    "pbdf.gemeente.address": "card_address.svg",

    // BRP credentials (alternative personal data source)
    "pbdf.pbdf.bsn": "card_personalData.svg",

    // Travel documents - pbdf issuer
    "pbdf.pbdf.passport": "card_passport.svg",
    "pbdf.pbdf.idcard": "card_idcard.svg",
    "pbdf.pbdf.drivinglicense": "card_drivinglicence.svg",
    "pbdf.pbdf.drivinglicence": "card_drivinglicence.svg",

    // Travel documents - pilot-amsterdam issuer
    "pbdf.pilot-amsterdam.passport": "card_passport.svg",
    "pbdf.pilot-amsterdam.idcard": "card_idcard.svg",

    // RDW credentials
    "pbdf.rdw.rijbewijs": "card_drivinglicence.svg",
  };

  /// Maps credential IDs (last part) to SVG file names as fallback.
  static const Map<String, String> _credentialIdToCard = {
    "email": "card_email.svg",
    "mobilenumber": "card_mobilenumber.svg",
    "ideal": "card_iban.svg",
    "idin": "card_iban.svg",
    "personalData": "card_personalData.svg",
    "address": "card_address.svg",
    "passport": "card_passport.svg",
    "idcard": "card_idcard.svg",
    "drivinglicense": "card_drivinglicence.svg",
    "drivinglicence": "card_drivinglicence.svg",
    "rijbewijs": "card_drivinglicence.svg",
  };

  static String getCardAssetPath(String fullId) {
    // First try exact match
    final cardFile = _credentialTypeToCard[fullId];
    if (cardFile != null) {
      return yiviAsset("credential_cards/$cardFile");
    }

    // Fallback: try matching just the credential ID (last part)
    final parts = fullId.split(".");
    if (parts.length >= 3) {
      final credentialId = parts.last;
      final fallbackCard = _credentialIdToCard[credentialId];
      if (fallbackCard != null) {
        return yiviAsset("credential_cards/$fallbackCard");
      }
    }

    return yiviAsset("credential_cards/card_generic.svg");
  }

  @override
  State<CredentialCardImage> createState() => _CredentialCardImageState();
}

class _CredentialCardImageState extends State<CredentialCardImage> {
  String? _processedSvg;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAndProcessSvg();
  }

  @override
  void didUpdateWidget(CredentialCardImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.credentialType.fullId != widget.credentialType.fullId ||
        oldWidget.attributes != widget.attributes) {
      _loadAndProcessSvg();
    }
  }

  Future<void> _loadAndProcessSvg() async {
    setState(() => _loading = true);

    try {
      final assetPath =
          CredentialCardImage.getCardAssetPath(widget.credentialType.fullId);
      final svgString = await rootBundle.loadString(assetPath);
      final processedSvg = _processMustacheTemplate(svgString);

      if (mounted) {
        setState(() {
          _processedSvg = processedSvg;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _processedSvg = null;
          _loading = false;
        });
      }
    }
  }

  String _processMustacheTemplate(String svgTemplate) {
    if (widget.attributes == null || widget.attributes!.isEmpty) {
      // Remove mustache placeholders if no attributes provided
      return svgTemplate.replaceAll(
        RegExp(r"\{\{/[^}]+\}\}"),
        "",
      );
    }

    String result = svgTemplate;

    // Build a map of attribute IDs to their values
    final attributeMap = <String, String>{};
    for (final attr in widget.attributes!) {
      final attrId = attr.attributeType.id;
      String value = "";

      if (attr.value is TextValue) {
        value = (attr.value as TextValue).raw;
      } else if (attr.value is YesNoValue) {
        final yesNo = attr.value as YesNoValue;
        value = yesNo.textValue.raw;
      }

      attributeMap[attrId] = value;
    }

    // Replace Mustache-style placeholders: {{/credentialSubject/attributeId}}
    result = result.replaceAllMapped(
      RegExp(r"\{\{/credentialSubject/([^}]+)\}\}"),
      (match) {
        final attrId = match.group(1);
        return attributeMap[attrId] ?? "";
      },
    );

    // Also handle other placeholder patterns
    result = result.replaceAllMapped(
      RegExp(r"\{\{/attributes/(\d+)/name\}\}"),
      (match) {
        final index = int.tryParse(match.group(1) ?? "");
        if (index != null && index < widget.attributes!.length) {
          return widget.attributes![index].attributeType.name.translate("en");
        }
        return "";
      },
    );

    // Replace remaining mustache placeholders
    result = result.replaceAll(RegExp(r"\{\{/[^}]+\}\}"), "");

    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _processedSvg == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    // Use a key based on the SVG content hash to force rebuild
    return SvgPicture.string(
      _processedSvg!,
      key: ValueKey(_processedSvg.hashCode),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholderBuilder: (context) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// A compact version of the credential card for list views.
/// Displays the card with a fixed aspect ratio (340:215 like a credit card).
class CredentialCardImageCompact extends StatelessWidget {
  final CredentialType credentialType;
  final List<Attribute>? attributes;
  final double height;
  final VoidCallback? onTap;

  const CredentialCardImageCompact({
    super.key,
    required this.credentialType,
    this.attributes,
    this.height = 72.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Credit card aspect ratio: 340:215 ≈ 1.58
    final width = height * (340 / 215);

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: CredentialCardImage(
        credentialType: credentialType,
        attributes: attributes,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
