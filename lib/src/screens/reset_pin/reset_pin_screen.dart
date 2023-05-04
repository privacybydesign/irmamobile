import 'package:flutter/material.dart';

import 'package:flutter_svg/svg.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/yivi_themed_button.dart';
import '../session/widgets/dynamic_layout.dart';
import '../settings/settings_screen.dart';

class ResetPinScreen extends StatelessWidget {
  static const String routeName = '/reset';

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.height < 670;

    return Scaffold(
      appBar: const IrmaAppBar(
        titleTranslationKey: 'reset_pin.title',
      ),
      body: DynamicLayout(
        hero: SvgPicture.asset(
          'assets/reset/forgot_pin_illustration.svg',
          height: isSmallScreen ? 250 : null,
        ),
        content: Column(
          children: [
            TranslatedText(
              'reset_pin.header',
              style: theme.themeData.textTheme.displaySmall!.copyWith(
                color: theme.dark,
              ),
            ),
            SizedBox(
              height: theme.tinySpacing,
            ),
            TranslatedText(
              'reset_pin.explanation',
              style: theme.themeData.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          YiviThemedButton(
            style: YiviButtonStyle.outlined,
            label: 'ui.cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          YiviThemedButton(
            label: 'reset_pin.reset',
            onPressed: () => showConfirmDeleteDialog(context),
          ),
        ],
      ),
    );
  }
}
