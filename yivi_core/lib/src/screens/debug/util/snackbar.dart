import "package:material_ui/material_ui.dart";

import "../../../widgets/feedback/app_toast.dart";

void showSnackbar(BuildContext context, String message) =>
    showAppToast(context, message);
