import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';

class CardSuggestion extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subTitle;
  final bool obtained;
  final VoidCallback onTap;

  const CardSuggestion({
    @required this.icon,
    @required this.title,
    @required this.subTitle,
    @required this.obtained,
    this.onTap,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
      ),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 24.0, bottom: 8.0, right: 8.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 54.0,
                    minWidth: 20.0,
                    maxHeight: 54.0,
                    maxWidth: 40.0,
                  ),
                  child: obtained
                      ? Stack(
                          children: <Widget>[
                            Container(
                              foregroundDecoration: BoxDecoration(
                                color: Colors.grey,
                                backgroundBlendMode: BlendMode.saturation,
                              ),
                              child: Opacity(
                                opacity: 0.3,
                                child: icon,
                              ),
                            ),
                            Center(
                              child: Icon(
                                IrmaIcons.alert,
                                color: IrmaTheme.of(context).interactionInvalid,
                              ),
                            ),
                          ],
                        )
                      : icon,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        title,
                        style: IrmaTheme.of(context).textTheme.display2,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                      child: obtained
                          ? Text(
                              "Expires in π days",
                              style: IrmaTheme.of(context).textTheme.body1.copyWith(
                                    color: IrmaTheme.of(context).interactionInvalid,
                                  ),
                            )
                          : Text(
                              subTitle,
                              style: IrmaTheme.of(context).textTheme.body1.copyWith(
                                    color: IrmaTheme.of(context).linkVisitedColor,
                                  ),
                            ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      obtained ? IrmaIcons.synchronize : IrmaIcons.add,
                      size: 16,
                      color: IrmaTheme.of(context).primaryBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
