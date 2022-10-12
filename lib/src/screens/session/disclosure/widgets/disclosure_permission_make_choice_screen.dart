import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/irma_bottom_bar.dart';
import '../../../../widgets/translated_text.dart';
import '../../widgets/session_scaffold.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import 'disclosure_permission_choice.dart';

class DisclosurePermissionMakeChoiceScreen extends StatefulWidget {
  final DisclosurePermissionMakeChoice state;
  final Function(DisclosurePermissionBlocEvent) onEvent;

  const DisclosurePermissionMakeChoiceScreen({
    required this.state,
    required this.onEvent,
  });

  @override
  State<DisclosurePermissionMakeChoiceScreen> createState() => _DisclosurePermissionMakeChoiceScreenState();
}

class _DisclosurePermissionMakeChoiceScreenState extends State<DisclosurePermissionMakeChoiceScreen> {
  late int selectedConIndex;

  @override
  void initState() {
    super.initState();
    selectedConIndex = widget.state.selectedConIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return SessionScaffold(
      appBarTitle: widget.state is DisclosurePermissionChangeChoice
          ? 'disclosure_permission.change_choice'
          : 'disclosure_permission.choose',
      onPrevious: () => widget.onEvent(
        DisclosurePermissionPreviousPressed(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DisclosurePermissionChoice(
              choice: widget.state.choosableCons,
              selectedConIndex: selectedConIndex,
              onChoiceUpdated: (int conIndex) => setState(
                () => selectedConIndex = conIndex,
              ),
            ),
            if (widget.state.templateCons.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.all(theme.smallSpacing),
                child: TranslatedText(
                  'disclosure_permission.obtain_new',
                  style: theme.themeData.textTheme.headline5,
                ),
              ),
              DisclosurePermissionChoice(
                choice: widget.state.templateCons,
                selectedConIndex: selectedConIndex,
                onChoiceUpdated: (int conIndex) => setState(
                  () => selectedConIndex = conIndex,
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: (selectedConIndex + 1) > widget.state.choosableCons.length
              ? 'disclosure_permission.obtain_data'
              : 'ui.done',
          onPrimaryPressed: () {
            widget.onEvent(DisclosurePermissionChoiceUpdated(conIndex: selectedConIndex));
            widget.onEvent(DisclosurePermissionNextPressed());
          }),
    );
  }
}
