import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/svg.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/screens/help/widgets/illustrator.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/collapsible.dart';

class DemoItems extends StatefulWidget {
  const DemoItems({this.credentialType, this.parentKey, this.parentScrollController});

  final CredentialType credentialType;
  final GlobalKey parentKey;
  final ScrollController parentScrollController;

  @override
  _DemoItemsState createState() => _DemoItemsState();
}

class _DemoItemsState extends State<DemoItems> with TickerProviderStateMixin {
  final List<GlobalKey> _collapsableKeys = List<GlobalKey>.generate(4, (int index) => GlobalKey());
  Duration expandDuration = const Duration(milliseconds: 200); // expand duration of _Collapsible

  void _jumpToCollapsable(int index) {
    final RenderObject scrollview = widget.parentKey.currentContext.findRenderObject();
    final RenderBox collapsable = _collapsableKeys[index].currentContext.findRenderObject() as RenderBox;
    widget.parentScrollController.animateTo(
      collapsable.localToGlobal(Offset(0, widget.parentScrollController.offset), ancestor: scrollview).dy,
      duration: const Duration(
        milliseconds: 500,
      ),
      curve: Curves.ease,
    );
  }

  // Content for question 1
  @override
  Widget build(BuildContext context) {
    final List<Widget> _demoPagesQuestion1 = <Widget>[
      Container(
        child: Center(
          child: SizedBox(child: SvgPicture.asset('assets/help/q1_step_1.svg')),
        ),
      ),
      Container(
        child: Center(
          child: SizedBox(child: SvgPicture.asset('assets/help/q1_step_2.svg')),
        ),
      ),
      Container(
        child: Center(
          child: SizedBox(child: SvgPicture.asset('assets/help/q1_step_3.svg')),
        ),
      ),
      Container(
        child: Center(
          child: SizedBox(child: SvgPicture.asset('assets/help/q1_step_4.svg')),
        ),
      ),
    ];

    final List<Widget> _demoTextsQuestion1 = [
      Text(
        FlutterI18n.translate(context, 'demo.answer_1.step_1'),
        textAlign: TextAlign.center,
      ),
      Text(
        FlutterI18n.translate(context, 'demo.answer_1.step_2'),
        textAlign: TextAlign.center,
      ),
      Text(
        FlutterI18n.translate(context, 'demo.answer_1.step_3'),
        textAlign: TextAlign.center,
      ),
      Text(
        FlutterI18n.translate(context, 'demo.answer_1.step_4'),
        textAlign: TextAlign.center,
      ),
    ];

    // Content for question 2
    final List<Widget> _demoPagesQuestion2 = <Widget>[
      Container(
        child: Center(
          child: SizedBox(child: SvgPicture.asset('assets/help/q2_step_1.svg')),
        ),
      ),
      Container(
        child: Center(
          child: SizedBox(child: SvgPicture.asset('assets/help/q2_step_2.svg')),
        ),
      ),
      Container(
        child: Center(
          child: SizedBox(child: SvgPicture.asset('assets/help/q2_step_3.svg')),
        ),
      ),
      Container(
        child: Center(
          child: SizedBox(child: SvgPicture.asset('assets/help/q2_step_4.svg')),
        ),
      ),
      Container(
        child: Center(
          child: SizedBox(child: SvgPicture.asset('assets/help/q2_step_5.svg')),
        ),
      ),
    ];

    final List<Widget> _demoTextsQuestion2 = [
      Text(
        FlutterI18n.translate(context, 'demo.answer_2.step_1'),
        textAlign: TextAlign.center,
      ),
      Text(
        FlutterI18n.translate(context, 'demo.answer_2.step_2'),
        textAlign: TextAlign.center,
      ),
      Text(
        FlutterI18n.translate(context, 'demo.answer_2.step_3'),
        textAlign: TextAlign.center,
      ),
      Text(
        FlutterI18n.translate(context, 'demo.answer_2.step_4'),
        textAlign: TextAlign.center,
      ),
      Text(
        FlutterI18n.translate(context, 'demo.answer_2.step_5'),
        textAlign: TextAlign.center,
      ),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Collapsible(
            header: FlutterI18n.translate(context, 'demo.question_1'),
            onExpansionChanged: (v) => {if (v) Future.delayed(expandDuration, () => _jumpToCollapsable(0))},
            content: Column(
              children: <Widget>[
                SizedBox(
                  height: IrmaTheme.of(context).smallSpacing,
                ),
                Illustrator(
                  imageSet: _demoPagesQuestion1,
                  textSet: _demoTextsQuestion1,
                  width: 280.0,
                  height: 220.0,
                ),
              ],
            ),
            key: _collapsableKeys[0]),
        Collapsible(
            header: FlutterI18n.translate(context, 'demo.question_2'),
            onExpansionChanged: (v) => {if (v) Future.delayed(expandDuration, () => _jumpToCollapsable(1))},
            content: Column(
              children: <Widget>[
                SizedBox(
                  height: IrmaTheme.of(context).smallSpacing,
                ),
                Illustrator(
                  imageSet: _demoPagesQuestion2,
                  textSet: _demoTextsQuestion2,
                  width: 280.0,
                  height: 220.0,
                ),
              ],
            ),
            key: _collapsableKeys[1]),
      ],
    );
  }
}
