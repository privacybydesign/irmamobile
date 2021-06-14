import 'package:flutter/cupertino.dart';
import 'package:irmamobile/src/models/attribute_value.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';

// The Offstage in the Carousel widget requires this widget to persist a constant height.
class CarouselAttributes extends StatelessWidget {
  final Iterable<Attribute> attributes;

  const CarouselAttributes({Key key, this.attributes}) : super(key: key);

  Widget _buildCandidateValue(BuildContext context, Attribute candidate) {
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

    //TODO: Does this always work?
    String text;
    if (candidate.value is NullValue) {
      text = '…';
    } else {
      text = getTranslation(context, (candidate.value as TextValue).translated);
    }
    return Text(
      text,
      style: IrmaTheme.of(context).textTheme.bodyText1,
    );
  }

  Widget _buildAttribute(BuildContext context, Attribute attribute) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).tinySpacing),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslation(context, attribute.attributeType.name),
            style: IrmaTheme.of(context)
                .textTheme
                .bodyText2
                .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          _buildCandidateValue(context, attribute),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: attributes.map((attr) => _buildAttribute(context, attr)).toList(),
      );
}
