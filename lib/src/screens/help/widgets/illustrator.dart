import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../theme/theme.dart';
import '../../../widgets/yivi_progress_indicator.dart';

class Illustrator extends StatefulWidget {
  final List<Widget> imageSet;
  final List<String> textSet;
  final double height;
  final double width;

  const Illustrator({
    required this.imageSet,
    required this.textSet,
    required this.height,
    required this.width,
  });

  @override
  _IllustratorState createState() => _IllustratorState();
}

class _IllustratorState extends State<Illustrator> with SingleTickerProviderStateMixin {
  late double height;
  int currentPage = 0;

  final _controller = PageController();

  // getChangedPageAndMoveBar from
  // https://medium.com/aubergine-solutions/create-an-onboarding-page-indicator-in-3-minutes-in-flutter-a2bd97ceeaff
  void getChangedPageAndMoveBar(int page) {
    setState(() {
      currentPage = page % widget.imageSet.length;
    });
  }

  String slideshowAccessibilityDescription(int page) {
    return FlutterI18n.translate(context, 'accessibility.slideshow', translationParams: {
      'i': (page + 1).toString(),
      'n': widget.imageSet.length.toString(),
      'description': widget.textSet[page],
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Semantics(
      excludeSemantics: true,
      container: true,
      value: slideshowAccessibilityDescription(currentPage),
      increasedValue:
          currentPage + 1 < widget.imageSet.length ? slideshowAccessibilityDescription(currentPage + 1) : null,
      decreasedValue: currentPage > 0 ? slideshowAccessibilityDescription(currentPage - 1) : null,
      onIncrease: currentPage + 1 < widget.imageSet.length
          ? () {
              if (_controller.hasClients && currentPage + 1 < widget.imageSet.length) {
                _controller.animateToPage(
                  currentPage + 1,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            }
          : null,
      onDecrease: currentPage > 0
          ? () {
              if (_controller.hasClients && currentPage > 0) {
                _controller.animateToPage(
                  currentPage - 1,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            }
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: SizedBox(
              height: widget.height,
              width: widget.width,
              child: PageView.builder(
                itemCount: widget.imageSet.length,
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _controller,
                onPageChanged: (int page) {
                  getChangedPageAndMoveBar(page);
                },
                itemBuilder: (BuildContext context, int index) {
                  return widget.imageSet[index % widget.imageSet.length];
                },
              ),
            ),
          ),
          SizedBox(
            height: theme.defaultSpacing,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: SizedBox(
              width: widget.width,
              child: Text(
                widget.textSet[currentPage],
                key: ValueKey<int>(currentPage),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (widget.imageSet.length > 1) ...[
            SizedBox(
              height: theme.defaultSpacing,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                YiviProgressIndicator(
                  stepCount: widget.imageSet.length,
                  stepIndex: currentPage,
                ),
              ],
            ),
          ],
          SizedBox(
            height: theme.smallSpacing,
          ),
        ],
      ),
    );
  }
}
