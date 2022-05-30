import 'package:flutter/material.dart';
import 'package:irmamobile/src/widgets/irma_step_indicator.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../../../../models/session.dart';
import '../../../../theme/theme.dart';
import '../bloc/disclosure_permission_state.dart';

class DisclosureIssueWizard extends StatelessWidget {
  final RequestorInfo requestor;
  final DisclosurePermissionIssueWizard state;

  const DisclosureIssueWizard({
    required this.requestor,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final stepIndicatorPadding = EdgeInsets.all(theme.smallSpacing);

    const lineStyle = LineStyle(
      thickness: 1,
      color: Colors.blue,
    );

    return ListView(
      shrinkWrap: true,
      children: [
        TimelineTile(
          indicatorStyle: IndicatorStyle(
            indicator: const IrmaStepIndicator(
              step: 1,
              style: IrmaStepIndicatorStyle.success,
            ),
            padding: stepIndicatorPadding,
          ),
          endChild: Container(
            color: Colors.red,
            height: 150,
          ),
          beforeLineStyle: lineStyle,
        ),
        TimelineTile(
          indicatorStyle: IndicatorStyle(
            indicator: const IrmaStepIndicator(step: 2),
            padding: stepIndicatorPadding,
          ),
          endChild: Container(
            color: Colors.green,
            height: 75,
          ),
          beforeLineStyle: lineStyle,
        ),
        TimelineTile(
          indicatorStyle: IndicatorStyle(
            indicator: const IrmaStepIndicator(
              step: 3,
              style: IrmaStepIndicatorStyle.outlined,
            ),
            padding: stepIndicatorPadding,
          ),
          endChild: Container(
            color: Colors.blue,
            height: 75,
          ),
          beforeLineStyle: lineStyle,
        ),
      ],
    );
  }
}
