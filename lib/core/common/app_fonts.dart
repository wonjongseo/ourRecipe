import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFontOption {
  final String key;
  final String family;
  final String label;

  const AppFontOption({
    required this.key,
    required this.family,
    required this.label,
  });
}

class AppFonts {
  static const String koNotoSans = 'ko_noto_sans';
  static const String koNanumGothic = 'ko_nanum_gothic';
  static const String koGowunDodum = 'ko_gowun_dodum';
  static const String koIbmPlexSans = 'ko_ibm_plex_sans';
  static const String koBlackHanSans = 'ko_black_han_sans';
  static const String koNanumMyeongjo = 'ko_nanum_myeongjo';
  static const String koNotoSerif = 'ko_noto_serif';
  static const String koDoHyeon = 'ko_do_hyeon';
  static const String koStylish = 'ko_stylish';
  static const String koSongMyung = 'ko_song_myung';

  static const String jaNotoSans = 'ja_noto_sans';
  static const String jaMplus = 'ja_mplus';
  static const String jaZenKaku = 'ja_zen_kaku';
  static const String jaSawarabi = 'ja_sawarabi';
  static const String jaZenOldMincho = 'ja_zen_old_mincho';
  static const String jaKosugiMaru = 'ja_kosugi_maru';
  static const String jaBizUdGothic = 'ja_biz_ud_gothic';
  static const String jaBizUdMincho = 'ja_biz_ud_mincho';
  static const String jaKaiseiDecol = 'ja_kaisei_decol';
  static const String jaYuseiMagic = 'ja_yusei_magic';

  static const String enInter = 'en_inter';
  static const String enPoppins = 'en_poppins';
  static const String enNunitoSans = 'en_nunito_sans';
  static const String enWorkSans = 'en_work_sans';
  static const String enMerriweather = 'en_merriweather';
  static const String enLora = 'en_lora';
  static const String enDmSans = 'en_dm_sans';
  static const String enOutfit = 'en_outfit';
  static const String enManrope = 'en_manrope';
  static const String enPlayfairDisplay = 'en_playfair_display';

  static const List<AppFontOption> _koOptions = [
    AppFontOption(
      key: koNotoSans,
      family: 'Noto Sans KR',
      label: 'Noto Sans KR',
    ),
    AppFontOption(
      key: koNanumGothic,
      family: 'Nanum Gothic',
      label: 'Nanum Gothic',
    ),
    AppFontOption(
      key: koGowunDodum,
      family: 'Gowun Dodum',
      label: 'Gowun Dodum',
    ),
    AppFontOption(
      key: koIbmPlexSans,
      family: 'IBM Plex Sans KR',
      label: 'IBM Plex Sans KR',
    ),
    AppFontOption(
      key: koBlackHanSans,
      family: 'Black Han Sans',
      label: 'Black Han Sans',
    ),
    AppFontOption(
      key: koNanumMyeongjo,
      family: 'Nanum Myeongjo',
      label: 'Nanum Myeongjo',
    ),
    AppFontOption(
      key: koNotoSerif,
      family: 'Noto Serif KR',
      label: 'Noto Serif KR',
    ),
    AppFontOption(key: koDoHyeon, family: 'Do Hyeon', label: 'Do Hyeon'),
    AppFontOption(key: koStylish, family: 'Stylish', label: 'Stylish'),
    AppFontOption(key: koSongMyung, family: 'Song Myung', label: 'Song Myung'),
  ];

  static const List<AppFontOption> _jaOptions = [
    AppFontOption(
      key: jaNotoSans,
      family: 'Noto Sans JP',
      label: 'Noto Sans JP',
    ),
    AppFontOption(
      key: jaMplus,
      family: 'M PLUS 1p',
      label: 'M PLUS 1p',
    ),
    AppFontOption(
      key: jaZenKaku,
      family: 'Zen Kaku Gothic New',
      label: 'Zen Kaku Gothic New',
    ),
    AppFontOption(
      key: jaSawarabi,
      family: 'Sawarabi Gothic',
      label: 'Sawarabi Gothic',
    ),
    AppFontOption(
      key: jaZenOldMincho,
      family: 'Zen Old Mincho',
      label: 'Zen Old Mincho',
    ),
    AppFontOption(
      key: jaKosugiMaru,
      family: 'Kosugi Maru',
      label: 'Kosugi Maru',
    ),
    AppFontOption(
      key: jaBizUdGothic,
      family: 'BIZ UDPGothic',
      label: 'BIZ UDPGothic',
    ),
    AppFontOption(
      key: jaBizUdMincho,
      family: 'BIZ UDMincho',
      label: 'BIZ UDMincho',
    ),
    AppFontOption(
      key: jaKaiseiDecol,
      family: 'Kaisei Decol',
      label: 'Kaisei Decol',
    ),
    AppFontOption(
      key: jaYuseiMagic,
      family: 'Yusei Magic',
      label: 'Yusei Magic',
    ),
  ];

  static const List<AppFontOption> _enOptions = [
    AppFontOption(key: enInter, family: 'Inter', label: 'Inter'),
    AppFontOption(key: enPoppins, family: 'Poppins', label: 'Poppins'),
    AppFontOption(
      key: enNunitoSans,
      family: 'Nunito Sans',
      label: 'Nunito Sans',
    ),
    AppFontOption(key: enWorkSans, family: 'Work Sans', label: 'Work Sans'),
    AppFontOption(
      key: enMerriweather,
      family: 'Merriweather',
      label: 'Merriweather',
    ),
    AppFontOption(key: enLora, family: 'Lora', label: 'Lora'),
    AppFontOption(key: enDmSans, family: 'DM Sans', label: 'DM Sans'),
    AppFontOption(key: enOutfit, family: 'Outfit', label: 'Outfit'),
    AppFontOption(key: enManrope, family: 'Manrope', label: 'Manrope'),
    AppFontOption(
      key: enPlayfairDisplay,
      family: 'Playfair Display',
      label: 'Playfair Display',
    ),
  ];

  static List<AppFontOption> optionsFor(Locale locale) {
    switch (locale.languageCode) {
      case 'ko':
        return _koOptions;
      case 'en':
        return _enOptions;
      default:
        return _jaOptions;
    }
  }

  static List<AppFontOption> get allOptions => [
    ..._koOptions,
    ..._jaOptions,
    ..._enOptions,
  ];

  static String defaultKeyFor(Locale locale) => optionsFor(locale).first.key;

  static bool isValidKey(String key) {
    return allOptions.any((option) => option.key == key);
  }

  static bool isValidKeyForLocale(String key, Locale locale) {
    return optionsFor(locale).any((option) => option.key == key);
  }

  static TextTheme textThemeFor({
    required String fontKey,
    required Locale locale,
    required TextTheme base,
  }) {
    final family = familyFor(fontKey: fontKey, locale: locale);
    return GoogleFonts.getTextTheme(family, base);
  }

  static String familyFor({
    required String fontKey,
    required Locale locale,
  }) {
    final options = optionsFor(locale);
    AppFontOption? matched;
    for (final option in options) {
      if (option.key == fontKey) {
        matched = option;
        break;
      }
    }
    matched ??= _findByKey(fontKey);
    matched ??= options.first;
    return matched.family;
  }

  static AppFontOption? _findByKey(String key) {
    for (final option in allOptions) {
      if (option.key == key) return option;
    }
    return null;
  }
}
