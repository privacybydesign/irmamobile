import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../models/session.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/credential_card/irma_credentials_card.dart';
import '../../../../widgets/irma_card.dart';
import '../../../../widgets/translated_text.dart';
import '../../../activity/widgets/issuer_verifier_header.dart';
import '../../models/template_disclosure_credential.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import 'irma_disclosure_credential_card.dart';

class DisclosureChoices extends StatelessWidget {
  final DisclosurePermissionChoices state;
  final RequestorInfo requestor;
  final Function(DisclosurePermissionBlocEvent) onEvent;

  const DisclosureChoices({
    required this.state,
    required this.requestor,
    required this.onEvent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IssuerVerifierHeader(title: requestor.name.translate(lang)),
        SizedBox(height: theme.defaultSpacing),
        TranslatedText(
          'disclosure_permission.choices.choose_data',
          style: theme.themeData.textTheme.headline3,
        ),
        Padding(
          padding: EdgeInsets.only(
            top: theme.smallSpacing,
            bottom: theme.defaultSpacing,
          ),
          child: Text(
            FlutterI18n.translate(context, 'disclosure_permission.choices.explanation',
                translationParams: {'requestorName': requestor.name.translate(lang)}),
            style: theme.themeData.textTheme.caption!.copyWith(color: Colors.grey.shade500),
          ),
        ),
        for (var stepIndex = 0; stepIndex < state.choices.length; stepIndex++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      FlutterI18n.translate(context, 'disclosure_permission.choices.step',
                          translationParams: {'stepIndex': (stepIndex + 1).toString()}),
                      style: theme.textTheme.bodyText1,
                    ),
                    GestureDetector(
                      onTap: () => onEvent(
                        DisclosurePermissionStepSelected(
                          stepIndex:
                              // If is selected set to null to deselect
                              state.selectedStepIndex == stepIndex ? null : stepIndex,
                        ),
                      ),
                      child: TranslatedText(
                        state.selectedStepIndex == stepIndex
                            ? 'disclosure_permission.choices.done'
                            : 'disclosure_permission.change_choice',
                        style: theme.textTheme.caption!.copyWith(
                          color: theme.themeData.colorScheme.primary,
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(height: theme.smallSpacing),
                if (state.selectedStepIndex == stepIndex)
                  for (var choiceIndex = 0; choiceIndex < state.choices[stepIndex].length; choiceIndex++)
                    for (var cred in state.choices[stepIndex][choiceIndex])
                      cred is TemplateDisclosureCredential
                          ? IrmaDisclosureCredentialCard(
                              cred,
                              style: IrmaCardStyle.template,
                            )
                          : IrmaCredentialsCard(
                              selected: state.choiceIndices[stepIndex] == choiceIndex,
                              attributesByCredential: {
                                cred: cred.attributes,
                              },
                              onTap: () => onEvent(
                                DisclosurePermissionChoiceUpdated(
                                  stepIndex: stepIndex,
                                  choiceIndex: choiceIndex,
                                ),
                              ),
                            )
                else
                  IrmaCredentialsCard(
                    attributesByCredential: {
                      state.currentSelection[stepIndex]: state.currentSelection[stepIndex].attributes
                    },
                  ),
              ],
            ),
          )
      ],
    );
  }
}
