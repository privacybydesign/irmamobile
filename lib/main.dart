import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IRMA Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'IRMA'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: IrmaCard()
      ),
    );
  }
}

// ===============

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
