import 'package:flutter/material.dart';

class IrmaCardState extends State<IrmaCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // grey box
      child: Stack(
        children: [
          Positioned(
            // red box
            child: Text(
              "Persoonsgegevens",
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            left: 100,
            top: 30,
          )
        ],
      ),
      width: 320.0,
      height: 240.0,
      decoration: BoxDecoration(
        color: Colors.red[400],
        borderRadius: BorderRadius.all(
          const Radius.circular(8.0),
        ),
      ),
    );
  }
}

class IrmaCard extends StatefulWidget {
  @override
  IrmaCardState createState() => IrmaCardState();
}
