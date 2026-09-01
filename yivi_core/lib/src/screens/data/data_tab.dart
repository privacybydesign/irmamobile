import "dart:math";

import "package:cupertino_ui/cupertino_ui.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../models/credential_events.dart";
import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../providers/irma_repository_provider.dart";
import "../../providers/schemaless_credentials_list_provider.dart";
import "../../providers/schemaless_credentials_provider.dart";
import "../../theme/theme.dart";
import "../../util/navigation.dart";
import "../../widgets/base64_image.dart";
import "../../widgets/credential_card/delete_credential_confirmation_dialog.dart";
import "../../widgets/credential_card/schemaless_yivi_credential_type_card.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_card.dart";
import "../../widgets/irma_icon_button.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/yivi_search_bar.dart";

class DataTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<DataTab> createState() => _DataTabState();
}

class _DataTabState extends ConsumerState<DataTab> {
  bool _searchActive = false;
  final _focusNode = FocusNode();

  // We use the global key of the add_data button to provide the 'pointing man' image with the
  // global location of the button, so it can calculate the correct angle to point to.
  // We don't want a completely global key, as that would cause problems since GoRouter keeps multiple instances
  // of a page alive for transitions, so we have to pass it down the widget tree.
  final _addDataButtonKey = GlobalKey(debugLabel: "add_data_button_key");

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    if (_searchActive) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: theme.backgroundTertiary,
        appBar: YiviSearchBar(
          focusNode: _focusNode,
          onCancel: _closeSearch,
          onQueryChanged: _searchQueryChanged,
        ),
        body: _CredentialsSearchResults(),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: "home.nav_bar.data",
        leading: null,
        actions: [
          IrmaIconButton(
            key: const Key("search_button"),
            icon: CupertinoIcons.search,
            size: 28,
            onTap: _openSearch,
          ),
          IrmaIconButton(
            key: _addDataButtonKey,
            icon: CupertinoIcons.add_circled_solid,
            size: 28,
            onTap: context.pushAddDataScreen,
          ),
        ],
      ),
      body: SafeArea(
        child: SizedBox(
          height: double.infinity,
          child: _AllCredentialsList(addDataButtonKey: _addDataButtonKey),
        ),
      ),
    );
  }

  void _openSearch() {
    _searchQueryChanged("");
    setState(() {
      _searchActive = true;
      _focusNode.requestFocus();
    });
  }

  void _closeSearch() {
    setState(() {
      _searchActive = false;
    });
  }

  void _searchQueryChanged(String query) {
    ref.read(credentialsSearchQueryProvider.notifier).set(query);
  }
}

// ============================================================================================

// Image of a man that always points towards the add data button to indicate that button should be pressed
class _ToAddDataButtonPointingImage extends StatefulWidget {
  const _ToAddDataButtonPointingImage({required this.addDataButtonKey});

  final GlobalKey addDataButtonKey;

  @override
  State<_ToAddDataButtonPointingImage> createState() =>
      _ToAddDataButtonPointingImageState();
}

class _ToAddDataButtonPointingImageState
    extends State<_ToAddDataButtonPointingImage> {
  final _imageKey = GlobalKey(debugLabel: "to_add_data_pointing_image_key");
  static const pi = 3.1415;
  double rotationAngle = 0.0;

  double _calculateRotation() {
    final addDataButtonRenderBox =
        widget.addDataButtonKey.currentContext?.findRenderObject()
            as RenderBox?;
    final imageRenderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;

    if (imageRenderBox == null || addDataButtonRenderBox == null) {
      return 100.0;
    }

    final plusButtonCenter = addDataButtonRenderBox.localToGlobal(
      addDataButtonRenderBox.size.center(Offset.zero),
    );
    final imageCenter = imageRenderBox.localToGlobal(
      imageRenderBox.size.center(Offset.zero),
    );

    final deltaX = plusButtonCenter.dx - imageCenter.dx;
    final deltaY = imageCenter.dy - plusButtonCenter.dy;
    final targetAngle = atan2(deltaY, deltaX);

    final referenceAngleDeg =
        55.0; // angle of the arm inside the image in degrees
    final referenceAngle = referenceAngleDeg * pi / 180.0;

    return targetAngle - referenceAngle;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rotation = _calculateRotation();
      if ((rotationAngle * 10000).round() != (rotation * 10000).round()) {
        setState(() => rotationAngle = rotation);
      }
    });

    return Transform(
      key: const Key("to_add_data_button_pointing_image"),
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateY(pi) // 180-degree flip (π radians)
        ..rotateZ(rotationAngle),
      child: SvgPicture.asset(
        key: _imageKey,
        yiviAsset("arrow_back/pointing_up.svg"),
      ),
    );
  }
}

class _NoCredentialsYet extends StatelessWidget {
  const _NoCredentialsYet({required this.addDataButtonKey});

  final GlobalKey addDataButtonKey;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return _buildPortraitOrientation(context);
        }
        return _buildLandscapeOrientation(context);
      },
    );
  }

  Padding _buildLandscapeOrientation(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Padding(
      padding: EdgeInsets.all(theme.screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  "data_tab.empty.title",
                  style: theme.textTheme.displayLarge,
                  textAlign: TextAlign.start,
                ),
                SizedBox(height: theme.defaultSpacing),
                TranslatedText(
                  "data_tab.empty.subtitle",
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
          _ToAddDataButtonPointingImage(addDataButtonKey: addDataButtonKey),
        ],
      ),
    );
  }

  Padding _buildPortraitOrientation(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Padding(
      padding: EdgeInsets.all(theme.defaultSpacing),
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: theme.defaultSpacing),
            _ToAddDataButtonPointingImage(addDataButtonKey: addDataButtonKey),
            SizedBox(height: theme.largeSpacing),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TranslatedText(
                  "data_tab.empty.title",
                  style: theme.textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: theme.defaultSpacing),
                TranslatedText(
                  "data_tab.empty.subtitle",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AllCredentialsList extends ConsumerWidget {
  const _AllCredentialsList({required this.addDataButtonKey});

  final GlobalKey addDataButtonKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final credentials = ref.watch(schemalessCredentialsProvider);

    return switch (credentials) {
      // Problematic credentials keep the overview non-empty even when every
      // loadable credential is gone, so the user can still see and delete them.
      AsyncData(:final value) =>
        value.credentials.isEmpty && value.problematic.isEmpty
            ? _NoCredentialsYet(addDataButtonKey: addDataButtonKey)
            : _ReorderableCredentialList(),
      AsyncError() => Center(
        child: Padding(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: TranslatedText("error.title", textAlign: TextAlign.center),
        ),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _CredentialsTypeList extends StatelessWidget {
  const _CredentialsTypeList({required this.credentials});

  final List<schemaless.Credential> credentials;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return ListView(
      key: const Key("credentials_type_list"),
      padding: EdgeInsets.only(top: theme.defaultSpacing),
      children: [
        ...credentials.map((c) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: theme.smallSpacing,
              left: theme.defaultSpacing,
              right: theme.defaultSpacing,
            ),
            child: SchemalessYiviCredentialTypeCard(
              credentialId: c.credentialId,
              credentialName: c.name,
              issuerName: c.issuer.name,
              credentialImageBase64: c.image != null
                  ? Base64Image(
                      base64: c.image!.base64,
                      mimeType: c.image!.mimeType,
                    )
                  : null,
              onTap: () => context.pushCredentialsDetailsScreen(
                CredentialsDetailsRouteParams(credentialTypeId: c.credentialId),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _CredentialsSearchResults extends ConsumerWidget {
  Center _buildNoCredentialsFound(BuildContext context, String query) {
    final theme = IrmaTheme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: TranslatedText(
          "data.search.no_results",
          translationParams: {"query": query},
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = FlutterI18n.currentLocale(context)!;
    final credentials = ref.watch(
      schemalessCredentialsSearchResultsProvider(locale),
    );
    final searchQuery = ref.watch(credentialsSearchQueryProvider);

    return credentials.when(
      skipLoadingOnReload: true,
      data: (credentials) => credentials.isEmpty && searchQuery.isNotEmpty
          ? _buildNoCredentialsFound(context, searchQuery)
          : _CredentialsTypeList(credentials: credentials),
      loading: () => CircularProgressIndicator(),
      error: (error, trace) => Text(error.toString()),
    );
  }
}

// ================================================================================

class _ReorderableCredentialList extends ConsumerWidget {
  const _ReorderableCredentialList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentials = ref.watch(schemalessCredentialOrderControllerProvider);
    final controller = ref.read(
      schemalessCredentialOrderControllerProvider.notifier,
    );
    final problematic =
        ref.watch(schemalessCredentialsProvider).value?.problematic ??
        const <schemaless.ProblematicCredential>[];

    final theme = IrmaTheme.of(context);

    return credentials.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: TranslatedText("error.title", textAlign: TextAlign.center),
        ),
      ),
      data: (items) {
        return ReorderableListView.builder(
          onReorderStart: (index) {
            HapticFeedback.mediumImpact();
          },
          onReorderEnd: (index) {
            HapticFeedback.mediumImpact();
          },
          onReorderItem: controller.reorder,
          proxyDecorator: (child, index, animation) {
            // ReorderableListView is a bit wanky when using padding to create space between cards.
            // It will show a shadow around the padded area, which looks weird. Therefore we remove the shadow altogether.
            return Material(type: .transparency, child: child);
          },
          padding: EdgeInsets.all(theme.defaultSpacing),
          itemCount: items.length,
          buildDefaultDragHandles: false,
          // Problematic credentials are shown at the top, above the loadable
          // ones, so the user sees what needs attention first.
          header: problematic.isEmpty
              ? null
              : Column(
                  key: const Key("problematic_credentials_section"),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final pc in problematic)
                      Padding(
                        padding: EdgeInsets.only(bottom: theme.smallSpacing),
                        child: _ProblematicCredentialCard(credential: pc),
                      ),
                  ],
                ),
          footer: const SizedBox(height: 50),
          itemBuilder: (_, i) {
            final cred = items[i];

            return Padding(
              key: ValueKey(cred.credentialId),
              padding: EdgeInsets.only(bottom: theme.smallSpacing),
              child: ReorderableDelayedDragStartListener(
                index: i,
                child: SchemalessYiviCredentialTypeCard(
                  credentialId: cred.credentialId,
                  credentialName: cred.name,
                  issuerName: cred.issuer.name,
                  credentialImageBase64: cred.image != null
                      ? Base64Image(
                          base64: cred.image!.base64,
                          mimeType: cred.image!.mimeType,
                        )
                      : null,
                  onTap: () => context.pushCredentialsDetailsScreen(
                    CredentialsDetailsRouteParams(
                      credentialTypeId: cred.credentialId,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// A card for a credential the wallet stored but cannot render (see
/// [schemaless.ProblematicCredential]). Shown in a danger style with the failure
/// reason and a trashcan to remove a credential that would otherwise be stuck in
/// storage — it has no type/detail screen to route to, so deletion is inline.
class _ProblematicCredentialCard extends ConsumerWidget {
  const _ProblematicCredentialCard({required this.credential});

  final schemaless.ProblematicCredential credential;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final title = FlutterI18n.translate(context, "data.problematic.title");

    return IrmaCard(
      style: IrmaCardStyle.danger,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.error, size: 28),
            SizedBox(width: theme.defaultSpacing - theme.tinySpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.themeData.textTheme.headlineMedium!.copyWith(
                      fontSize: 16,
                      color: theme.dark,
                    ),
                  ),
                  SizedBox(height: theme.tinySpacing),
                  Text(
                    credential.reason,
                    style: theme.themeData.textTheme.bodyMedium!.copyWith(
                      fontSize: 14,
                      color: theme.neutralExtraDark,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: theme.smallSpacing),
            IconButton(
              key: Key("${credential.credentialId ?? "problematic"}_delete"),
              icon: Icon(Icons.delete_outline, color: theme.error),
              tooltip: FlutterI18n.translate(context, "accessibility.remove"),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => DeleteCredentialConfirmationDialog(),
        ) ??
        false;
    if (confirmed && context.mounted) {
      ref
          .read(irmaRepositoryProvider)
          .bridgedDispatch(
            DeleteCredentialEvent(
              hashByFormat: credential.credentialInstanceIds,
            ),
          );
    }
  }
}
