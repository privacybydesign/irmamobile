import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            CircularProgressIndicator(),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Loading... (UI TODO)"),
            ),
          ],
        ),
      ),
    );
  }
}
