import "dart:math";

import "package:cupertino_ui/cupertino_ui.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../data/feature_flags.dart";
import "../../models/credential_events.dart";
import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../providers/data_tab_sections_provider.dart";
import "../../providers/feature_flag_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/schemaless_credentials_list_provider.dart";
import "../../providers/schemaless_credentials_provider.dart";
import "../../theme/theme.dart";
import "../../util/navigation.dart";
import "../../widgets/base64_image.dart";
import "../../widgets/credential_card/delete_credential_confirmation_dialog.dart";
import "../../widgets/credential_card/models/credential_card_status.dart";
import "../../widgets/credential_card/schemaless_yivi_credential_type_card.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_card.dart";
import "../../widgets/irma_icon_button.dart";
import "../../widgets/section_header.dart";
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
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

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
            : ref.watch(dataTabLayoutProvider) == DataTabLayout.classic
            ? _ReorderableCredentialList()
            : const _SectionedCredentialList(),
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
            child: _CredentialTypeCard(c),
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
      error: (error, trace) => Center(
        child: Padding(
          padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
          child: TranslatedText("error.title", textAlign: TextAlign.center),
        ),
      ),
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
              : _ProblematicCredentialsSection(problematic),
          footer: const SizedBox(height: 50),
          itemBuilder: (_, i) {
            final cred = items[i];

            return Padding(
              key: ValueKey(cred.credentialId),
              padding: EdgeInsets.only(bottom: theme.smallSpacing),
              child: ReorderableDelayedDragStartListener(
                index: i,
                child: _CredentialTypeCard(cred),
              ),
            );
          },
        );
      },
    );
  }
}

/// The card of a credential type. With `dataTabV2` on it shows the type as
/// expired when every credential of it is, so a valid credential next to an
/// expired one does not make the type look unusable.
class _CredentialTypeCard extends ConsumerWidget {
  const _CredentialTypeCard(this.credential);

  final schemaless.Credential credential;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showExpiry =
        ref.watch(featureFlagProvider(FeatureFlag.dataTabV2)).value ?? false;
    final sameType = !showExpiry
        ? null
        : ref
              .watch(
                schemalessCredentialsWithIdProvider(credential.credentialId),
              )
              .value;
    final expired =
        sameType != null && sameType.isNotEmpty && sameType.every(_isExpired);

    return SchemalessYiviCredentialTypeCard(
      credentialId: credential.credentialId,
      credentialName: credential.name,
      issuerName: credential.issuer.name,
      expireState: expired ? ExpireState.expired : ExpireState.notExpired,
      credentialImageBase64: credential.image != null
          ? Base64Image(
              base64: credential.image!.base64,
              mimeType: credential.image!.mimeType,
            )
          : null,
      onTap: () => context.pushCredentialsDetailsScreen(
        CredentialsDetailsRouteParams(
          credentialTypeId: credential.credentialId,
        ),
      ),
    );
  }
}

bool _isExpired(schemaless.Credential credential) => CredentialCardStatus(
  expiryDateUnix: credential.expiryDate,
  revoked: credential.revoked,
  batchInstanceCountsRemaining: credential.batchInstanceCountsRemaining,
).isExpired;

class _ProblematicCredentialsSection extends StatelessWidget {
  const _ProblematicCredentialsSection(this.problematic);

  final List<schemaless.ProblematicCredential> problematic;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Column(
      key: const Key("problematic_credentials_section"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final pc in problematic)
          Padding(
            padding: EdgeInsets.only(bottom: theme.smallSpacing),
            child: _ProblematicCredentialCard(credential: pc),
          ),
      ],
    );
  }
}

/// The data tab behind `dataTabV2` and `dataTabCategories`: the credentials in
/// sections, each in the user's own order. All sections share one scroll view,
/// so dragging a card to the edge of the screen scrolls the whole list.
class _SectionedCredentialList extends ConsumerWidget {
  const _SectionedCredentialList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final sections = ref.watch(dataTabSectionsProvider);
    final problematic =
        ref.watch(schemalessCredentialsProvider).value?.problematic ??
        const <schemaless.ProblematicCredential>[];

    return sections.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: TranslatedText("error.title", textAlign: TextAlign.center),
        ),
      ),
      data: (sections) => CustomScrollView(
        key: const Key("credential_sections_list"),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(theme.defaultSpacing),
            sliver: SliverMainAxisGroup(
              slivers: [
                if (problematic.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _ProblematicCredentialsSection(problematic),
                  ),
                for (final section in sections)
                  _CredentialSection(
                    key: ValueKey(section.key),
                    section: section,
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _SectionState {
  /// No chevron: favourites, and every section while `dataTabCategories` is off.
  fixed,
  expanded,
  collapsed,
}

class _CredentialSection extends ConsumerWidget {
  const _CredentialSection({super.key, required this.section});

  final DataTabSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final controller = ref.read(
      schemalessCredentialOrderControllerProvider.notifier,
    );
    final collapsible =
        ref.watch(dataTabLayoutProvider) == DataTabLayout.categories &&
        section.kind != DataTabSectionKind.favourites;
    final state = !collapsible
        ? _SectionState.fixed
        : ref.watch(collapsedDataTabSectionsProvider).contains(section.key)
        ? _SectionState.collapsed
        : _SectionState.expanded;

    return SliverMainAxisGroup(
      slivers: [
        if (section.kind != DataTabSectionKind.ungrouped)
          SliverToBoxAdapter(
            child: _SectionTitle(section: section, state: state),
          ),
        if (state != _SectionState.collapsed)
          SliverReorderableList(
            onReorderStart: (index) {
              HapticFeedback.mediumImpact();
            },
            onReorderEnd: (index) {
              HapticFeedback.mediumImpact();
            },
            onReorderItem: (oldIndex, newIndex) => controller.reorderWithin(
              section.credentials,
              oldIndex,
              newIndex,
            ),
            proxyDecorator: (child, index, animation) {
              // See _ReorderableCredentialList: no shadow around the padding.
              return Material(type: .transparency, child: child);
            },
            itemCount: section.credentials.length,
            itemBuilder: (_, i) {
              final credential = section.credentials[i];

              return Padding(
                key: ValueKey(credential.credentialId),
                padding: EdgeInsets.only(bottom: theme.smallSpacing),
                child: ReorderableDelayedDragStartListener(
                  index: i,
                  child: _CredentialTypeCard(credential),
                ),
              );
            },
          ),
        SliverToBoxAdapter(child: SizedBox(height: theme.smallSpacing)),
      ],
    );
  }
}

class _SectionTitle extends ConsumerWidget {
  const _SectionTitle({required this.section, required this.state});

  final DataTabSection section;
  final _SectionState state;

  String _title(BuildContext context) => switch (section.kind) {
    .favourites => FlutterI18n.translate(context, "data_tab.favourites.title"),
    .category when section.category.isEmpty => FlutterI18n.translate(
      context,
      "data.category_other",
    ),
    .category => section.category,
    .staging => FlutterI18n.translate(context, "data.add.staging"),
    .demo => FlutterI18n.translate(context, "data.add.demo"),
    .ungrouped => "",
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final title = _title(context);

    if (state == _SectionState.fixed) {
      return Padding(
        padding: EdgeInsets.only(bottom: theme.smallSpacing),
        child: Row(
          children: [
            Flexible(child: SectionHeader.text(title)),
            if (section.kind == DataTabSectionKind.favourites) ...[
              SizedBox(width: theme.tinySpacing),
              ExcludeSemantics(
                child: Icon(
                  Icons.star,
                  size: 20,
                  color: theme.neutralExtraDark,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final collapsed = state == _SectionState.collapsed;
    final count = section.credentials.length;
    void toggle() =>
        ref.read(collapsedDataTabSectionsProvider.notifier).toggle(section.key);

    return Semantics(
      container: true,
      header: true,
      button: true,
      expanded: !collapsed,
      label: collapsed
          ? "$title, ${FlutterI18n.plural(context, "data_tab.section_count", count)}"
          : title,
      hint: FlutterI18n.translate(
        context,
        collapsed ? "accessibility.expand_hint" : "accessibility.collapse_hint",
      ),
      onTap: toggle,
      excludeSemantics: true,
      child: InkWell(
        key: Key("${section.key}_header"),
        onTap: toggle,
        borderRadius: theme.borderRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: theme.defaultSpacing,
              right: theme.smallSpacing,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.themeData.textTheme.headlineMedium?.copyWith(
                      color: theme.neutralExtraDark,
                    ),
                  ),
                ),
                if (collapsed)
                  Text(
                    "$count",
                    style: theme.themeData.textTheme.bodyMedium?.copyWith(
                      color: theme.neutralExtraDark,
                    ),
                  ),
                SizedBox(width: theme.tinySpacing),
                Icon(
                  collapsed ? Icons.expand_more : Icons.expand_less,
                  color: theme.neutralExtraDark,
                ),
              ],
            ),
          ),
        ),
      ),
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
                    FlutterI18n.translate(
                      context,
                      "data.problematic.explanation",
                    ),
                    style: theme.themeData.textTheme.bodyMedium!.copyWith(
                      fontSize: 14,
                      color: theme.neutralExtraDark,
                    ),
                  ),
                  SizedBox(height: theme.tinySpacing),
                  Text(
                    credential.reason,
                    style: theme.themeData.textTheme.bodySmall!.copyWith(
                      fontSize: 12,
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
