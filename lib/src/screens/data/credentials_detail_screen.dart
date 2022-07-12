import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../models/credentials.dart';
import '../../theme/theme.dart';
import '../../widgets/credential_card/irma_credential_card.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_repository_provider.dart';

class CredentialsDetailScreen extends StatefulWidget {
  final String credentialTypeId;

  const CredentialsDetailScreen({
    required this.credentialTypeId,
  });

  @override
  State<CredentialsDetailScreen> createState() => _DataDetailScreenState();
}

class _DataDetailScreenState extends State<CredentialsDetailScreen> {
  List<Credential> credentials = [];
  late final StreamSubscription<Credentials> credentialStreamSubscription;

  void _credentialStreamListener(Credentials newCredentials) => setState(
        () => (credentials =
            newCredentials.values.where((cred) => cred.info.credentialType.fullId == widget.credentialTypeId).toList()),
      );

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance?.addPostFrameCallback((_) {
      credentialStreamSubscription =
          IrmaRepositoryProvider.of(context).getCredentials().listen(_credentialStreamListener);
    });
  }

  @override
  void dispose() {
    credentialStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IrmaAppBar(
        titleTranslationKey: 'data.detail.title',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: IrmaTheme.of(context).smallSpacing,
        ),
        child: Column(
          children: credentials.map((cred) => IrmaCredentialCard.fromCredential(cred)).toList(),
        ),
      ),
    );
  }
}
