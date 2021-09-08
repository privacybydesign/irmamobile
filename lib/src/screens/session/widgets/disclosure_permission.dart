// This file is not null safe yet.
// @dart=2.11

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/screens/session/widgets/disclosure_feedback_screen.dart';
import 'package:irmamobile/src/screens/session/widgets/disclosure_header.dart';
import 'package:irmamobile/src/screens/session/widgets/session_scaffold.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/navigation.dart';
import 'package:irmamobile/src/widgets/disclosure/disclosure_card.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

class DisclosurePermission extends StatefulWidget {
  final Function() onDismiss;
  final Function() onGivePermission;
  final Function(SessionEvent event, {bool isBridgedEvent}) dispatchSessionEvent;

  final SessionState session;

  const DisclosurePermission({Key key, this.onDismiss, this.onGivePermission, this.session, this.dispatchSessionEvent})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _DisclosurePermissionState();
}

class _DisclosurePermissionState extends State<DisclosurePermission> {
  bool _showTooltip = true;
  bool _scrolledToEnd = false;

  final _scrollController = ScrollController();
  final _navigatorKey = GlobalKey();
  final double _scrollEndGive = 25.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.session.canBeFinished) {
        _showExplanation(widget.session.disclosuresCandidates);
      }
    });
  }

  Future<void> _showExplanation(ConDisCon<Attribute> candidatesConDisCon) async {
    final irmaPrefs = IrmaPreferences.get();

    final bool showDisclosureDialog = await irmaPrefs.getShowDisclosureDialog().first;
    final hasChoice = candidatesConDisCon.any((candidatesDisCon) => candidatesDisCon.length > 1);

    if (!showDisclosureDialog || !hasChoice) {
      return;
    }

    setState(() => _showTooltip = false);
    showDialog(
      context: _navigatorKey.currentContext,
      useRootNavigator: false,
      builder: (BuildContext context) => IrmaDialog(
        title: FlutterI18n.translate(context, 'disclosure.explanation.title'),
        content: FlutterI18n.translate(context, 'disclosure.explanation.body'),
        image: 'assets/disclosure/disclosure-explanation.webp',
        child: Wrap(
          direction: Axis.horizontal,
          verticalDirection: VerticalDirection.up,
          alignment: WrapAlignment.spaceEvenly,
          children: <Widget>[
            IrmaTextButton(
              onPressed: () async {
                await irmaPrefs.setShowDisclosureDialog(false);
                _hideExplanation();
              },
              minWidth: 0.0,
              label: 'disclosure.explanation.dismiss-remember',
            ),
            IrmaButton(
              size: IrmaButtonSize.small,
              minWidth: 0.0,
              onPressed: _hideExplanation,
              label: 'disclosure.explanation.dismiss',
            ),
          ],
        ),
      ),
    );
  }

  void _hideExplanation() {
    setState(() {
      _showTooltip = true;
    });
    Navigator.of(_navigatorKey.currentContext).pop();
  }

  void _checkScrolledToEnd() {
    if (!_scrolledToEnd &&
        _scrollController.hasClients &&
        _scrollController.offset >= _scrollController.position.maxScrollExtent - _scrollEndGive) {
      setState(() {
        _scrolledToEnd = true;
      });
    }
  }

  void _carouselPageUpdate(int disconIndex, int conIndex) {
    widget.dispatchSessionEvent(
      DisclosureChoiceUpdateSessionEvent(
        disconIndex: disconIndex,
        conIndex: conIndex,
      ),
      isBridgedEvent: false,
    );

    _scrolledToEnd = false;
    _checkScrolledToEnd();
  }

  Widget _buildDisclosureChoices() {
    _scrollController.addListener(_checkScrolledToEnd);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Unfortunately, if this is run immediately the ListView does not yet have height
      // so _checkScrolledToEnd would conclude the end is reached, even if it is not.
      await Future.delayed(const Duration(milliseconds: 50));
      _checkScrolledToEnd();
    });

    return ListView(
      padding: EdgeInsets.all(IrmaTheme.of(context).smallSpacing),
      controller: _scrollController,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: IrmaTheme.of(context).mediumSpacing,
            horizontal: IrmaTheme.of(context).smallSpacing,
          ),
          child: DisclosureHeader(
            session: widget.session,
          ),
        ),
        DisclosureCard(
          candidatesConDisCon: widget.session.disclosuresCandidates,
          onCurrentPageUpdate: _carouselPageUpdate,
          onIssue: () => setState(() => _showTooltip = false),
        ),
      ],
    );
  }

  @protected
  Widget _buildNavigationBar() {
    final showTooltip = _showTooltip && !_scrolledToEnd;
    return IrmaBottomBar(
      primaryButtonLabel: FlutterI18n.translate(context, 'session.navigation_bar.yes'),
      onPrimaryPressed: widget.session.canDisclose && _scrolledToEnd ? () => widget.onGivePermission() : null,
      secondaryButtonLabel: FlutterI18n.translate(context, 'session.navigation_bar.no'),
      onSecondaryPressed: () => widget.onDismiss(),
      toolTipLabel: showTooltip ? FlutterI18n.translate(context, 'disclosure.see_more') : null,
      showTooltipOnPrimary: showTooltip,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.session.canBeFinished) {
      final serverName = widget.session.serverName.name.translate(FlutterI18n.currentLocale(context).languageCode);
      return DisclosureFeedbackScreen(
        feedbackType: DisclosureFeedbackType.notSatisfiable,
        otherParty: serverName,
        popToWallet: popToWallet,
      );
    }

    // Wrap component in custom navigator in order to manage the explanation popup as widget ourselves.
    // Now popping this widget from the root navigator also makes the explanation popup to be popped.
    // This saves us having to manually take account of an _explanationHidden state.
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (context) => SessionScaffold(
          appBarTitle: 'disclosure.title',
          bottomNavigationBar: _buildNavigationBar(),
          body: _buildDisclosureChoices(),
          onDismiss: widget.onDismiss,
        ),
        settings: settings,
      ),
    );
  }
}
