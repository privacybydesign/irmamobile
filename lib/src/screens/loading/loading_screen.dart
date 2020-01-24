import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
          // TODO: We want LoadingIndicator, but need to find out why tests fail
          // when using LoadingIndicator
          child: CircularProgressIndicator()),
    );
  }
}
