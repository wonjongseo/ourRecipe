import 'package:flutter/foundation.dart';

class AdMobUnitIds {
  AdMobUnitIds._();

  static String get banner {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ca-app-pub-3940256099942544/6300978111';
      case TargetPlatform.iOS:
        return 'ca-app-pub-9712392194582442/7562526018';
      default:
        return '';
    }
  }
}
