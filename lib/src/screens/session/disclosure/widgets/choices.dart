import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../models/session.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/credential_card/irma_credentials_card.dart';
import '../../../../widgets/irma_bottom_bar.dart';
import '../../../../widgets/translated_text.dart';
import '../../../activity/widgets/issuer_verifier_header.dart';
import '../../models/template_disclosure_credential.dart';
import '../bloc/disclosure_permission_bloc.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import 'irma_template_credential_card.dart';

class Choices extends StatelessWidget {
  final DisclosurePermissionBloc bloc;
  final RequestorInfo requestor;

  const Choices({
    required this.bloc,
    required this.requestor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final state = bloc.state as DisclosurePermissionChoices;
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IssuerVerifierHeader(title: requestor.name.translate(lang)),
              SizedBox(height: theme.defaultSpacing),
              TranslatedText(
                'disclosure.disclosure_permission.choices.choose_data',
                style: theme.themeData.textTheme.headline3,
              ),
              SizedBox(height: theme.smallSpacing),
              Text(
                FlutterI18n.translate(context, 'disclosure.disclosure_permission.choices.explanation',
                    translationParams: {'requestorName': requestor.name.translate(lang)}),
                style: theme.themeData.textTheme.caption!.copyWith(color: Colors.grey.shade500),
              ),
              SizedBox(height: theme.defaultSpacing),
              for (var stepIndex = 0; stepIndex < state.currentSelection.length; stepIndex++) ...[
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(
                    FlutterI18n.translate(context, 'disclosure.disclosure_permission.choices.step',
                        translationParams: {'stepIndex': (stepIndex + 1).toString()}),
                    style: theme.textTheme.bodyText1,
                  ),
                  GestureDetector(
                      onTap: () => bloc.add(DisclosurePermissionStepSelected(
                            stepIndex:
                                // If is selected set to null to deselect
                                state.selectedStepIndex == stepIndex ? null : stepIndex,
                          )),
                      child: TranslatedText(
                        state.selectedStepIndex == stepIndex
                            ? 'disclosure.disclosure_permission.choices.done'
                            : 'disclosure.disclosure_permission.choices.change_choice',
                        style: theme.textTheme.caption!.copyWith(
                          color: theme.themeData.colorScheme.primary,
                        ),
                      ))
                ]),
                SizedBox(height: theme.smallSpacing),
                if (state.selectedStepIndex == stepIndex)
                  for (var choiceIndex = 0; choiceIndex < state.choices[stepIndex].length; choiceIndex++)
                    for (var cred in state.choices[stepIndex][choiceIndex])
                      cred is TemplateDisclosureCredential
                          ? IrmaCredentialTemplateCard(
                              cred,
                              forceObtainable: true,
                            )
                          : IrmaCredentialsCard(
                              selected: state.choiceIndices[stepIndex] == choiceIndex,
                              attributesByCredential: {
                                cred: cred.attributes,
                              },
                              onTap: () => bloc.add(DisclosurePermissionChoiceUpdated(
                                stepIndex: stepIndex,
                                choiceIndex: choiceIndex,
                              )),
                            )
                else
                  IrmaCredentialsCard(
                    attributesByCredential: {
                      state.currentSelection[stepIndex]: state.currentSelection[stepIndex].attributes
                    },
                  )
              ]
            ],
          ),
        ),
        Align(
            alignment: Alignment.bottomCenter,
            child: IrmaBottomBar(
              primaryButtonLabel: 'disclosure.disclosure_permission.next',
              onPrimaryPressed: () => bloc.add(DisclosurePermissionNextPressed()),
            ))
      ],
    );
  }
}
