import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/irma_repository.dart';
import '../../models/credentials.dart';
import '../../providers/irma_repository_provider.dart';
import '../../theme/theme.dart';
import '../../util/navigation.dart';
import '../../widgets/credential_card/irma_credential_type_card.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_icon_button.dart';

class DataTab extends StatefulWidget {
  @override
  State<DataTab> createState() => _DataTabState();
}

class _DataTabState extends State<DataTab> {
  bool enableSearch = false;

  _openSearch() {
    setState(() {
      enableSearch = true;
      _focusNode.requestFocus();
    });
  }

  _closeSearch() {
    setState(() {
      enableSearch = false;
    });
  }

  final _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    if (enableSearch) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: IrmaTheme.of(context).backgroundPrimary,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
                decoration: BoxDecoration(color: theme.backgroundPrimary),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoSearchTextField(focusNode: _focusNode),
                    ),
                    TextButton(
                      onPressed: _closeSearch,
                      child: Text(
                        'Annuleer',
                        style: theme.textButtonTextStyle.copyWith(fontWeight: FontWeight.normal, color: theme.link),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: theme.backgroundTertiary,
                  child: CredentialsList(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: IrmaTheme.of(context).backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'home.nav_bar.data',
        leading: null,
        actions: [
          IrmaIconButton(icon: CupertinoIcons.search, onTap: _openSearch),
          IrmaIconButton(icon: CupertinoIcons.add_circled_solid, onTap: context.pushAddDataScreen),
        ],
      ),
      body: SizedBox(
        height: double.infinity,
        child: CredentialsList(),
      ),
    );
  }
}

// ============================================================================================

class CredentialsList extends ConsumerWidget {
  const CredentialsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final credentials = ref.watch(credentialsProvider(IrmaRepositoryProvider.of(context)));

    return switch (credentials) {
      AsyncData(:final value) => _buildList(context, value),
      AsyncError(:final error) => Text(error.toString()),
      _ => CircularProgressIndicator(),
    };
  }

  Widget _buildList(BuildContext context, Credentials credentials) {
    final theme = IrmaTheme.of(context);
    return ListView(
      padding: EdgeInsets.only(top: theme.defaultSpacing),
      children: [
        ...credentials.values.map(
          (c) {
            return Padding(
              padding:
                  EdgeInsets.only(bottom: theme.smallSpacing, left: theme.defaultSpacing, right: theme.defaultSpacing),
              child: IrmaCredentialTypeCard(
                credType: c.credentialType,
                onTap: () => context.pushCredentialsDetailsScreen(
                  CredentialsDetailsRouteParams(categoryName: c.fullId, credentialTypeId: c.credentialType.fullId),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class CredentialsSearchList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

final credentialsProvider = StreamProviderFamily<Credentials, IrmaRepository>((ref, repo) async* {
  final stream = repo.getCredentials();

  await for (final credentials in stream) {
    yield credentials;
  }
});
