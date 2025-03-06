import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/irma_configuration.dart';
import '../../theme/theme.dart';
import '../../util/navigation.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_icon_button.dart';
import 'widgets/credential_category_list.dart';
import 'widgets/credential_types_builder.dart';

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
                      child: Text('Annuleer', style: theme.textButtonTextStyle),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: theme.backgroundTertiary,
                  child: Center(child: Text('Hello')),
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CredentialTypesBuilder(
                builder: (context, groupedCredentialTypes) => Column(
                  children: groupedCredentialTypes.entries
                      .map(
                        (credentialTypesByCategory) => CredentialCategoryList(
                          categoryName: credentialTypesByCategory.key,
                          credentialTypes: credentialTypesByCategory.value,
                          onCredentialTypeTap: (CredentialType credType) => context.pushCredentialsDetailsScreen(
                            CredentialsDetailsRouteParams(
                              credentialTypeId: credType.fullId,
                              categoryName: credentialTypesByCategory.key,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              SizedBox(
                height: theme.defaultSpacing,
              )
            ],
          ),
        ),
      ),
    );
  }
}
