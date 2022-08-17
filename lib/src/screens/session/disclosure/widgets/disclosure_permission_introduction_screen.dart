import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/irma_bottom_bar.dart';
import '../../widgets/session_scaffold.dart';
import 'disclosure_permission_introduction_instruction.dart';

class DisclosurePermissionIntroductionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return SessionScaffold(
      appBarTitle: 'disclosure_permission.introduction.title',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/disclosure/disclosure_intro.svg'),
            SizedBox(height: theme.defaultSpacing),
            DisclosurePermissionIntroductionInstruction()
          ],
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: 'disclosure_permission.introduction.continue',
        onPrimaryPressed: () {}, // TODO: Implement onTap
      ),
    );
  }
}
