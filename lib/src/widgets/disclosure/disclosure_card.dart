import 'package:flutter/material.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/disclosure/carousel.dart';

class DisclosureCard extends StatefulWidget {
  final ConDisCon<Attribute> candidatesConDisCon;
  final Function(int, int) onCurrentPageUpdate;
  final Function() onIssue;
  final bool showObtainButton;

  const DisclosureCard({
    this.candidatesConDisCon,
    this.onCurrentPageUpdate,
    this.onIssue,
    this.showObtainButton = true,
  }) : super();

  @override
  _DisclosureCardState createState() => _DisclosureCardState();
}

class _DisclosureCardState extends State<DisclosureCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      semanticContainer: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(IrmaTheme.of(context).defaultSpacing),
        side: const BorderSide(color: Color(0xFFDFE3E9), width: 1),
      ),
      color: IrmaTheme.of(context).primaryLight,
      child: Column(
        children: [
          SizedBox(height: IrmaTheme.of(context).smallSpacing),
          ...widget.candidatesConDisCon
              .asMap()
              .entries
              .expand(
                (entry) => [
                  // Display a divider except for the first element
                  if (entry.key != 0)
                    Divider(
                      color: IrmaTheme.of(context).grayscale80,
                    ),
                  StreamBuilder<Credentials>(
                    stream: IrmaRepository.get().getCredentials(),
                    builder: (context, credentialsSnapshot) => credentialsSnapshot.hasData
                        ? Carousel(
                            candidatesDisCon: entry.value,
                            onCurrentPageUpdate: (int page) => widget.onCurrentPageUpdate(entry.key, page),
                            showObtainButton: widget.showObtainButton,
                            onIssue: widget.onIssue,
                            credentials: credentialsSnapshot.data.values.toList(),
                          )

                        /// Credentials are already loaded on app start-up, so the fallback is never visible.
                        : Container(),
                  ),
                ],
              )
              .toList(),
          SizedBox(height: IrmaTheme.of(context).smallSpacing),
        ],
      ),
    );
  }
}
