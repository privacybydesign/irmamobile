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

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundPrimary,
        border: Border(bottom: BorderSide(color: theme.tertiary)),
      ),
      child: SafeArea(
        child: Container(
          height: preferredSize.height,
          padding: EdgeInsets.only(left: theme.defaultSpacing, right: theme.smallSpacing),
          child: Row(
            children: [
              Expanded(
                child: CupertinoSearchTextField(
                  key: const Key('search_bar'),
                  focusNode: focusNode,
                  onChanged: onQueryChanged,
                ),
              ),
              TextButton(
                key: const Key('cancel_search_button'),
                onPressed: onCancel,
                child: TranslatedText(
                  'search.cancel',
                  style: theme.textButtonTextStyle.copyWith(fontWeight: FontWeight.normal, color: theme.link),
                ),
              ),
            ],
          ),
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

final _addDataButtonKey = GlobalKey();

class _DataTabState extends ConsumerState<DataTab> {
  bool _searchActive = false;
  final _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    if (_searchActive) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: theme.backgroundTertiary,
        appBar: YiviSearchBar(focusNode: _focusNode, onCancel: _closeSearch, onQueryChanged: _searchQueryChanged),
        body: CredentialsSearchResults(),
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
          child: AllCredentialsList(),
        ),
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
    ref.read(credentialsSearchQueryProvider.notifier).state = query;
  }
}

// ============================================================================================

// Image of a man that always points towards the add data button to indicate that button should be pressed
class ToAddDataButtonPointingImage extends StatefulWidget {
  @override
  State<ToAddDataButtonPointingImage> createState() => _ToAddDataButtonPointingImageState();
}

class _ToAddDataButtonPointingImageState extends State<ToAddDataButtonPointingImage> {
  final _imageKey = GlobalKey();
  double rotationAngle = 0.0;

  double _calculateRotation() {
    final pi = 3.1415;

    final addDataButtonRenderBox = _addDataButtonKey.currentContext?.findRenderObject() as RenderBox?;
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
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateY(3.14159) // 180-degree flip (π radians)
        ..rotateZ(rotationAngle),
      child: SvgPicture.asset(key: _imageKey, 'assets/arrow_back/pointing_up.svg'),
    );
  }
}

class NoCredentialsYet extends StatelessWidget {
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

  _buildLandscapeOrientation(BuildContext context) {
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
          ToAddDataButtonPointingImage(),
        ],
      ),
    );
  }

  _buildPortraitOrientation(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Padding(
      padding: EdgeInsets.all(theme.defaultSpacing),
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: theme.defaultSpacing),
            ToAddDataButtonPointingImage(),
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

  _buildExplanationText(BuildContext context, {required TextAlign textAlign}) {
    final theme = IrmaTheme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TranslatedText('data_tab.empty.title', style: theme.textTheme.displayLarge, textAlign: textAlign),
        SizedBox(height: theme.defaultSpacing),
        TranslatedText('data_tab.empty.subtitle', textAlign: textAlign),
      ],
    );
  }
}

class AllCredentialsList extends ConsumerWidget {
  const AllCredentialsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentials = ref.watch(credentialsProvider);

    return switch (credentials) {
      AsyncData(:final value) =>
        value.isEmpty ? NoCredentialsYet() : CredentialsList(credentials: value.values.toList(growable: false)),
      AsyncError(:final error) => Text(error.toString()),
      _ => CircularProgressIndicator(),
    };
  }
}

class CredentialsList extends StatelessWidget {
  const CredentialsList({super.key, required this.credentials});

  final List<Credential> credentials;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return ListView(
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

class CredentialsSearchResults extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = FlutterI18n.currentLocale(context)!;
    final credentials = ref.watch(credentialsSearchResultsProvider(locale));

    return credentials.when(
      skipLoadingOnReload: true,
      data: (credentials) => CredentialsList(credentials: credentials),
      loading: () => CircularProgressIndicator(),
      error: (error, trace) => Text(error.toString()),
    );
  }
}
