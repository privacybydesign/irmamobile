import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child:
              const CircularProgressIndicator() //LoadingIndicator(), TODO: find out why tests fail when using LoadingIndicator
          ),
    );
  }
}
