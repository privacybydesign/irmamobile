// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/disclosure/carousel_attributes.dart';
import 'package:irmamobile/src/widgets/disclosure/carousel_credential_footer.dart';
import 'package:irmamobile/src/widgets/disclosure/models/disclosure_credential.dart';
import 'package:irmamobile/src/widgets/disclosure/tear_line.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

/* The Offstage in the Carousel widget requires this widget to persist a fixed height when fixedSize
   is true. This height is being used by the Carousel widget to calculate the maximum height.
   When fixedSize is false, this widget may never be larger than the size when fixedSize is true. */
class UnsatisfiableCredentialDetails extends StatefulWidget {
  /// A DisclosureCredential which is not satisfiable for the current session.
  final DisclosureCredential unsatisfiableCredential;

  /// List of credentials that are present in the user's wallet having the same type as the unsatisfiable one.
  final List<Credential> presentCredentials;

  /// Indicates whether the widget should have a fixed size, independent of the widget's state.
  final bool fixedSize;

  /// Handler that is called when obtain/refresh button is pressed.
  final Function() onIssue;

  UnsatisfiableCredentialDetails({
    Key key,
    @required this.presentCredentials,
    @required this.unsatisfiableCredential,
    this.fixedSize = false,
    this.onIssue,
  })  : assert(presentCredentials != null),
        assert(unsatisfiableCredential != null),
        assert(!unsatisfiableCredential.satisfiable),
        assert(presentCredentials.every((cred) => cred.info.fullId == unsatisfiableCredential.credentialInfo.fullId)),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _UnsatisfiableCredentialDetailsState();
}

class _UnsatisfiableCredentialDetailsState extends State<UnsatisfiableCredentialDetails> {
  final ValueNotifier<int> _selectedPresentCredential = ValueNotifier<int>(0);

  // Maybe there are more cases we want to show the present credentials, but for now we
  // only show the present credentials when attributes with specific values are requested.
  bool get _showPresentCredentials =>
      !widget.unsatisfiableCredential.expired &&
      !widget.unsatisfiableCredential.revoked &&
      !widget.unsatisfiableCredential.notRevokable &&
      widget.unsatisfiableCredential.hasValues &&
      widget.presentCredentials.isNotEmpty;

  @override
  void dispose() {
    _selectedPresentCredential.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(UnsatisfiableCredentialDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedPresentCredential.value >= widget.presentCredentials.length) {
      _selectedPresentCredential.value = widget.presentCredentials.length - 1;
    }
  }

  Function() _createOnRefreshCredential(CredentialType type) {
    return () {
      if (widget.onIssue != null) {
        widget.onIssue();
      }
      IrmaRepository.get().openIssueURL(context, type.fullId);
    };
  }

  String _notice() {
    if (widget.unsatisfiableCredential.expired) {
      return FlutterI18n.translate(context, 'disclosure.expired');
    } else if (widget.unsatisfiableCredential.revoked) {
      return FlutterI18n.translate(context, 'disclosure.revoked');
    } else if (widget.unsatisfiableCredential.notRevokable) {
      return FlutterI18n.translate(context, 'disclosure.not_revokable');
    } else if (widget.presentCredentials.isEmpty) {
      return FlutterI18n.translate(context, 'disclosure.not_present');
    } else if (widget.unsatisfiableCredential.hasValues) {
      return FlutterI18n.translate(context, 'disclosure.not_present_have_other');
    } else {
      return FlutterI18n.translate(context, 'disclosure.add_additional', translationParams: {
        "credential": widget.unsatisfiableCredential.credentialInfo.credentialType.name
            .translate(FlutterI18n.currentLocale(context).languageCode),
      });
    }
  }

  Widget _buildNotice() {
    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 11, 4),
          child: SvgPicture.asset(
            'assets/generic/info.svg',
            width: 22,
            excludeFromSemantics: true,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, right: 9, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _notice(),
                  style: IrmaTheme.of(context).textTheme.bodyText2.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: IrmaTheme.of(context).primaryBlue,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCredentialSnippet(List<Attribute> attributes, {bool isPresent = false}) {
    final tinySpacing = IrmaTheme.of(context).tinySpacing;
    final smallSpacing = IrmaTheme.of(context).smallSpacing;
    return Card(
      margin: EdgeInsets.fromLTRB(tinySpacing, smallSpacing, tinySpacing, tinySpacing),
      color: isPresent ? IrmaTheme.of(context).notificationSuccessBg : IrmaTheme.of(context).notificationInfoBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TearLine(margin: EdgeInsets.only(top: tinySpacing)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: smallSpacing, vertical: tinySpacing),
            child: CarouselAttributes(
              attributes: attributes,
              showNullValues: !isPresent,
            ),
          ),
          TearLine(margin: EdgeInsets.only(bottom: tinySpacing)),
        ],
      ),
    );
  }

  void _onTapPresentCredential() {
    final nextIndex = (_selectedPresentCredential.value + 1) % widget.presentCredentials.length;
    _selectedPresentCredential.value = nextIndex;
  }

  int _findIndexOfAttribute(Attribute attr) => widget.unsatisfiableCredential.attributes
      .asMap()
      .entries
      .firstWhere((entry) => entry.value.attributeType.fullId == attr.attributeType.fullId)
      .key;

  Widget _buildPresentCredential(Credential credential) {
    final presentAttributes = credential.attributeList
        .where((presentAttr) => widget.unsatisfiableCredential.attributes
            .any((missingAttr) => missingAttr.attributeType.fullId == presentAttr.attributeType.fullId))
        .toList();
    // Use the attribute order of the requested conjunction, also when this deviates from the attribute order on the card.
    presentAttributes.sort((x, y) => _findIndexOfAttribute(x).compareTo(_findIndexOfAttribute(y)));
    return _buildCredentialSnippet(presentAttributes, isPresent: true);
  }

  // To not overcomplicate accessibility semantics, we exclude the gestures to cycle
  // through all present credentials from semantics.
  Widget _buildPresentCredentials() => GestureDetector(
        excludeFromSemantics: true,
        onTap: _onTapPresentCredential,
        child: ValueListenableBuilder<int>(
          valueListenable: _selectedPresentCredential,
          builder: (context, index, _) => Stack(
            alignment: AlignmentDirectional.topEnd,
            children: [
              // When the widget should have a fixed size we use an IndexedStack, since it always uses the size of the largest child.
              if (widget.fixedSize)
                IndexedStack(
                  index: index,
                  children: widget.presentCredentials.map(_buildPresentCredential).toList(),
                )
              else
                _buildPresentCredential(widget.presentCredentials[index]),

              // If we have multiple cards, we add an indicator to show how many cards there are.
              // Above we disabled the gesture to cycle through all present cards from semantics.
              // Therefore, we also exclude the total amount of cards from semantics. We replace
              // it with a general comment that the visible card is just one among others.
              if (widget.presentCredentials.length > 1)
                Semantics(
                  label: FlutterI18n.translate(context, 'disclosure.among_others'),
                  excludeSemantics: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 1),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(15.0),
                      ),
                      color: Colors.green,
                    ),
                    child: TranslatedText(
                      'disclosure.card_count',
                      translationParams: {
                        "i": (index + 1).toString(),
                        "total": widget.presentCredentials.length.toString()
                      },
                      textAlign: TextAlign.center,
                      style: IrmaTheme.of(context).textTheme.bodyText1.apply(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildGetButton() {
    final label = widget.unsatisfiableCredential.attributes.first.credentialHash == ''
        ? FlutterI18n.translate(context, 'disclosure.obtain')
        : FlutterI18n.translate(context, 'disclosure.refresh');
    return Padding(
      padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).defaultSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IrmaButton(
            label: label,
            size: IrmaButtonSize.small,
            onPressed: _createOnRefreshCredential(
                widget.unsatisfiableCredential.attributes.first.credentialInfo.credentialType),
          ),
        ],
      ),
    );
  }

  // We need a work-around for an inconsistency in the semantics order of a column being nested
  // in a MergeSemantics (at least on Android). Therefore, we number the items in the widget list manually.
  List<Widget> _listSemantics(List<Widget> widgets) =>
      widgets.asMap().entries.map((entry) => IndexedSemantics(index: entry.key, child: entry.value)).toList();

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _listSemantics([
          _buildNotice(),
          if (_showPresentCredentials) ...[
            const Opacity(opacity: 0.5, child: TranslatedText('disclosure.you_have')),
            _buildPresentCredentials(),
            const Opacity(opacity: 0.5, child: TranslatedText('disclosure.requested_for')),
          ],
          _buildCredentialSnippet(widget.unsatisfiableCredential.attributes),
          CarouselCredentialFooter(credential: widget.unsatisfiableCredential),
          if (widget.unsatisfiableCredential.obtainable) _buildGetButton(),
        ]),
      ),
    );
  }
}
