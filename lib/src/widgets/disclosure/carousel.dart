import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:irmamobile/src/models/attribute_value.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:irmamobile/src/screens/webview/webview_screen.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';
import 'package:irmamobile/src/util/translated_text.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

class Carousel extends StatefulWidget {
  final DisCon<Attribute> candidatesDisCon;
  final ValueChanged<int> onCurrentPageUpdate;

  const Carousel({
    @required this.candidatesDisCon,
    @required this.onCurrentPageUpdate,
  });

  @override
  _CarouselState createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  final GlobalKey _keyStackedIndex = GlobalKey();
  final _animationDuration = 250;
  int _currentPage = 0;

  double height;

  int get currentPage => _currentPage;
  set currentPage(int val) {
    _currentPage = val;
    widget.onCurrentPageUpdate(val);
  }

  final _controller = PageController();

  Function() _createOnRefreshCredential(CredentialType type) {
    return () {
      final url = getTranslation(context, type.issueUrl);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return WebviewScreen(url);
        }),
      );
    };
  }

  // Determining size of widget as described here:
  // https://medium.com/@diegoveloper/flutter-widget-size-and-position-b0a9ffed9407

  Size _getSize() {
    final RenderBox renderBoxStackedIndex = _keyStackedIndex.currentContext.findRenderObject() as RenderBox;
    return renderBoxStackedIndex.size;
  }

  void _afterLayout(_) {
    setState(() {
      height = _getSize().height;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
    super.initState();
  }

  // getChangedPageAndMoveBar and dotsIndicator from
  // https://medium.com/aubergine-solutions/create-an-onboarding-page-indicator-in-3-minutes-in-flutter-a2bd97ceeaff
  void getChangedPageAndMoveBar(int page) {
    setState(() {
      currentPage = page % widget.candidatesDisCon.length;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          /* An offstage IndexedStack is used because an IndexedStack always has
        the height of the highest element. The height is then used to determine
        the height of a PageViewer (who needs to be in an element of pre-determined height).
        FUTURE: implement a more elegant solution */
          Offstage(
            offstage: true,
            child: IndexedStack(
                key: _keyStackedIndex,
                index: currentPage,
                children: widget.candidatesDisCon.map(_buildCarouselWidget).toList()),
          ),
          _buildPageViewer(),
        ],
      );

  Widget _buildPageViewer() => height == null
      ? Container()
      : Column(
          children: <Widget>[
            Container(
              height: height,
              child: PageView.builder(
                itemCount: widget.candidatesDisCon.length,
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _controller,
                onPageChanged: (int page) {
                  getChangedPageAndMoveBar(page);
                },
                itemBuilder: (BuildContext context, int index) {
                  return _buildCarouselWidget(widget.candidatesDisCon[index % widget.candidatesDisCon.length]);
                },
              ),
            ),
            if (widget.candidatesDisCon.length > 1) _buildNavBar(),
          ],
        );

  Widget _buildNavBar() => Container(
        height: 60.0,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            Positioned(
              left: 0,
              child: _buildArrowButton(
                icon: IrmaIcons.chevronLeft,
                semanticLabel: "disclosure.previous",
                isVisible: currentPage > 0,
                delta: -1,
                size: widget.candidatesDisCon.length,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Spacer(flex: 15),
                Row(
                  children: <Widget>[
                    const Spacer(),
                    ...List.generate(
                        widget.candidatesDisCon.length, (i) => _buildDotsIndicator(isActive: i == currentPage)),
                    const Spacer(),
                  ],
                ),
                const Spacer(flex: 3),
                Center(
                  child: TranslatedText(
                    'disclosure.choices',
                    translationParams: {"choices": widget.candidatesDisCon.length.toString()},
                    style: IrmaTheme.of(context)
                        .textTheme
                        .body1
                        .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 12),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
            Positioned(
              right: 0,
              child: _buildArrowButton(
                icon: IrmaIcons.chevronRight,
                semanticLabel: "disclosure.next",
                isVisible: currentPage < widget.candidatesDisCon.length - 1,
                delta: 1,
                size: widget.candidatesDisCon.length,
              ),
            ),
          ],
        ),
      );

  Widget _buildDotsIndicator({bool isActive}) => AnimatedContainer(
        duration: Duration(milliseconds: _animationDuration),
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        height: 5,
        width: 5,
        decoration: BoxDecoration(
          color: isActive ? IrmaTheme.of(context).grayscale40 : IrmaTheme.of(context).grayscale80,
          borderRadius: const BorderRadius.all(
            Radius.circular(3),
          ),
        ),
      );

  Widget _buildArrowButton({IconData icon, String semanticLabel, bool isVisible, int delta, int size}) =>
      AnimatedOpacity(
        opacity: isVisible ? 1 : 0,
        duration: Duration(milliseconds: _animationDuration),
        child: IconButton(
          icon: Icon(icon,
              color: IrmaTheme.of(context).interactionInformation,
              semanticLabel: FlutterI18n.translate(context, semanticLabel)),
          iconSize: 20.0,
          splashColor: isVisible ? const Color(0xffcccccc) : const Color(0x00000000),
          onPressed: () {
            setState(
              () {
                if (currentPage + delta >= 0 && currentPage + delta <= size - 1) {
                  currentPage += delta;
                  _controller.animateToPage(
                    currentPage,
                    duration: Duration(milliseconds: _animationDuration),
                    curve: Curves.easeInOut,
                  );
                }
              },
            );
          },
        ),
      );

  Widget _buildCandidateValue(Attribute candidate) {
    if (candidate.value is PhotoValue) {
      return Padding(
        padding: EdgeInsets.only(
          top: 6,
          bottom: IrmaTheme.of(context).smallSpacing,
        ),
        child: Container(
          width: 90,
          height: 120,
          color: const Color(0xff777777),
          child: (candidate.value as PhotoValue).image,
        ),
      );
    }

    // If an attribute is null, we render a TextValue with a dash as text.
    return Text(
      candidate.value is TextValue ? getTranslation(context, (candidate.value as TextValue).translated) : "-",
      style: IrmaTheme.of(context).textTheme.body2,
    );
  }

  Widget _buildGetButton(_DisclosureCredential cred) {
    final label = cred.attributes.first.credentialHash == ""
        ? FlutterI18n.translate(context, 'disclosure.obtain')
        : FlutterI18n.translate(context, 'disclosure.refresh');
    return Padding(
      padding: EdgeInsets.only(top: IrmaTheme.of(context).smallSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IrmaButton(
            label: label,
            size: IrmaButtonSize.small,
            onPressed: _createOnRefreshCredential(cred.attributes.first.credentialInfo.credentialType),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice(String notice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 11, 4),
          child: SvgPicture.asset(
            'assets/generic/stop.svg',
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
                  notice,
                  style: IrmaTheme.of(context).textTheme.body1.copyWith(
                        fontSize: 14,
                        color: IrmaTheme.of(context).grayscale40,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _notice(_DisclosureCredential cred) {
    if (cred.attributes.first.expired) {
      return FlutterI18n.translate(context, 'disclosure.expired');
    } else if (cred.attributes.first.revoked) {
      return FlutterI18n.translate(context, 'disclosure.revoked');
    } else if (cred.attributes.first.notRevokable) {
      return FlutterI18n.translate(context, 'disclosure.not_revokable');
    } else if (cred.attributes.first.credentialHash == "") {
      return FlutterI18n.translate(context, 'disclosure.not_present');
    }
    return null;
  }

  Widget _buildCredentialFooter(_DisclosureCredential cred) {
    final notice = _notice(cred);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).smallSpacing),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: 0.5,
              child: Text(
                FlutterI18n.translate(context, 'disclosure.issuer'),
                style: IrmaTheme.of(context)
                    .textTheme
                    .body1
                    .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: IrmaTheme.of(context).smallSpacing),
              child: Text(
                getTranslation(context, cred.issuer),
                style: IrmaTheme.of(context)
                    .textTheme
                    .body1
                    .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (notice != null) _buildNotice(notice),
        if (cred.obtainable) _buildGetButton(cred),
        if (!cred.isLast)
          Padding(
            padding: EdgeInsets.only(top: IrmaTheme.of(context).mediumSpacing),
            child: Container(
              color: IrmaTheme.of(context).grayscale85,
              height: 1,
            ),
          ),
      ]),
    );
  }

  Widget _buildAttribute(Attribute attribute) {
    return Padding(
      padding: EdgeInsets.only(top: IrmaTheme.of(context).smallSpacing),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslation(context, attribute.attributeType.name),
            style:
                IrmaTheme.of(context).textTheme.body1.copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          _buildCandidateValue(attribute),
        ],
      ),
    );
  }

  bool _group(List<List<Attribute>> list, Attribute attr) {
    if (list.isEmpty) {
      return false;
    }
    final last = list.last.last;
    return !last.choosable
        ? last.credentialInfo.fullId == attr.credentialInfo.fullId
        : last.credentialInfo.issuer.fullId == attr.credentialInfo.issuer.fullId;
  }

  Widget _buildCarouselWidget(Con<Attribute> candidatesCon) {
    // Transform candidatesCon into a list where attributes of the same issuer
    // are grouped together. This assumes those attributes are always
    // adjacent within the specified con, which is guaranteed by irmago.
    final grouped = candidatesCon.fold(
      <List<Attribute>>[],
      (List<List<Attribute>> list, attr) => _group(list, attr) ? (list..last.add(attr)) : (list..add([attr])),
    ).toList();
    final credentials = grouped
        .asMap()
        .map(
          (i, list) => MapEntry(i, _DisclosureCredential(attributes: Con(list), isLast: i == grouped.length - 1)),
        )
        .values;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...credentials
              .map((cred) => <Widget>[
                    ...cred.attributes.map((attribute) => _buildAttribute(attribute)).toList(),
                    _buildCredentialFooter(cred),
                  ])
              .expand((f) => f)
              .toList(),
        ],
      ),
    );
  }
}

class _DisclosureCredential {
  final Con<Attribute> attributes;
  final String id;
  final TranslatedValue issuer;
  final bool isLast;
  final bool obtainable;

  _DisclosureCredential({@required this.attributes, @required this.isLast})
      : assert(isLast != null &&
            attributes != null &&
            attributes.isNotEmpty &&
            attributes
                .every((attr) => attr.credentialInfo.issuer.fullId == attributes.first.credentialInfo.issuer.fullId)),
        id = attributes.first.credentialInfo.fullId,
        issuer = attributes.first.credentialInfo.issuer.name,
        obtainable =
            !attributes.last.choosable && (attributes.last.credentialInfo.credentialType.issueUrl?.isNotEmpty ?? false);
}
