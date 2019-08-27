import 'package:flutter/material.dart';

class IrmaCardState extends State<IrmaCard> {
    @override
    Widget build(BuildContext context) {
        final indent = 100.0;
        final padingLeft = 15.0;
        final personalDataTop = 60.0;
        final lineHeight = 20.0;
        final personal = [
            {'key': 'Geboren', 'value': '4 juli 1990'},
            {'key': 'E-mail', 'value': 'anouk.meijer@gmail.com'},
        ];

        List<Positioned> getDataLines() {
            var textLines = [
                Positioned(
                    // red box
                    child: Text(
                        "Persoonsgegevens",
                        style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                        ),
                    ),
                    left: indent,
                    top: padingLeft,
                ),
            ];

            for (var i = 0; i < personal.length; i++) {
                textLines.add(
                    Positioned(
                        child: Text(
                            personal[i]['key'],
                            style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                            ),
                        ),
                        left: padingLeft,
                        top: personalDataTop + i * lineHeight,
                    ),
                );
                textLines.add(
                    Positioned(
                        child: Text(
                            personal[i]['value'],
                            style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                            ),
                        ),
                        left: indent,
                        top: personalDataTop + i * lineHeight,
                    ),
                );
            }return textLines;
        }

        return Container(
            child: Stack(
                children: getDataLines(),
            ),
            width: 320.0,
            height: 240.0,
            decoration: BoxDecoration(
                color: Color(0xffec0000),
                borderRadius: BorderRadius.all(
                    const Radius.circular(15.0),
                ),
            ),
        );
    }
}

class IrmaCard extends StatefulWidget {
    @override
    IrmaCardState createState() => IrmaCardState();
}
