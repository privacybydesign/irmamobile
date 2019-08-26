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
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            left: 100,
            top: 15,
          ),
            Positioned(
                // red box
                child: Text(
                    "Geboren",
                    style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                    ),
                ),
                left: 15,
                top: 60,
            ),
            Positioned(
                // red box
                child: Text(
                    "4 juli 1990",
                    style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                    ),
                ),
                left: 100,
                top: 60,
            ),
            Positioned(
                // red box
                child: Text(
                    "E-mail",
                    style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                    ),
                ),
                left: 15,
                top: 80,
            ),
            Positioned(
                // red box
                child: Text(
                    "anouk.meijer@gmail.com",
                    style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                    ),
                ),
                left: 100,
                top: 80,
            ),
        ],
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
