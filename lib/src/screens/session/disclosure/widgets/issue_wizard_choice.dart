import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/widgets/credential_card/irma_credential_card.dart';

import '../../../../models/attributes.dart';
import '../../models/template_disclosure_credential.dart';
import '../bloc/disclosure_permission_bloc.dart';

class IssueWizardChoice extends StatelessWidget {
  final DisCon<TemplateDisclosureCredential> disCon;

  final DisclosurePermissionBloc bloc;

  IssueWizardChoice({required this.disCon, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(children: []),
    );
  }
}
