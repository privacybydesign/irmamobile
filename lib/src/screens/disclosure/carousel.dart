import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';

class Carousel extends StatefulWidget {
  final List<Widget> credentialSet;

  const Carousel({@required this.credentialSet});

  @override
  _CarouselState createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  final GlobalKey _keyStackedIndex = GlobalKey();
  final _animationDuration = 250;

  double height;
  int currentPage = 0;

  final _controller = PageController();

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
      currentPage = page % widget.credentialSet.length;
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
            child: IndexedStack(key: _keyStackedIndex, index: currentPage, children: widget.credentialSet),
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
                itemCount: widget.credentialSet.length,
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _controller,
                onPageChanged: (int page) {
                  getChangedPageAndMoveBar(page);
                },
                itemBuilder: (BuildContext context, int index) {
                  return widget.credentialSet[index % widget.credentialSet.length];
                },
              ),
            ),
            if (widget.credentialSet.length > 1) navBar(),
          ],
        );

  Widget navBar() => Container(
        height: 60.0,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            Positioned(
              left: 0,
              child: arrowButton(
                icon: IrmaIcons.chevronLeft,
                label: "disclosure.previous",
                isVisible: currentPage > 0,
                delta: -1,
                size: widget.credentialSet.length,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Spacer(flex: 15),
                Row(
                  children: <Widget>[
                    const Spacer(),
                    ...List.generate(widget.credentialSet.length, (i) => dotsIndicator(isActive: i == currentPage)),
                    const Spacer(),
                  ],
                ),
                const Spacer(flex: 3),
                Center(
                  child: Text(
                    FlutterI18n.translate(
                        context, 'disclosure.choices', {"choices": widget.credentialSet.length.toString()}),
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
              child: arrowButton(
                icon: IrmaIcons.chevronRight,
                label: "disclosure.next",
                isVisible: currentPage < widget.credentialSet.length - 1,
                delta: 1,
                size: widget.credentialSet.length,
              ),
            ),
          ],
        ),
      );

  Widget dotsIndicator({bool isActive}) => AnimatedContainer(
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

  Widget arrowButton({IconData icon, String label, bool isVisible, int delta, int size}) => AnimatedOpacity(
        opacity: isVisible ? 1 : 0,
        duration: Duration(milliseconds: _animationDuration),
        child: Semantics(
          button: true,
          label: FlutterI18n.translate(context, label),
          child: IconButton(
            icon: Icon(icon, color: IrmaTheme.of(context).interactionInformation),
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
        ),
      );
}
