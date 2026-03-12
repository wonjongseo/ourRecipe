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

  static String get interstitial {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ca-app-pub-9712392194582442/7735121688'; //TODO
      case TargetPlatform.iOS:
        return 'ca-app-pub-9712392194582442/5244689715';
      default:
        return '';
    }
  }

  static String get native {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ca-app-pub-3940256099942544/2247696110'; //TODO
      case TargetPlatform.iOS:
        return 'ca-app-pub-9712392194582442/2650820541';
      default:
        return '';
    }
  }
}
