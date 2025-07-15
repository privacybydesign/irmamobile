import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/credentials.dart';
import '../../providers/credentials_provider.dart';
import '../../theme/theme.dart';
import '../../util/navigation.dart';
import '../../widgets/credential_card/irma_credential_type_card.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_icon_button.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/yivi_search_bar.dart';

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
  final _addDataButtonKey = GlobalKey(debugLabel: 'add_data_button_key');

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    if (_searchActive) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: theme.backgroundTertiary,
        appBar: YiviSearchBar(focusNode: _focusNode, onCancel: _closeSearch, onQueryChanged: _searchQueryChanged),
        body: _CredentialsSearchResults(),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'home.nav_bar.data',
        leading: null,
        actions: [
          IrmaIconButton(
            key: const Key('search_button'),
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
    _searchQueryChanged('');
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
    ref.read(credentialsSearchQueryProvider.notifier).state = query;
  }
}

// ============================================================================================

// Image of a man that always points towards the add data button to indicate that button should be pressed
class _ToAddDataButtonPointingImage extends StatefulWidget {
  const _ToAddDataButtonPointingImage({required this.addDataButtonKey});

  final GlobalKey addDataButtonKey;

  @override
  State<_ToAddDataButtonPointingImage> createState() => _ToAddDataButtonPointingImageState();
}

class _ToAddDataButtonPointingImageState extends State<_ToAddDataButtonPointingImage> {
  final _imageKey = GlobalKey(debugLabel: 'to_add_data_pointing_image_key');
  static const pi = 3.1415;
  double rotationAngle = 0.0;

  double _calculateRotation() {
    final addDataButtonRenderBox = widget.addDataButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final imageRenderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;

    if (imageRenderBox == null || addDataButtonRenderBox == null) {
      return 100.0;
    }

    final plusButtonCenter = addDataButtonRenderBox.localToGlobal(addDataButtonRenderBox.size.center(Offset.zero));
    final imageCenter = imageRenderBox.localToGlobal(imageRenderBox.size.center(Offset.zero));

    final deltaX = plusButtonCenter.dx - imageCenter.dx;
    final deltaY = imageCenter.dy - plusButtonCenter.dy;
    final targetAngle = atan2(deltaY, deltaX);

    final referenceAngleDeg = 55.0; // angle of the arm inside the image in degrees
    final referenceAngle = referenceAngleDeg * pi / 180.0;

    return targetAngle - referenceAngle;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rotation = _calculateRotation();
      if (rotationAngle != rotation) {
        setState(() => rotationAngle = rotation);
      }
    });

    return Transform(
      key: const Key('to_add_data_button_pointing_image'),
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateY(pi) // 180-degree flip (π radians)
        ..rotateZ(rotationAngle),
      child: SvgPicture.asset(key: _imageKey, 'assets/arrow_back/pointing_up.svg'),
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
                TranslatedText('data_tab.empty.title', style: theme.textTheme.displayLarge, textAlign: TextAlign.start),
                SizedBox(height: theme.defaultSpacing),
                TranslatedText('data_tab.empty.subtitle', textAlign: TextAlign.start),
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
                TranslatedText('data_tab.empty.title',
                    style: theme.textTheme.displayLarge, textAlign: TextAlign.center),
                SizedBox(height: theme.defaultSpacing),
                TranslatedText('data_tab.empty.subtitle', textAlign: TextAlign.center),
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
    final credentials = ref.watch(credentialsProvider);

    return switch (credentials) {
      AsyncData(:final value) => value.isEmpty
          ? _NoCredentialsYet(addDataButtonKey: addDataButtonKey)
          : _CredentialsTypeList(credentials: value.values.toList(growable: false)),
      AsyncError(:final error) => Text(error.toString()),
      _ => CircularProgressIndicator(),
    };
  }
}

class _CredentialsTypeList extends StatelessWidget {
  const _CredentialsTypeList({required this.credentials});

  final List<Credential> credentials;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return ListView(
      key: const Key('credentials_type_list'),
      padding: EdgeInsets.only(top: theme.defaultSpacing),
      children: [
        ...credentials.map(
          (c) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: theme.smallSpacing,
                left: theme.defaultSpacing,
                right: theme.defaultSpacing,
              ),
              child: IrmaCredentialTypeCard(
                credType: c.credentialType,
                onTap: () => context.pushCredentialsDetailsScreen(
                  CredentialsDetailsRouteParams(
                      categoryName: 'home.nav_bar.data', credentialTypeId: c.credentialType.fullId),
                ),
              ),
            );
          },
        ),
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
          'data.search.no_results',
          translationParams: {'query': query},
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = FlutterI18n.currentLocale(context)!;
    final credentials = ref.watch(credentialsSearchResultsProvider(locale));
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
