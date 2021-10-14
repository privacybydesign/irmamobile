// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/cupertino.dart';
import 'package:irmamobile/src/models/attribute_value.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';

// The Offstage in the Carousel widget requires this widget to persist a constant height.
class CarouselAttributes extends StatelessWidget {
  final List<Attribute> attributes;

  const CarouselAttributes({
    Key key,
    @required this.attributes,
  }) : super(key: key);

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
    } else if (candidate.value is TextValue) {
      return Text(
        getTranslation(context, (candidate.value as TextValue).translated),
        style: IrmaTheme.of(context).textTheme.bodyText1,
      );
    } else {
      // In case of a NullValue we fully skip the candidate value. A NullValue occurs in non-present optional
      // attributes and when the requested attribute is missing in the user's wallet and no specific value is specified.
      return Container();
    }
  }

  Widget _buildAttribute(BuildContext context, Attribute attribute) => Padding(
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

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: attributes.map((attr) => _buildAttribute(context, attr)).toList(),
      );
}
