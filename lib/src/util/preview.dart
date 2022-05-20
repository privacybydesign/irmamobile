import 'package:flutter/cupertino.dart';
import 'package:irmamobile/src/screens/error/blocked_screen.dart';
import 'package:irmamobile/src/screens/error/error_screen.dart';
import 'package:irmamobile/src/screens/error/no_internet_screen.dart';

Widget? previewFlow(String name) {
  switch (name) {
    case "NoInternetScreen":
      return NoInternetScreen(
        onTapClose: () {},
        onTapRetry: () {},
      );

    case "BlockedScreen":
      return BlockedScreen();

    case "ErrorScreen":
      return ErrorScreen(onTapClose: () {});
  }

  return null;
}
