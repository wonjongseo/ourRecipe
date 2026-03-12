import 'dart:io';

class InAppProductIds {
  InAppProductIds._();

  static const String premiumAndroid = 'our_recipe_premium';
  static const String premiumIOS = 'our_recipe_premium';

  static String get premium {
    if (Platform.isIOS) return premiumIOS;
    return premiumAndroid;
  }
}
