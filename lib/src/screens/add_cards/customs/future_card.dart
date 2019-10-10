import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import 'dash_path_border.dart';

class FutureCard extends StatelessWidget {
  final String name;
  final String issuer;
  final String logoPath;

  FutureCard(this.name, this.issuer, this.logoPath);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 0.5),
      child: AspectRatio(
        aspectRatio: 1.585,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white, //Theme.of(context).canvasColor,
            borderRadius: BorderRadius.circular(20.0),
            border: DashPathBorder.all(
              dashArray: CircularIntervalList<double>(<double>[6.0, 4.0]),
            ),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: Container(
                        child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Image.asset(logoPath),
                    )),
                  ),
                  Expanded(
                      flex: 3,
                      child: Container(
                          child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.subhead,
                        ),
                      ))),
                ],
              ),
              Expanded(
                child: Container(),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "Uitgifte",
                        style: TextStyle(fontSize: 14.0, color: Colors.black54, fontWeight: FontWeight.w400),
                      ),
                    ),
                  ),
                  Expanded(
                      flex: 3,
                      child: Container(
                          child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          issuer,
                          style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w700),
                        ),
                      ))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
