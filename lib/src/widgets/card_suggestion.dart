import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';

class CardSuggestion extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subTitle;
  final bool obtained;
  final int daysUntilExpiration;
  final VoidCallback onTap;


  const CardSuggestion({
    @required this.icon,
    @required this.title,
    @required this.subTitle,
    @required this.obtained,
    this.daysUntilExpiration = 40, // TODO get this info from scheme
    this.onTap,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.0),
      child: Card(
        elevation: 3.0,
        semanticContainer: true,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: IrmaTheme.of(context).grayscale85, width: 0.2),
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
                      minWidth: 54.0,
                      maxHeight: 54.0,
                      maxWidth: 54.0,
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
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                        child: Text(
                          title,
                          style: IrmaTheme.of(context).textTheme.display2,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                        child: Text(
                          subTitle,
                          style: IrmaTheme.of(context).textTheme.body1.copyWith(
                                color: IrmaTheme.of(context).linkVisitedColor,
                              ),
                        ),
                      ),
                      if (daysUntilExpiration <= 0) Padding(
                        padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                        child : Text(
                          "Your card has expired", // TODO add text in en/nl file and get info from scheme
                          style: IrmaTheme.of(context).textTheme.body1.copyWith(
                                color: IrmaTheme.of(context).interactionInvalid,
                              ),
                        ),
                      ) else if (daysUntilExpiration < 30) Padding(
                        padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                        child : Text(
                          "Expires in π days", // TODO add text in en/nl file and get info from scheme
                          style: IrmaTheme.of(context).textTheme.body1.copyWith(
                                color: IrmaTheme.of(context).interactionAlert,
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
                      padding: const EdgeInsets.only(top: 8.0, right: 16.0, bottom: 8.0),
                      child: Icon(
                        obtained ? IrmaIcons.synchronize : IrmaIcons.add,
                        size: 20,
                        color: IrmaTheme.of(context).primaryBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
