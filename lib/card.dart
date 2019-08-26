import 'package:flutter/material.dart';

class IrmaCardState extends State<IrmaCard> {
    @override
    Widget build(BuildContext context) {
        return Container(
            // grey box
            child: Text(
                "Card",
                style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w900,
                    fontFamily: "Georgia",
                ),
            ),
            width: 320.0,
            height: 240.0,
            color: Colors.grey[300],
        );
    }
}

class IrmaCard extends StatefulWidget {
    @override
    IrmaCardState createState() => IrmaCardState();
}
