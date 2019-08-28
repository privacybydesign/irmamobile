import 'package:flutter/material.dart';

class IrmaCardState extends State<IrmaCard> {
  @override
  Widget build(BuildContext context) {
    final indent = 100.0;
    final headerBottom = 30.0;
    final personalData = [
      {'key': 'Geboren', 'value': '4 juli 1990'},
      {'key': 'E-mail', 'value': 'anouk.meijer@gmail.com'},
    ];

    List<Widget> getDataLines() {
      var textLines = <Widget>[
        Padding(
          padding: EdgeInsets.only(left: indent, bottom: headerBottom),
          child: Text(
            "Persoonsgegevens",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        Divider(color: Color(0xaaffffff)),
      ];

      for (var i = 0; i < personalData.length; i++) {
        textLines.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  child: Text(personalData[i]['key'],
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      )),
                  width: indent,
                ),
                Text(
                  personalData[i]['value'],
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return textLines;
    }

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: getDataLines(),
      ),
      width: 320.0,
      height: 240.0,
      padding: const EdgeInsets.all(15),
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
