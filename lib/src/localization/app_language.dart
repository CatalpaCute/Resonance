import 'dart:ui';

enum AppLanguageMode {
  system,
  zhCn,
  zhHant,
  english,
}

const Locale appLocaleZhCn = Locale('zh', 'CN');
const Locale appLocaleZhHant = Locale.fromSubtags(
    languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK');
const Locale appLocaleEnglish = Locale('en');
const List<Locale> supportedAppLocales = <Locale>[
  appLocaleZhCn,
  appLocaleZhHant,
  appLocaleEnglish,
];

extension AppLanguageModeX on AppLanguageMode {
  String get storageValue {
    switch (this) {
      case AppLanguageMode.system:
        return 'system';
      case AppLanguageMode.zhCn:
        return 'zh_cn';
      case AppLanguageMode.zhHant:
        return 'zh_hant';
      case AppLanguageMode.english:
        return 'en';
    }
  }

  Locale? get explicitLocale {
    switch (this) {
      case AppLanguageMode.system:
        return null;
      case AppLanguageMode.zhCn:
        return appLocaleZhCn;
      case AppLanguageMode.zhHant:
        return appLocaleZhHant;
      case AppLanguageMode.english:
        return appLocaleEnglish;
    }
  }

  static AppLanguageMode fromStorageValue(String? raw) {
    for (final AppLanguageMode mode in AppLanguageMode.values) {
      if (mode.storageValue == raw) {
        return mode;
      }
    }
    return AppLanguageMode.system;
  }
}

Locale resolveSupportedAppLocale(Locale? locale) {
  if (locale == null) {
    return appLocaleEnglish;
  }
  if (locale.languageCode == 'zh') {
    if (_isTraditionalChinese(locale)) {
      return appLocaleZhHant;
    }
    return appLocaleZhCn;
  }
  if (locale.languageCode == 'en') {
    return appLocaleEnglish;
  }
  return appLocaleEnglish;
}

Locale resolveAppLocale(AppLanguageMode mode, {Locale? systemLocale}) {
  return mode.explicitLocale ?? resolveSupportedAppLocale(systemLocale);
}

bool _isTraditionalChinese(Locale locale) {
  final String scriptCode = (locale.scriptCode ?? '').toLowerCase();
  if (scriptCode == 'hant') {
    return true;
  }

  final String countryCode = (locale.countryCode ?? '').toUpperCase();
  return countryCode == 'HK' || countryCode == 'MO' || countryCode == 'TW';
}
