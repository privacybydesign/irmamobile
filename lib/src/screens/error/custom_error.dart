import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

class CustomError extends StatelessWidget {
  final TranslatedText errorText;

  const CustomError({this.errorText});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: IrmaTheme.of(context).defaultSpacing,
        ),
        Center(
          child: SvgPicture.asset(
            'assets/error/general.svg',
            fit: BoxFit.scaleDown,
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(IrmaTheme.of(context).mediumSpacing),
            child: SingleChildScrollView(child: errorText),
          ),
        ),
      ],
    );
  }
}
