import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../../../../models/attributes.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/credential_card/irma_credentials_card.dart';
import '../../../../widgets/irma_card.dart';
import '../../../../widgets/irma_step_indicator.dart';
import '../models/template_disclosure_credential.dart';
import 'disclosure_issue_wizard_choice.dart';

class DisclosureIssueWizardStepper extends StatefulWidget {
  final UnmodifiableListView<TemplateDisclosureCredential>? issueWizard;
  final ConDisCon<TemplateDisclosureCredential>? issueWizardChoices;

  const DisclosureIssueWizardStepper({
    this.issueWizard,
    this.issueWizardChoices,
  });

  @override
  State<DisclosureIssueWizardStepper> createState() => _DisclosureIssueWizardStepperState();
}

class _DisclosureIssueWizardStepperState extends State<DisclosureIssueWizardStepper> {
  final scrollController = ItemScrollController();
  int selectedIndex = 0;

  Widget _buildStepperItem(int index, bool isChoiceWizard) {
    // Build the indicator widget
    final Widget indicator = IrmaStepIndicator(
      step: index + 1,
      style: selectedIndex == index
          ? IrmaStepIndicatorStyle.filled
          : selectedIndex > index
              ? IrmaStepIndicatorStyle.success
              : IrmaStepIndicatorStyle.outlined,
    );

    // Build child widget
    Widget child = isChoiceWizard
        //If this item is a choice render choice widgets.
        ? DisclosureIssueWizardChoice(
            choice: widget.issueWizardChoices![index],
            isActive: selectedIndex == index,
          )
        // If not render regular card
        : IrmaCredentialsCard.fromCredentialInfo(
            credentialInfo: widget.issueWizard![index],
            attributes: widget.issueWizard![index].attributes,
            style: selectedIndex == index ? IrmaCardStyle.highlighted : IrmaCardStyle.normal,
          );

    // Wrap the child widget in a color filter to make it look greyed out.
    if (index > selectedIndex) {
      child = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.white.withOpacity(0.5),
          BlendMode.modulate,
        ),
        child: child,
      );
    }

    // Compose a TimelineTile with the indicator and child
    final theme = IrmaTheme.of(context);

    return TimelineTile(
      indicatorStyle: IndicatorStyle(
        indicator: indicator,
        padding: EdgeInsets.all(theme.smallSpacing),
      ),
      endChild: child,
      beforeLineStyle: LineStyle(
        thickness: 1,
        color: theme.themeData.colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isChoiceWizard = widget.issueWizard == null;

    return ScrollablePositionedList.builder(
      shrinkWrap: true,
      //physics: const NeverScrollableScrollPhysics(),
      itemCount: isChoiceWizard ? widget.issueWizardChoices!.length : widget.issueWizard!.length,
      itemScrollController: scrollController,
      itemBuilder: (context, index) => _buildStepperItem(index, isChoiceWizard),
    );
  }
}
