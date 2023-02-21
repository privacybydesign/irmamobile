import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/translated_text.dart';
import '../../../../widgets/yivi_themed_button.dart';
import '../../widgets/dynamic_layout.dart';
import '../../widgets/session_scaffold.dart';
import '../bloc/disclosure_permission_event.dart';

class DisclosurePermissionIntroductionScreen extends StatelessWidget {
  final Function(DisclosurePermissionBlocEvent) onEvent;
  final Function() onDismiss;

  const DisclosurePermissionIntroductionScreen({
    required this.onEvent,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return SessionScaffold(
      appBarTitle: 'disclosure_permission.introduction.title',
      onDismiss: onDismiss,
      body: DynamicLayout(
        hero: SvgPicture.asset(
          'assets/disclosure/disclosure_intro.svg',
        ),
        content: Column(
          children: [
            TranslatedText(
              'disclosure_permission.introduction.header',
              style: theme.themeData.textTheme.headline3!.copyWith(
                color: theme.dark,
              ),
            ),
            SizedBox(
              height: theme.tinySpacing,
            ),
            TranslatedText(
              'disclosure_permission.introduction.explanation',
              style: theme.themeData.textTheme.bodyText2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          YiviThemedButton(
            label: 'disclosure_permission.introduction.continue',
            onPressed: () => onEvent(
              DisclosurePermissionNextPressed(),
            ),
          )
        ],
      ),
    );
  }
}
