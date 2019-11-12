import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/add_cards/customs/configurable_expansion_tile.dart';
import 'package:irmamobile/src/theme/theme.dart';

class CardQuestions extends StatefulWidget {
  const CardQuestions(this.parentKey, this.parentScrollController);

  final GlobalKey parentKey;
  final ScrollController parentScrollController;

  @override
  _CardQuestionsState createState() => _CardQuestionsState();
}

class _CardQuestionsState extends State<CardQuestions> with TickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Collapsible(
            header: FlutterI18n.translate(context, 'card_store.card_info.issuer_question'),
            onExpansionChanged: (v) => {if (v) Future.delayed(expandDuration, () => _jumpToCollapsable(0))},
            content: "De tekst hier komt uit het scheme. De tekst hier komt uit het scheme.",
            key: _collapsableKeys[0]),
        _Collapsible(
            header: FlutterI18n.translate(context, 'card_store.card_info.provided_attributes_question'),
            onExpansionChanged: (v) => {if (v) Future.delayed(expandDuration, () => _jumpToCollapsable(1))},
            content:
                " Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin ac dolor vel eros dapibus lobortis. Nam ex metus, ultrices vitae dapibus id, maximus non tortor. Duis gravida varius orci consectetur congue. Donec molestie sit amet nisl et fringilla. In eu metus quis nunc laoreet suscipit. Donec vitae pretium libero, lobortis cursus ipsum. Integer pretium semper ex.Proin sed eleifend ipsum. Aenean sollicitudin arcu ut scelerisque varius. Mauris varius tortor massa, nec interdum mauris dignissim vel. Vestibulum ullamcorper facilisis lacus vel tincidunt. Aliquam erat volutpat. Fusce elit sapien, consectetur vitae nunc sit amet, suscipit tincidunt enim. Nunc turpis nisi, vestibulum id lacus ut, feugiat volutpat lorem. Integer hendrerit dolor pellentesque, lacinia dui ac, efficitur eros. Aliquam dignissim neque nec molestie consequat.Mauris ultrices quam eu arcu suscipit feugiat ultricies quis magna. Praesent auctor leo a vulputate imperdiet. Fusce eget dolor sagittis, elementum sapien feugiat, semper metus. Duis vel massa fermentum enim pharetra imperdiet. Nunc elementum sapien in metus porta, sed cursus justo consequat. Aenean vehicula diam eget elit auctor ultrices. Nulla tortor neque, lobortis vitae erat vel, pretium sodales tortor. Nulla aliquam faucibus bibendum. Proin eros nisi, porta nec euismod eget, accumsan eget odio. Nullam interdum in diam ut mattis. Duis ac nunc pulvinar, varius dui et, consectetur neque. Quisque aliquam urna orci, id vehicula nibh interdum eget. Donec ullamcorper ante et est interdum, a congue nulla varius. Vivamus a sollicitudin elit. ",
            key: _collapsableKeys[1]),
        _Collapsible(
            header: FlutterI18n.translate(context, 'card_store.card_info.expiration_question'),
            onExpansionChanged: (v) => {if (v) Future.delayed(expandDuration, () => _jumpToCollapsable(2))},
            content:
                " Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin ac dolor vel eros dapibus lobortis. Nam ex metus, ultrices vitae dapibus id, maximus non tortor. Duis gravida varius orci consectetur congue. Donec molestie sit amet nisl et fringilla. In eu metus quis nunc laoreet suscipit. Donec vitae pretium libero, lobortis cursus ipsum. Integer pretium semper ex.Proin sed eleifend ipsum. Aenean sollicitudin arcu ut scelerisque varius. Mauris varius tortor massa, nec interdum mauris dignissim vel. Vestibulum ullamcorper facilisis lacus vel tincidunt. Aliquam erat volutpat. Fusce elit sapien, consectetur vitae nunc sit amet, suscipit tincidunt enim. Nunc turpis nisi, vestibulum id lacus ut, feugiat volutpat lorem. Integer hendrerit dolor pellentesque, lacinia dui ac, efficitur eros. Aliquam dignissim neque nec molestie consequat.Mauris ultrices quam eu arcu suscipit feugiat ultricies quis magna. Praesent auctor leo a vulputate imperdiet. Fusce eget dolor sagittis, elementum sapien feugiat, semper metus. Duis vel massa fermentum enim pharetra imperdiet. Nunc elementum sapien in metus porta, sed cursus justo consequat. Aenean vehicula diam eget elit auctor ultrices. Nulla tortor neque, lobortis vitae erat vel, pretium sodales tortor. Nulla aliquam faucibus bibendum. Proin eros nisi, porta nec euismod eget, accumsan eget odio. Nullam interdum in diam ut mattis. Duis ac nunc pulvinar, varius dui et, consectetur neque. Quisque aliquam urna orci, id vehicula nibh interdum eget. Donec ullamcorper ante et est interdum, a congue nulla varius. Vivamus a sollicitudin elit. ",
            key: _collapsableKeys[2]),
        _Collapsible(
            header: FlutterI18n.translate(context, 'card_store.card_info.how_does_it_work_question'),
            onExpansionChanged: (v) => {if (v) Future.delayed(expandDuration, () => _jumpToCollapsable(3))},
            content:
                " Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin ac dolor vel eros dapibus lobortis. Nam ex metus, ultrices vitae dapibus id, maximus non tortor. Duis gravida varius orci consectetur congue. Donec molestie sit amet nisl et fringilla. In eu metus quis nunc laoreet suscipit. Donec vitae pretium libero, lobortis cursus ipsum. Integer pretium semper ex.Proin sed eleifend ipsum. Aenean sollicitudin arcu ut scelerisque varius. Mauris varius tortor massa, nec interdum mauris dignissim vel. Vestibulum ullamcorper facilisis lacus vel tincidunt. Aliquam erat volutpat. Fusce elit sapien, consectetur vitae nunc sit amet, suscipit tincidunt enim. Nunc turpis nisi, vestibulum id lacus ut, feugiat volutpat lorem. Integer hendrerit dolor pellentesque, lacinia dui ac, efficitur eros. Aliquam dignissim neque nec molestie consequat.Mauris ultrices quam eu arcu suscipit feugiat ultricies quis magna. Praesent auctor leo a vulputate imperdiet. Fusce eget dolor sagittis, elementum sapien feugiat, semper metus. Duis vel massa fermentum enim pharetra imperdiet. Nunc elementum sapien in metus porta, sed cursus justo consequat. Aenean vehicula diam eget elit auctor ultrices. Nulla tortor neque, lobortis vitae erat vel, pretium sodales tortor. Nulla aliquam faucibus bibendum. Proin eros nisi, porta nec euismod eget, accumsan eget odio. Nullam interdum in diam ut mattis. Duis ac nunc pulvinar, varius dui et, consectetur neque. Quisque aliquam urna orci, id vehicula nibh interdum eget. Donec ullamcorper ante et est interdum, a congue nulla varius. Vivamus a sollicitudin elit. ",
            key: _collapsableKeys[3]),
      ],
    );
  }
}

class _Collapsible extends StatelessWidget {
  final String header;
  final String content;
  const _Collapsible({Key key, this.header, this.content, this.onExpansionChanged}) : super(key: key);
  final ValueChanged<bool> onExpansionChanged;

  @override
  Widget build(BuildContext context) {
    return ConfigurableExpansionTile(
      onExpansionChanged: onExpansionChanged,
      animatedWidgetFollowingHeader: const Padding(
        padding: EdgeInsets.all(4.0),
        child: Icon(
          Icons.expand_more,
          color: Colors.black,
        ),
      ),

      header: Expanded(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            header,
            style: Theme.of(context).textTheme.body2,
          ),
        ),
      ),
      headerBackgroundColorStart: IrmaTheme.of(context).grayscale90, // TODO: determine color
      expandedBackgroundColor: const Color(0x00000000), // TODO: define transparent in theme
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            content,
            style: Theme.of(context).textTheme.body1,
          ),
        )
      ],
    );
  }
}
