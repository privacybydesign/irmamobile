import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/disclosure/models/disclosure_credential.dart';
import 'package:irmamobile/src/widgets/disclosure/tear_line.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

import 'carousel_attributes.dart';

/* The Offstage in the Carousel widget requires this widget to persist a constant height when
   persistMaxHeight is true. This height is being used by the Carousel widget to calculate the maximum
   height. When persistMaxHeight is false, this widget may never grow larger than that height. */
class UnsatisfiableCredentialDetails extends StatefulWidget {
  /// A DisclosureCredential which is not satisfiable for the current session.
  final DisclosureCredential unsatisfiableCredential;

  /// List of credentials that are present in the user's wallet having the same type as the unsatisfiable one.
  final List<Credential> presentCredentials;

  /// Indicates whether this widget should grow to the maximum height it wants to use.
  final bool persistMaxHeight;

  const UnsatisfiableCredentialDetails({
    Key key,
    @required this.presentCredentials,
    @required this.unsatisfiableCredential,
    this.persistMaxHeight = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    if (unsatisfiableCredential.satisfiable) {
      throw Exception('Given unsatisfiable credential appears to be satisfiable');
    }
    return _UnsatisfiableCredentialDetailsState();
  }
}

class _UnsatisfiableCredentialDetailsState extends State<UnsatisfiableCredentialDetails> {
  final ValueNotifier<int> _visiblePresentCredentialIndex = ValueNotifier<int>(0);

  // TODO: Maybe there are more cases we want to show the present credentials.
  bool get _showPresentCredentials =>
      !widget.unsatisfiableCredential.expired &&
      !widget.unsatisfiableCredential.revoked &&
      !widget.unsatisfiableCredential.notRevokable &&
      widget.unsatisfiableCredential.hasValues &&
      widget.presentCredentials.isNotEmpty;

  @override
  void dispose() {
    _visiblePresentCredentialIndex.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(UnsatisfiableCredentialDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_visiblePresentCredentialIndex.value >= widget.presentCredentials.length) {
      _visiblePresentCredentialIndex.value = widget.presentCredentials.length - 1;
    }
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 11, 4),
          child: SvgPicture.asset(
            'assets/generic/info.svg',
            width: 22,
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
    final nextIndex = (_visiblePresentCredentialIndex.value + 1) % widget.presentCredentials.length;
    _visiblePresentCredentialIndex.value = nextIndex;
  }

  // TODO: Semantics?
  Widget _buildPresentCredentials() => ValueListenableBuilder<int>(
        valueListenable: _visiblePresentCredentialIndex,
        builder: (context, index, _) => GestureDetector(
          excludeFromSemantics: true,
          onTap: _onTapPresentCredential,
          child: Stack(
            alignment: AlignmentDirectional.topEnd,
            children: [
              ...widget.presentCredentials.asMap().entries.map(
                    (credEntry) => Offstage(
                      /// When persistMaxHeight is true, we should render the largest possible state in height.
                      /// We don't know in advance which presentCredential has the biggest height. Therefore, we
                      /// render them all, stacked upon each other, such that the widget gets the size of the
                      /// largest one. This means all presentCredentials should be on stage then (so not offstage).
                      offstage: !(widget.persistMaxHeight || index == credEntry.key),
                      child: _buildCredentialSnippet(
                        credEntry.value.attributeInstances
                            .where((presentAttr) => widget.unsatisfiableCredential.attributes.any(
                                (missingAttr) => missingAttr.attributeType.fullId == presentAttr.attributeType.fullId))
                            .toList(),
                        isPresent: true,
                      ),
                    ),
                  ),

              /// If we have multiple cards, we add an indicator to show how many cards there are.
              if (widget.presentCredentials.length > 1)
                Container(
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
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNotice(),
        if (_showPresentCredentials) ...[
          const Opacity(opacity: 0.5, child: TranslatedText('disclosure.you_have')),
          _buildPresentCredentials(),
          const Opacity(opacity: 0.5, child: TranslatedText('disclosure.requested_for')),
        ],
        _buildCredentialSnippet(widget.unsatisfiableCredential.attributes, isPresent: false),
      ],
    );
  }
}
