import "package:material_ui/material_ui.dart";

import "../../../widgets/app_toast.dart";

void showSnackbar(BuildContext context, String message) =>
    showAppToast(context, message);
