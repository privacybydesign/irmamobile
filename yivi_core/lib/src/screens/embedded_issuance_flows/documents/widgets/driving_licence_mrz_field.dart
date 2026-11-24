import "package:material_ui/material_ui.dart";

import "../../../../util/i18n.dart";
import "document_nr_input_field.dart";

class DrivingLicenceMrzInputField extends StatelessWidget {
  final TextEditingController controller;

  const DrivingLicenceMrzInputField({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    String t(String key) => context.tr("driving_licence.manual.fields.$key");
    final label = t("mrz");
    return DocumentCodeField(
      fieldKey: const Key("driving_licence_mrz_input_field"),
      controller: controller,
      label: label,
      hint: label,
      // Exactly 30 alpha numeric characters (only capital letters allowed)
      pattern: RegExp(r"^[A-Z0-9]{30}$"),
      requiredText: t("mrz_required"),
      invalidText: t("mrz_invalid"),
    );
  }
}
