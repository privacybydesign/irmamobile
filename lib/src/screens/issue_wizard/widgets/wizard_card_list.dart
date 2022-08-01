import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';

import '../../../widgets/irma_card.dart';
import '../../../widgets/irma_stepper.dart';

class WizardCardItem {
  final String header;
  final String? subheader;
  final String text;
  final bool completed;

  WizardCardItem({
    required this.header,
    this.subheader,
    required this.text,
    this.completed = false,
  });
}

class WizardCardList extends StatelessWidget {
  final List<WizardCardItem> data;
  final bool completed;

  const WizardCardList({Key? key, required this.data, this.completed = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeItemIndex = data.indexWhere((item) => !item.completed);
    final theme = IrmaTheme.of(context);

    final contents = data
        .map(
          (item) => IrmaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.header,
                    style: theme.textTheme.bodyText2!.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                if (item.subheader != null) Text(item.subheader!, style: theme.textTheme.bodyText2),
                Text(item.text, style: theme.textTheme.bodyText2),
              ],
            ),
          ),
        )
        .toList();

    return IrmaStepper(children: contents, currentIndex: activeItemIndex >= 0 ? activeItemIndex : null);
  }
}
