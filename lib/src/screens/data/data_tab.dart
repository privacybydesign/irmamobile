import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/credentials.dart';
import '../../providers/credentials_provider.dart';
import '../../theme/theme.dart';
import '../../util/navigation.dart';
import '../../widgets/credential_card/irma_credential_type_card.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_icon_button.dart';

class YiviSearchBar extends StatelessWidget implements PreferredSizeWidget {
  final FocusNode focusNode;
  final Function() onCancel;
  final Function(String) onQueryChanged;
  final bool hasBorder;

  const YiviSearchBar({
    super.key,
    required this.focusNode,
    required this.onCancel,
    required this.onQueryChanged,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return SafeArea(
      child: Container(
        height: preferredSize.height,
        padding: EdgeInsets.only(left: theme.defaultSpacing, right: theme.smallSpacing),
        decoration: BoxDecoration(
          color: theme.backgroundPrimary,
          border: Border(bottom: BorderSide(color: theme.tertiary)),
        ),
        child: Row(
          children: [
            Expanded(
              child: CupertinoSearchTextField(
                focusNode: focusNode,
                onChanged: onQueryChanged,
              ),
            ),
            TextButton(
              onPressed: onCancel,
              child: Text(
                'Annuleer',
                style: theme.textButtonTextStyle.copyWith(fontWeight: FontWeight.normal, color: theme.link),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class DataTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<DataTab> createState() => _DataTabState();
}

class _DataTabState extends ConsumerState<DataTab> {
  bool _searchActive = false;
  final _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    if (_searchActive) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: theme.backgroundPrimary,
        appBar: YiviSearchBar(focusNode: _focusNode, onCancel: _closeSearch, onQueryChanged: _searchQueryChanged),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ColoredBox(
                  color: theme.backgroundTertiary,
                  child: CredentialsSearchList(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'home.nav_bar.data',
        leading: null,
        actions: [
          IrmaIconButton(icon: CupertinoIcons.search, size: 28, onTap: _openSearch),
          IrmaIconButton(icon: CupertinoIcons.add_circled_solid, size: 28, onTap: context.pushAddDataScreen),
        ],
      ),
      body: SizedBox(
        height: double.infinity,
        child: AllCredentialsList(),
      ),
    );
  }

  _openSearch() {
    _searchQueryChanged('');
    setState(() {
      _searchActive = true;
      _focusNode.requestFocus();
    });
  }

  _closeSearch() {
    setState(() {
      _searchActive = false;
    });
  }

  _searchQueryChanged(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
  }
}

// ============================================================================================

class AllCredentialsList extends ConsumerWidget {
  const AllCredentialsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentials = ref.watch(credentialsProvider);

    return switch (credentials) {
      AsyncData(:final value) => CredentialsList(credentials: value),
      AsyncError(:final error) => Text(error.toString()),
      _ => CircularProgressIndicator(),
    };
  }
}

class CredentialsList extends StatelessWidget {
  const CredentialsList({super.key, required this.credentials});

  final Credentials credentials;

  @override
  Widget build(BuildContext context) {
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
    final credentials = ref.watch(filteredCredentialsProvider);

    return credentials.when(
      skipLoadingOnReload: true,
      data: (data) => CredentialsList(credentials: data),
      loading: () => CircularProgressIndicator(),
      error: (error, trace) => Text(error.toString()),
    );
  }
}

final searchQueryProvider = StateProvider((ref) => '');

final filteredCredentialsProvider = StreamProvider<Credentials>(
  (ref) async* {
    final query = ref.watch(searchQueryProvider);
    final credentials = ref.watch(credentialsProvider);

    if (credentials case AsyncData(:final value)) {
      yield value.rebuiltRemoveWhere((id, credential) => !credential.info.fullId.contains(query));
    }
  },
);
