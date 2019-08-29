import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IrmaCardState extends State<IrmaCard> {
  @override
  Widget build(BuildContext context) {
    const indent = 100.0;
    const headerBottom = 30.0;
    const borderRadius = Radius.circular(15.0);
    const padding = 15.0;
    const personalData = [
      {'key': 'Naam', 'value': 'Anouk Meijer'},
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
        children: <Widget>[
          Expanded(
            child: Padding(
                padding: const EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: getDataLines(),
                )),
          ),
          Container(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: IconButton(
                    icon: SvgPicture.asset('assets/icons/arrow-down.svg'),
                    padding: EdgeInsets.only(left: padding),
                    alignment: Alignment.centerLeft,
                    onPressed: () {
                      print('unfold');
                    },
                  ),
                ),
                IconButton(
                  icon: SvgPicture.asset('assets/icons/update.svg'),
                  padding: EdgeInsets.only(right: padding),
                  onPressed: () {
                    print('update');
                  },
                ),
                IconButton(
                  icon: SvgPicture.asset('assets/icons/delete.svg'),
                  padding: EdgeInsets.only(right: padding),
                  onPressed: () {
                    print('delete');
                  },
                ),
              ],
            ),
            height: 50,
            decoration: BoxDecoration(
              color: Color(0x55ffffff),
              borderRadius: BorderRadius.only(
                bottomLeft: borderRadius,
                bottomRight: borderRadius,
              ),
            ),
          ),
        ],
      ),
      height: 240.0,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
          color: Color(0xffec0000),
          borderRadius: BorderRadius.all(
            borderRadius,
          ),
          image: DecorationImage(
              image: AssetImage('assets/issuers/amsterdam/bg.png'),
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter)),
    );
  }
}

class IrmaCard extends StatefulWidget {
  @override
  IrmaCardState createState() => IrmaCardState();
}
