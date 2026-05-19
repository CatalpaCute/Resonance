import 'package:flutter/widgets.dart';

import '../models/app_route.dart';
import '../models/article.dart';
import '../models/reader_settings.dart';
import 'app_language.dart';

class AppBrand {
  static const String mark = 'R';
  static const String nameZhCn = '鍥炲搷';
  static const String nameZhHant = '鍥為熆';
  static const String nameEn = 'Resonance';
  static const String fullName = 'Resonance';
  static const String version = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: 'dev',
  );
  static const String repoUrl = 'https://github.com/CatalpaCute/Resonance';
}

enum _AppTextLanguage {
  zhCn,
  zhHant,
  en,
}

class AppStrings {
  const AppStrings._(this._language);

  final _AppTextLanguage _language;

  static AppStrings of(BuildContext context) {
    return fromLocale(Localizations.localeOf(context));
  }

  static AppStrings fromLanguageMode(
    AppLanguageMode mode, {
    Locale? systemLocale,
  }) {
    return fromLocale(resolveAppLocale(mode, systemLocale: systemLocale));
  }

  static AppStrings fromLocale(Locale locale) {
    final Locale resolved = resolveSupportedAppLocale(locale);
    if (resolved == appLocaleZhHant) {
      return const AppStrings._(_AppTextLanguage.zhHant);
    }
    if (resolved == appLocaleZhCn) {
      return const AppStrings._(_AppTextLanguage.zhCn);
    }
    return const AppStrings._(_AppTextLanguage.en);
  }

  static Locale resolveLocaleList(
    List<Locale>? locales,
    Iterable<Locale> supportedLocales,
  ) {
    if (locales != null) {
      for (final Locale locale in locales) {
        if (locale.languageCode == 'zh' || locale.languageCode == 'en') {
          return resolveSupportedAppLocale(locale);
        }
      }
    }
    return appLocaleEnglish;
  }

  String _text({
    required String zhCn,
    String? zhHant,
    required String en,
  }) {
    switch (_language) {
      case _AppTextLanguage.zhCn:
        return zhCn;
      case _AppTextLanguage.zhHant:
        return zhHant ?? zhCn;
      case _AppTextLanguage.en:
        return en;
    }
  }

  String get appName => _text(
        zhCn: AppBrand.nameZhCn,
        zhHant: AppBrand.nameZhHant,
        en: AppBrand.nameEn,
      );

  String get appFullName => _text(
        zhCn: AppBrand.fullName,
        zhHant: AppBrand.fullName,
        en: AppBrand.fullName,
      );

  String routeTitle(
    AppRouteId route, {
    String? activeSourceTitle,
    String? selectedArticleTitle,
    BookmarkFilter? bookmarkFilter,
  }) {
    switch (route) {
      case AppRouteId.allArticles:
        return allArticles;
      case AppRouteId.sources:
        return sources;
      case AppRouteId.sourceDetail:
        return activeSourceTitle ?? sourceArticles;
      case AppRouteId.bookmarks:
        return bookmarkFilter == BookmarkFilter.savedForLater
            ? savedForLater
            : starred;
      case AppRouteId.discoverAddSource:
        return subscriptionManagement;
      case AppRouteId.settings:
        return settings;
      case AppRouteId.readerDetail:
        return selectedArticleTitle ?? readerDetail;
    }
  }

  String startupSummary(StartupHomeMode mode) {
    switch (mode) {
      case StartupHomeMode.allArticles:
      case StartupHomeMode.sources:
        return _text(
          zhCn: '鍚姩鍚庝紭鍏堣繘鍏ュ叏閮ㄦ枃绔?,
          zhHant: '鍟熷嫊寰屽劒鍏堥€插叆鍏ㄩ儴鏂囩珷',
          en: 'Open All Articles on startup',
        );
      case StartupHomeMode.bookmarks:
        return _text(
          zhCn: '鍚姩鍚庝紭鍏堣繘鍏ユ敹钘忎笌绋嶅悗璇?,
          zhHant: '鍟熷嫊寰屽劒鍏堥€插叆鏀惰棌鑸囩◢寰岃畝',
          en: 'Open Bookmarks on startup',
        );
    }
  }

  String startupLabel(StartupHomeMode mode) {
    switch (mode) {
      case StartupHomeMode.allArticles:
      case StartupHomeMode.sources:
        return allArticles;
      case StartupHomeMode.bookmarks:
        return bookmarksAndLater;
    }
  }

  String startupDesc(StartupHomeMode mode) {
    switch (mode) {
      case StartupHomeMode.allArticles:
      case StartupHomeMode.sources:
        return _text(
          zhCn: '打开后显示所有订阅文章，适合跟进最新更新。',
          zhHant: '打開後顯示所有訂閱文章，適合跟進最新更新。',
          en: 'Show all subscribed articles on launch, ideal for catching up on the latest updates.',
        );
      case StartupHomeMode.bookmarks:
        return _text(
          zhCn: '打开后显示已标记文章，适合继续阅读或回顾。',
          zhHant: '打開後顯示已標記文章，適合繼續閱讀或回顧。',
          en: 'Show marked articles on launch, ideal for continuing or revisiting reading.',
        );
    }
  }

  String mobileSidebarLabel(MobileSidebarMode mode) {
    switch (mode) {
      case MobileSidebarMode.adaptive:
        return _text(zhCn: '鑷€傚簲', zhHant: '鑷仼鎳?, en: 'Adaptive');
      case MobileSidebarMode.drawer:
        return _text(zhCn: '鎶藉眽渚ф爮', zhHant: '鎶藉睖鍋存瑒', en: 'Drawer');
      case MobileSidebarMode.rail:
        return _text(zhCn: '绐勬爮甯搁┗', zhHant: '绐勬瑒甯搁', en: 'Rail');
    }
  }

  String mobileSidebarDesc(MobileSidebarMode mode) {
    switch (mode) {
      case MobileSidebarMode.adaptive:
        return _text(
          zhCn: '灏忓睆鎶藉眽锛屽ぇ灞忕獎鏍忥紝榛樿鏇寸ǔ銆?,
          zhHant: '灏忓睆鎶藉睖锛屽ぇ灞忕獎娆勶紝闋愯ō鏇寸┅銆?,
          en: 'Use a drawer on small screens and a rail on wider screens.',
        );
      case MobileSidebarMode.drawer:
        return _text(
          zhCn: '濮嬬粓閫氳繃鎶藉眽鎵撳紑瀵艰埅銆?,
          zhHant: '濮嬬祩閫忛亷鎶藉睖鎵撻枊灏庤銆?,
          en: 'Always open navigation as a drawer.',
        );
      case MobileSidebarMode.rail:
        return _text(
          zhCn: '濮嬬粓淇濈暀绐勬爮锛屽苟鍍忔闈㈢涓€鏍蜂粠椤堕儴鎸夐挳灞曞紑鎴栨敹璧枫€?,
          zhHant: '濮嬬祩淇濈暀绐勬瑒锛屼甫鍍忔闈㈢涓€妯ｅ緸闋傞儴鎸夐垥灞曢枊鎴栨敹璧枫€?,
          en: 'Keep a slim rail visible and toggle it from the top button like desktop.',
        );
    }
  }

  String mobileWorkspaceModeLabel(MobileWorkspaceMode mode) {
    switch (mode) {
      case MobileWorkspaceMode.singlePane:
        return _text(zhCn: '鏁撮〉鏂囩珷娴?, zhHant: '鏁撮爜鏂囩珷娴?, en: 'Single Pane');
      case MobileWorkspaceMode.multiPane:
        return _text(zhCn: '澶氭爮宸ヤ綔鍖?, zhHant: '澶氭瑒宸ヤ綔鍗€', en: 'Multi Pane');
    }
  }

  String desktopWorkspaceModeLabel(DesktopWorkspaceMode mode) {
    switch (mode) {
      case DesktopWorkspaceMode.threePane:
        return _text(zhCn: '涓夋爮宸ヤ綔鍖?, zhHant: '涓夋瑒宸ヤ綔鍗€', en: 'Three Pane');
      case DesktopWorkspaceMode.focusedReader:
        return _text(
          zhCn: '鍙屾爮鍒楄〃 + 鐙珛闃呰椤?,
          zhHant: '闆欐瑒鍒楄〃 + 鐛ㄧ珛闁辫畝闋?,
          en: 'Two Pane + Reader Page',
        );
    }
  }

  String desktopContentSurfaceModeLabel(DesktopContentSurfaceMode mode) {
    switch (mode) {
      case DesktopContentSurfaceMode.flat:
        return _text(zhCn: '鎵佸钩鑳屾櫙鏉?, zhHant: '鎵佸钩鑳屾櫙鏉?, en: 'Flat Surfaces');
      case DesktopContentSurfaceMode.layered:
        return _text(zhCn: '灞傚彔鑳屾櫙鏉?, zhHant: '灞ょ枈鑳屾櫙鏉?, en: 'Layered Surfaces');
    }
  }

  String articleDensityLabel(ArticleListDensity density) {
    switch (density) {
      case ArticleListDensity.comfortable:
        return _text(zhCn: '鑸掑睍', zhHant: '鑸掑睍', en: 'Comfortable');
      case ArticleListDensity.compact:
        return _text(zhCn: '绱у噾', zhHant: '绶婃箠', en: 'Compact');
    }
  }

  String articleContentModeLabel(ArticleContentMode mode) {
    switch (mode) {
      case ArticleContentMode.rich:
        return _text(zhCn: '瀹屾暣鐗堟枃绔?, zhHant: '瀹屾暣鐗堟枃绔?, en: 'Rich Article');
      case ArticleContentMode.textOnly:
        return _text(zhCn: '绾枃鏈枃绔?, zhHant: '绱旀枃瀛楁枃绔?, en: 'Text Only');
    }
  }

  String languageModeLabel(AppLanguageMode mode) {
    switch (mode) {
      case AppLanguageMode.system:
        return _text(zhCn: '璺熼殢绯荤粺', zhHant: '璺熼毃绯荤当', en: 'Follow System');
      case AppLanguageMode.zhCn:
        return '涓枃锛堢畝浣擄級';
      case AppLanguageMode.zhHant:
        return '涓枃锛堢箒楂旓級';
      case AppLanguageMode.english:
        return 'English';
    }
  }

  String appearanceModeLabel(AppearanceMode mode) {
    switch (mode) {
      case AppearanceMode.light:
        return _text(zhCn: '娴呰壊', zhHant: '娣鸿壊', en: 'Light');
      case AppearanceMode.dark:
        return _text(zhCn: '娣辫壊', zhHant: '娣辫壊', en: 'Dark');
      case AppearanceMode.system:
        return _text(zhCn: '璺熼殢绯荤粺', zhHant: '璺熼毃绯荤当', en: 'Follow System');
    }
  }

  String themePresetName(String themeId) {
    switch (themeId) {
      case 'warm_default':
        return _text(zhCn: '鏆栫伆榛樿', zhHant: '鏆栫伆闋愯ō', en: 'Warm Default');
      case 'deep_default':
        return _text(zhCn: '娣辨榛樿', zhHant: '娣辨闋愯ō', en: 'Deep Default');
      case 'neutral_minimal':
        return _text(zhCn: '涓€ф瀬绠€', zhHant: '涓€фサ绨?, en: 'Neutral Minimal');
      case 'material_you_light':
        return _text(
            zhCn: 'Material You', zhHant: 'Material You', en: 'Material You');
      case 'wechat_green':
        return _text(zhCn: '寰俊缁?, zhHant: '寰俊缍?, en: 'WeChat Green');
      case 'ink_black_white':
        return _text(zhCn: '澧ㄦ按榛戠櫧', zhHant: '澧ㄦ按榛戠櫧', en: 'Ink Black & White');
      default:
        return _text(zhCn: '鏆栫伆榛樿', zhHant: '鏆栫伆闋愯ō', en: 'Warm Default');
    }
  }

  String get allArticles =>
      _text(zhCn: '鍏ㄩ儴鏂囩珷', zhHant: '鍏ㄩ儴鏂囩珷', en: 'All Articles');
  String get sources => _text(zhCn: '璁㈤槄婧?, zhHant: '瑷傞柋婧?, en: 'Sources');
  String get sourceArticles =>
      _text(zhCn: '鏉ユ簮鏂囩珷', zhHant: '渚嗘簮鏂囩珷', en: 'Source Articles');
  String get bookmarksAndLater => _text(
        zhCn: '鏀惰棌涓庣◢鍚庤',
        zhHant: '鏀惰棌鑸囩◢寰岃畝',
        en: 'Bookmarks & Later',
      );
  String get addSubscription => _text(
        zhCn: '娣诲姞璁㈤槄',
        zhHant: '娣诲姞瑷傞柋',
        en: 'Add Subscription',
      );
  String get subscriptionManagement => _text(
        zhCn: '璁㈤槄绠＄悊',
        zhHant: '瑷傞柋绠＄悊',
        en: 'Subscription Management',
      );
  String get subscriptionManagementIntro => _text(
        zhCn: '鍦ㄨ繖閲岄泦涓鐞嗚闃呮簮銆備綘鍙互娣诲姞銆佺紪杈戙€佸垹闄わ紝骞堕€氳繃闀挎寜鎷栧姩璋冩暣椤哄簭銆?,
        zhHant: '鍦ㄩ€欒！闆嗕腑绠＄悊瑷傞柋婧愩€備綘鍙互娣诲姞銆佺法杓€佸埅闄わ紝涓﹂€忛亷闀锋寜鎷栧嫊瑾挎暣闋嗗簭銆?,
        en: 'Manage sources here. Add, edit, remove, and long-press to reorder them.',
      );
  String get currentSubscriptionsHint => _text(
        zhCn: '闀挎寜鍙充晶鎷栧姩鏌勫彲璋冩暣椤哄簭锛岃彍鍗曢噷鍙互鍒锋柊銆佺紪杈戞垨鍒犻櫎绔欑偣銆?,
        zhHant: '闀锋寜鍙冲伌鎷栧嫊鏌勫彲瑾挎暣闋嗗簭锛岄伕鍠！鍙互閲嶆柊鏁寸悊銆佺法杓垨鍒櫎绔欓粸銆?,
        en: 'Long-press the drag handle to reorder. Use the menu to refresh, edit, or delete a source.',
      );
  String get settings => _text(zhCn: '璁剧疆', zhHant: '瑷畾', en: 'Settings');
  String get readerDetail =>
      _text(zhCn: '闃呰璇︽儏', zhHant: '闁辫畝瑭虫儏', en: 'Reader Detail');
  String get starred => _text(zhCn: '鏀惰棌', zhHant: '鏀惰棌', en: 'Starred');
  String get savedForLater =>
      _text(zhCn: '绋嶅悗璇?, zhHant: '绋嶅緦璁€', en: 'Read Later');
  String get home => _text(zhCn: '棣栭〉', zhHant: '棣栭爜', en: 'Home');
  String get unlocked => _text(zhCn: '鏈攣瀹?, zhHant: '鏈帠瀹?, en: 'Unlocked');
  String get localReader => _text(
        zhCn: '鏈湴闃呰鍣?,
        zhHant: '鏈湴闁辫畝鍣?,
        en: 'Local Reader',
      );
  String get settingsIntro => _text(
        zhCn: '鎸夊垎绫荤鐞嗗悓姝ャ€佽嚜鍔ㄦ洿鏂般€侀€氱煡銆佷富棰樺拰鏄剧ず鏂瑰紡銆?,
        zhHant: '鎸夊垎椤炵鐞嗗悓姝ャ€佽嚜鍕曟洿鏂般€侀€氱煡銆佷富椤屽拰椤ず鏂瑰紡銆?,
        en: 'Manage sync, automatic refresh, notifications, theme, and display preferences by category.',
      );
  String get settingsBack => _text(
        zhCn: '杩斿洖璁剧疆',
        zhHant: '杩斿洖瑷畾',
        en: 'Back to Settings',
      );
  String get settingsAboutApp => _text(
        zhCn: '鍏充簬鏈簲鐢?,
        zhHant: '闂滄柤鏈噳鐢?,
        en: 'About This App',
      );
  String get settingsVersionLabel => _text(
        zhCn: '鐗堟湰 ${AppBrand.version}',
        zhHant: '鐗堟湰 ${AppBrand.version}',
        en: 'Version ${AppBrand.version}',
      );
  String get settingsAboutLicense => _text(
        zhCn: 'MIT 璁稿彲璇?,
        zhHant: 'MIT 瑷卞彲璀?,
        en: 'MIT License',
      );
  String get settingsAboutRepo => _text(
        zhCn: '婧愪唬鐮佷粨搴?,
        zhHant: '鍘熷纰煎€夊韩',
        en: 'Source Repository',
      );
  String get settingsUpdateAvailable => _text(
        zhCn: '鏈夋柊鐗堟湰',
        zhHant: '鏈夋柊鐗堟湰',
        en: 'Update Available',
      );
  String get settingsCategorySyncAccount => _text(
        zhCn: '鍚屾涓庤处鍙?,
        zhHant: '鍚屾鑸囧赋铏?,
        en: 'Sync & Account',
      );
  String get settingsCategoryAi => _text(
        zhCn: 'AI',
        zhHant: 'AI',
        en: 'AI',
      );
  String get settingsCategoryAutoRefreshNotifications => _text(
        zhCn: '鑷姩鏇存柊涓庨€氱煡',
        zhHant: '鑷嫊鏇存柊鑸囬€氱煡',
        en: 'Refresh & Notifications',
      );
  String get settingsCategoryThemeDisplay => _text(
        zhCn: '涓婚涓庢樉绀?,
        zhHant: '涓婚鑸囬’绀?,
        en: 'Theme & Display',
      );
  String get settingsCategoryAbout => _text(
        zhCn: '鍏充簬',
        zhHant: '闂滄柤',
        en: 'About',
      );
  String get settingsCategoryComingSoonTitle => _text(
        zhCn: '鏆傛湭寮€鏀?,
        zhHant: '鏆湭闁嬫斁',
        en: 'Not Available Yet',
      );
  String settingsCategoryComingSoonBody(String category) => _text(
        zhCn: '$category 鍏ュ彛宸查鐣欙紝鍚庣画鐗堟湰鍐嶆帴鍏ュ叿浣撳姛鑳姐€?,
        zhHant: '$category 鍏ュ彛宸查爯鐣欙紝寰岀簩鐗堟湰鍐嶆帴鍏ュ叿楂斿姛鑳姐€?,
        en: '$category is reserved for a future version.',
      );
  String get startupPage =>
      _text(zhCn: '鍚姩椤?, zhHant: '鍟熷嫊闋?, en: 'Startup Page');
  String get visualTheme => _text(zhCn: '瑙嗚涓婚', zhHant: '瑕栬涓婚', en: 'Theme');
  String get visualThemeHint => _text(
        zhCn: '閫夋嫨涓婚棰勮锛屽苟鍐冲畾鏄惁璺熼殢绯荤粺鐨勬槑鏆楁ā寮忋€?,
        zhHant: '閬告搰涓婚闋愯ō锛屼甫姹哄畾鏄惁璺熼毃绯荤当鐨勬槑鏆楁ā寮忋€?,
        en: 'Choose a theme preset and decide whether it follows the system appearance.',
      );
  String get articleDisplayMode =>
      _text(zhCn: '鏂囩珷鏄剧ず', zhHant: '鏂囩珷椤ず', en: 'Article Display');
  String get articleDisplayModeHint => _text(
        zhCn: '瀹屾暣鐗堜繚鐣欏浘鐗囧拰濯掍綋鍗犱綅锛岀函鏂囨湰鍙樉绀烘钀戒笌鎹㈣銆?,
        zhHant: '瀹屾暣鐗堜繚鐣欏湒鐗囪垏濯掗珨浣斾綅锛岀磾鏂囧瓧鍙’绀烘钀借垏鎻涜銆?,
        en: 'Rich mode keeps images and media placeholders. Text-only mode shows paragraphs and line breaks only.',
      );
  String get subscriptionNotificationModeTitle => _text(
        zhCn: '璁㈤槄閫氱煡鏂瑰紡',
        zhHant: '瑷傞柋閫氱煡鏂瑰紡',
        en: 'Subscription Notifications',
      );
  String get subscriptionNotificationModeHint => _text(
        zhCn: '鍙拡瀵硅嚜鍔ㄦ洿鏂板甫鏉ョ殑鏂版枃绔犵敓鏁堛€傚簲鐢ㄥ湪鍓嶅彴鏃朵笉浼氬脊绯荤粺閫氱煡銆?,
        zhHant: '鍙嚌灏嶈嚜鍕曟洿鏂板付渚嗙殑鏂版枃绔犵敓鏁堛€傛噳鐢ㄥ湪鍓嶆櫙鏅備笉鏈冨綀鍑虹郴绲遍€氱煡銆?,
        en: 'Only applies to new articles found by automatic refresh. System notifications are not shown while the app is in the foreground.',
      );
  String subscriptionNotificationModeLabel(
    SubscriptionNotificationMode mode,
  ) {
    switch (mode) {
      case SubscriptionNotificationMode.sourceSummary:
        return _text(zhCn: '鎸夋簮姹囨€?, zhHant: '鎸変締婧愬綑绺?, en: 'Group by Source');
      case SubscriptionNotificationMode.perArticle:
        return _text(zhCn: '閫愮瘒閫氱煡', zhHant: '閫愮瘒閫氱煡', en: 'Per Article');
      case SubscriptionNotificationMode.minimal:
        return _text(zhCn: '浠呮彁绀烘湁鏇存柊', zhHant: '鍍呮彁绀烘湁鏇存柊', en: 'Update Only');
    }
  }

  String get mobileSidebar =>
      _text(zhCn: '绉诲姩绔晶鏍?, zhHant: '绉诲嫊绔伌娆?, en: 'Mobile Sidebar');
  String get mobileWorkspaceLayout => _text(
        zhCn: '绉诲姩绔椤典笌鏀惰棌甯冨眬',
        zhHant: '绉诲嫊绔闋佽垏鏀惰棌浣堝眬',
        en: 'Mobile Home & Bookmarks Layout',
      );
  String get mobileWorkspaceLayoutHint => _text(
        zhCn: '鍙湪鎵嬫満鍜岀獎灞忕敓鏁堛€傚彲浠ヤ繚鎸佺幇鍦ㄧ殑鍗曟爮鏂囩珷娴侊紝鎴栬€呭垏鍒版闈㈢閭ｇ澶氭爮宸ヤ綔鍖恒€?,
        zhHant: '鍙湪鎵嬫鍜岀獎铻㈠箷鐢熸晥銆傚彲浠ヤ繚鐣欑洰鍓嶇殑鍠瑒鏂囩珷娴侊紝鎴栧垏鍒版闈㈢閭ｇó澶氭瑒宸ヤ綔鍗€銆?,
        en: 'Applies only on phones and narrow screens. Keep the current single article flow or switch to the desktop-style multi-pane workspace.',
      );
  String get desktopWorkspaceLayout => _text(
        zhCn: '妗岄潰绔槄璇诲竷灞€',
        zhHant: '妗岄潰绔柋璁€浣堝眬',
        en: 'Desktop Reader Layout',
      );
  String get desktopWorkspaceLayoutHint => _text(
        zhCn: '涓夋爮妯″紡浼氭妸姝ｆ枃鍥哄畾鏀惧湪鍙充晶銆傚弻鏍忔ā寮忎細闅愯棌鍙充晶闃呰鏍忥紝鐐瑰嚮鏂囩珷鍚庤繘鍏ョ嫭绔嬮槄璇婚〉銆?,
        zhHant: '涓夋瑒妯″紡鏈冩妸姝ｆ枃鍥哄畾鏀惧湪鍙冲伌銆傞洐娆勬ā寮忔渻闅辫棌鍙冲伌闁辫畝娆勶紝榛炴搳鏂囩珷寰岄€插叆鐛ㄧ珛闁辫畝闋併€?,
        en: 'Three-pane mode keeps the reader embedded on the right. Two-pane mode hides the reader pane and opens a dedicated reader page when an article is selected.',
      );
  String get desktopContentSurface => _text(
        zhCn: '妗岄潰鍐呭灞傜骇',
        zhHant: '妗岄潰鍏у灞ょ礆',
        en: 'Desktop Content Layers',
      );
  String get desktopContentSurfaceHint => _text(
        zhCn: '鎵佸钩妯″紡浼氬幓鎺夊唴瀹瑰尯閲屼綔涓鸿儗鏅澘鐨勫ぇ妗嗭紝浣嗕繚鐣欐枃绔犮€佽闃呮簮鍜屾帶浠舵湰韬殑鍗＄墖灞傛銆?,
        zhHant: '鎵佸钩妯″紡鏈冨幓鎺夊収瀹瑰崁瑁′綔鐐鸿儗鏅澘鐨勫ぇ妗嗭紝浣嗕繚鐣欐枃绔犮€佽▊闁辨簮鍜屾帶鍒堕爡鏈韩鐨勫崱鐗囧堡娆°€?,
        en: 'Flat mode removes large background panels while keeping cards for articles, sources, and controls.',
      );
  String get searchArticlesOrSources => _text(
        zhCn: '鎼滅储鏂囩珷鎴栨簮',
        zhHant: '鎼滃皨鏂囩珷鎴栦締婧?,
        en: 'Search articles or sources',
      );
  String get globalSearchIdleHint => _text(
        zhCn: '鍦ㄥ叏閮ㄦ潵婧愬拰鏂囩珷涓悳瀵?..',
        zhHant: '鍦ㄥ叏閮ㄤ締婧愬拰鏂囩珷涓悳灏?..',
        en: 'Search across all sources and articles...',
      );
  String get globalSearchNoResults => _text(
        zhCn: '娌℃湁鎵惧埌鍖归厤鍐呭',
        zhHant: '娌掓湁鎵惧埌绗﹀悎鐨勫収瀹?,
        en: 'No matching results',
      );
  String get keyboardShortcutCtrlK => 'Ctrl+K';
  String get autoRefreshSettings => _text(
        zhCn: '鑷姩鏇存柊璁㈤槄',
        zhHant: '鑷嫊鏇存柊瑷傞柋',
        en: 'Automatic Subscription Refresh',
      );
  String get autoRefreshEnabledLabel => _text(
        zhCn: '寮€鍚嚜鍔ㄦ洿鏂拌闃?,
        zhHant: '闁嬪暉鑷嫊鏇存柊瑷傞柋',
        en: 'Enable automatic subscription refresh',
      );
  String get autoRefreshSettingsHintWindows => _text(
        zhCn: 'Windows 寮€鍚悗锛屽叧闂獥鍙ｄ細杞叆鎵樼洏甯搁┗锛屽苟鎸夎闃呮簮閰嶇疆瀹氭椂鍒锋柊銆?,
        zhHant: 'Windows 闁嬪暉寰岋紝闂滈枆瑕栫獥鏈冭綁鍏ョ郴绲卞專甯搁锛屼甫渚濊▊闁辨簮瑷畾瀹氭檪鍒锋柊銆?,
        en: 'On Windows, closing the window keeps the app in the tray and refreshes enabled sources on schedule.',
      );
  String get autoRefreshSettingsHintAndroid => _text(
        zhCn: 'Android 浼氫娇鐢ㄧ郴缁熷悗鍙颁换鍔¤嚜鍔ㄥ埛鏂帮紝涓嶆樉绀哄父椹婚€氱煡锛屽疄闄呮墽琛屾椂闂村彲鑳戒細寤跺悗銆?,
        zhHant: 'Android 鏈冧娇鐢ㄧ郴绲辫儗鏅换鍕欒嚜鍕曞埛鏂帮紝涓嶉’绀哄父椐愰€氱煡锛屽闅涘煼琛屾檪闁撳彲鑳藉欢寰屻€?,
        en: 'Android uses system-managed background work without a persistent notification. Actual execution may be delayed.',
      );
  String get autoRefreshSettingsHintLinux => _text(
        zhCn: 'Linux 浼氬湪搴旂敤杩愯鏈熼棿鎸夎闃呮簮閰嶇疆瀹氭椂鍒锋柊锛屽苟鍦ㄥ彂鐜版柊鏂囩珷鏃跺彂閫佺郴缁熼€氱煡銆?,
        zhHant: 'Linux 鏈冨湪鎳夌敤鍩疯鏈熼枔渚濊▊闁辨簮瑷畾瀹氭檪鍒锋柊锛屼甫鍦ㄧ櫦鐝炬柊鏂囩珷鏅傜櫦閫佺郴绲遍€氱煡銆?,
        en: 'On Linux, the app refreshes enabled sources while it is running and sends system notifications when new articles are found.',
      );
  String get autoRefreshSettingsHintDefault => _text(
        zhCn: '鑷姩鍒锋柊浼氭牴鎹綋鍓嶅钩鍙版敮鎸佹儏鍐佃繍琛岋紝瀹為檯鎵ц鏃舵満鍙兘鍙楃郴缁熼檺鍒躲€?,
        zhHant: '鑷嫊鍒锋柊鏈冧緷鐩墠骞冲彴鏀彺鎯呮硜鍩疯锛屽闅涘煼琛屾檪姗熷彲鑳藉彈绯荤当闄愬埗銆?,
        en: 'Automatic refresh runs when supported by the current platform. Actual timing may be limited by the system.',
      );
  String get autoRefreshDisabledNotice => _text(
        zhCn: '鑷姩鏇存柊璁㈤槄鏈紑鍚?,
        zhHant: '鑷嫊鏇存柊瑷傞柋灏氭湭闁嬪暉',
        en: 'Automatic subscription refresh is turned off',
      );
  String get autoRefreshGoToSettings => _text(
        zhCn: '鐐瑰嚮鍓嶅線璁剧疆寮€鍚?,
        zhHant: '榛炴搳鍓嶅線瑷畾闁嬪暉',
        en: 'Tap to open Settings',
      );
  String get autoRefreshConfig => _text(
        zhCn: '鑷姩鏇存柊',
        zhHant: '鑷嫊鏇存柊',
        en: 'Automatic Refresh',
      );
  String autoRefreshModeLabel(AutoRefreshMode mode) {
    switch (mode) {
      case AutoRefreshMode.allOff:
        return _text(zhCn: '鍏ㄩ儴鍏抽棴', zhHant: '鍏ㄩ儴闂滈枆', en: 'All Off');
      case AutoRefreshMode.partial:
        return _text(zhCn: '閮ㄥ垎寮€鍚?, zhHant: '閮ㄥ垎闁嬪暉', en: 'Partial');
      case AutoRefreshMode.allOn:
        return _text(zhCn: '鍏ㄩ儴寮€鍚?, zhHant: '鍏ㄩ儴闁嬪暉', en: 'All On');
    }
  }

  String get autoRefreshSourceEnabled => _text(
        zhCn: '鏇存柊杩欎釜璁㈤槄婧?,
        zhHant: '鏇存柊閫欏€嬭▊闁辨簮',
        en: 'Refresh this source automatically',
      );
  String get autoRefreshInterval => _text(
        zhCn: '鏇存柊闂撮殧',
        zhHant: '鏇存柊闁撻殧',
        en: 'Refresh interval',
      );
  String get autoRefreshSourceDisabledHint => _text(
        zhCn: '鍏抽棴鍚庝細淇濈暀褰撳墠闂撮殧锛屼絾涓嶄細杩涘叆鑷姩鏇存柊璋冨害銆?,
        zhHant: '闂滈枆寰屾渻淇濈暀鐩墠闁撻殧锛屼絾涓嶆渻閫插叆鑷嫊鏇存柊鎺掔▼銆?,
        en: 'The saved interval stays in place, but this source stops participating in automatic refresh.',
      );
  String get autoRefreshPanelHint => _text(
        zhCn: '杩欓噷鍙互缁熶竴鎺у埗鍏ㄩ儴璁㈤槄婧愮殑鑷姩鏇存柊鏂瑰紡銆?,
        zhHant: '閫欒！鍙互绲变竴鎺у埗鍏ㄩ儴瑷傞柋婧愮殑鑷嫊鏇存柊鏂瑰紡銆?,
        en: 'Control the automatic refresh mode for all subscriptions here.',
      );
  String get autoRefreshGlobalInterval => _text(
        zhCn: '鍏ㄥ眬鏇存柊闂撮殧',
        zhHant: '鍏ㄥ煙鏇存柊闁撻殧',
        en: 'Global refresh interval',
      );
  String get autoRefreshGlobalIntervalHint => _text(
        zhCn: '鍙湪鈥滃叏閮ㄥ紑鍚€濇椂鐢熸晥锛屼笉浼氭敼鍐欐瘡涓闃呮簮鍘熸湰淇濆瓨鐨勯棿闅斻€?,
        zhHant: '鍙湪銆屽叏閮ㄩ枊鍟熴€嶆檪鐢熸晥锛屼笉鏈冩敼瀵瘡鍊嬭▊闁辨簮鍘熸湰淇濆瓨鐨勯枔闅斻€?,
        en: 'Only applies in All On mode and does not overwrite per-source saved intervals.',
      );
  String get autoRefreshFollowGlobalHint => _text(
        zhCn: '褰撳墠宸插紑鍚叏閮ㄨ闃呮簮鑷姩鏇存柊锛屾洿鏂伴棿闅旇窡闅忓叏灞€璁剧疆銆?,
        zhHant: '鐩墠宸查枊鍟熷叏閮ㄨ▊闁辨簮鑷嫊鏇存柊锛屾洿鏂伴枔闅旇窡闅ㄥ叏鍩熻ō瀹氥€?,
        en: 'All subscriptions now follow the global automatic refresh interval.',
      );
  String autoRefreshGlobalSummary(int minutes) => _text(
        zhCn: '璺熼殢鍏ㄥ眬锛氭瘡 ${autoRefreshIntervalLabel(minutes)}',
        zhHant: '璺熼毃鍏ㄥ煙锛氭瘡 ${autoRefreshIntervalLabel(minutes)}',
        en: 'Follow global: every ${autoRefreshIntervalLabel(minutes)}',
      );
  String get readingDensity =>
      _text(zhCn: '闃呰瀵嗗害', zhHant: '闁辫畝瀵嗗害', en: 'Reading Density');
  String get interfaceLanguage =>
      _text(zhCn: '鐣岄潰璇█', zhHant: '浠嬮潰瑾炶█', en: 'Interface Language');
  String get interfaceLanguageHint => _text(
        zhCn: '鍒囨崲鍚庣珛鍒荤敓鏁堛€傝窡闅忕郴缁熸椂锛屼細鍦ㄧ畝浣撲腑鏂囥€佺箒浣撲腑鏂囧拰 English 涔嬮棿鑷姩鍖归厤銆?,
        zhHant: '鍒囨彌寰岀珛鍒荤敓鏁堛€傝窡闅ㄧ郴绲辨檪锛屾渻鍦ㄧ啊楂斾腑鏂囥€佺箒楂斾腑鏂囧拰 English 涔嬮枔鑷嫊鍖归厤銆?,
        en: 'Changes apply immediately. Follow System picks Simplified Chinese, Traditional Chinese, or English automatically.',
      );
  String get desktopSidebarCollapsedTitle => _text(
        zhCn: '妗岄潰绔粯璁ゆ姌鍙犱晶鏍?,
        zhHant: '妗岄潰绔爯瑷姌鐤婂伌娆?,
        en: 'Collapse Desktop Sidebar by Default',
      );
  String get desktopSidebarCollapsedHint => _text(
        zhCn: '缁欐枃绔犲垪琛ㄥ拰闃呰鍖鸿鍑烘洿澶氱┖闂淬€?,
        zhHant: '璁撴枃绔犲垪琛ㄥ拰闁辫畝鍗€鐛插緱鏇村绌洪枔銆?,
        en: 'Leave more room for the list and reader.',
      );
  String get blurEffectsTitle => _text(
        zhCn: '鐣岄潰妯＄硦鏁堟灉',
        zhHant: '浠嬮潰妯＄硦鏁堟灉',
        en: 'Interface Blur Effects',
      );
  String get blurEffectsSwitchLabel => _text(
        zhCn: '寮€鍚晫闈㈡ā绯?,
        zhHant: '闁嬪暉浠嬮潰妯＄硦',
        en: 'Enable interface blur',
      );
  String get blurEffectsHint => _text(
        zhCn: '鐢ㄤ簬闃呰椤舵爮绛夊崐閫忔槑鍖哄煙銆傚叧闂悗浼氭敼鐢ㄦ洿绋冲畾鐨勫疄鑹茶儗鏅€?,
        zhHant: '鐢ㄦ柤闁辫畝闋傛瑒绛夊崐閫忔槑鍗€鍩熴€傞棞闁夊緦鏈冩敼鐢ㄦ洿绌╁畾鐨勫鑹茶儗鏅€?,
        en: 'Used by translucent areas such as the reader toolbar. Turn it off to use steadier solid surfaces.',
      );

  String visibleArticleCount(int count) => _text(
        zhCn: '$count 绡囧彲瑙佹枃绔?,
        zhHant: '$count 绡囧彲瑕嬫枃绔?,
        en: '$count visible article${count == 1 ? '' : 's'}',
      );

  String unreadCountStat(int count) => _text(
        zhCn: '$count 鏈',
        zhHant: '$count 鏈畝',
        en: '$count unread',
      );

  String get refreshCurrentView => _text(
        zhCn: '鍒锋柊褰撳墠瑙嗗浘',
        zhHant: '閲嶆柊鏁寸悊鐩墠瑕栧湒',
        en: 'Refresh Current View',
      );
  String get noReadableSummary => _text(
        zhCn: '杩欑瘒鏂囩珷鏆傛椂娌℃湁鍙鎽樿锛屽彲浠ョ洿鎺ユ墦寮€鍘熸枃銆?,
        zhHant: '閫欑瘒鏂囩珷鏆檪娌掓湁鍙畝鎽樿锛屽彲浠ョ洿鎺ユ墦闁嬪師鏂囥€?,
        en: 'No readable summary is available yet. Open the original page instead.',
      );
  String get emptyArticleListTitle =>
      _text(zhCn: '杩欓噷杩樻病鏈夋枃绔?, zhHant: '閫欒！閭勬矑鏈夋枃绔?, en: 'No Articles Yet');
  String get emptyArticleListBody => _text(
        zhCn: '鍏堟坊鍔犺闃呮簮锛屾垨鑰呮斁瀹藉綋鍓嶇瓫閫夋潯浠躲€?,
        zhHant: '鍏堟坊鍔犺▊闁辨簮锛屾垨鏀惧鐩墠鐨勭閬告浠躲€?,
        en: 'Add a subscription first, or loosen the current filters.',
      );

  String starAction(bool value) => value
      ? _text(zhCn: '鍙栨秷鏀惰棌', zhHant: '鍙栨秷鏀惰棌', en: 'Remove Star')
      : _text(zhCn: '鏀惰棌', zhHant: '鏀惰棌', en: 'Star');

  String readLaterAction(bool value) => value
      ? _text(zhCn: '鍙栨秷绋嶅悗璇?, zhHant: '鍙栨秷绋嶅緦璁€', en: 'Remove from Later')
      : _text(zhCn: '绋嶅悗璇?, zhHant: '绋嶅緦璁€', en: 'Read Later');

  String get readLaterDoneAction =>
      _text(zhCn: '宸茶', zhHant: '宸茶畝', en: 'Done Reading');

  String readStateAction(bool isRead) => isRead
      ? _text(zhCn: '鏍囦负鏈', zhHant: '妯欑偤鏈畝', en: 'Mark Unread')
      : _text(zhCn: '鏍囦负宸茶', zhHant: '妯欑偤宸茶畝', en: 'Mark Read');

  String get openOriginal =>
      _text(zhCn: '鎵撳紑鍘熸枃', zhHant: '鎵撻枊鍘熸枃', en: 'Open Original');
  String estimatedReadingTime(int minutes) => _text(
        zhCn: '$minutes 鍒嗛挓闃呰',
        zhHant: '$minutes 鍒嗛悩闁辫畝',
        en: '$minutes min read',
      );
  String get noReadableBody => _text(
        zhCn: '杩欑瘒鏂囩珷娌℃湁鍙洿鎺ユ樉绀虹殑姝ｆ枃鎴栨憳瑕侊紝鍙互鎵撳紑鍘熸枃缁х画闃呰銆?,
        zhHant: '閫欑瘒鏂囩珷娌掓湁鍙洿鎺ラ’绀虹殑姝ｆ枃鎴栨憳瑕侊紝鍙互鎵撻枊鍘熸枃绻肩簩闁辫畝銆?,
        en: 'This article has no readable body or summary to display directly.',
      );
  String get emptyReaderTitle => _text(
        zhCn: '鐐瑰紑涓€绡囨枃绔狅紝闃呰鍖轰細鍦ㄨ繖閲屽畨闈欏睍寮€銆?,
        zhHant: '榛為枊涓€绡囨枃绔狅紝闁辫畝鍗€鏈冨湪閫欒！瀹夐潨灞曢枊銆?,
        en: 'Open any article and the reader will expand here.',
      );
  String get addSourceTitle =>
      _text(zhCn: '娣诲姞璁㈤槄婧?, zhHant: '娣诲姞瑷傞柋婧?, en: 'Add Source');
  String get feedUrlLabel => _text(
      zhCn: 'RSS / Atom 鍦板潃', zhHant: 'RSS / Atom 浣嶅潃', en: 'RSS / Atom URL');
  String get feedUrlHint => 'https://example.com/feed.xml';
  String get enterFeedAddress => _text(
        zhCn: '璇疯緭鍏ヨ闃呭湴鍧€',
        zhHant: '璜嬭几鍏ヨ▊闁变綅鍧€',
        en: 'Enter a subscription URL',
      );
  String get displayName =>
      _text(zhCn: '鏄剧ず鍚嶇О', zhHant: '椤ず鍚嶇ū', en: 'Display Name');
  String get displayNameHint => _text(
        zhCn: '鐣欑┖鏃惰嚜鍔ㄤ娇鐢ㄨ闃呮爣棰?,
        zhHant: '鐣欑┖鏅傝嚜鍕曚娇鐢ㄨ▊闁辨椤?,
        en: 'Leave empty to use the feed title automatically',
      );
  String get addNow => _text(zhCn: '绔嬪嵆娣诲姞', zhHant: '绔嬪嵆娣诲姞', en: 'Add Now');
  String get currentSubscriptions => _text(
        zhCn: '褰撳墠宸叉湁璁㈤槄',
        zhHant: '鐩墠宸叉湁瑷傞柋',
        en: 'Current Subscriptions',
      );
  String get noSubscriptionsYet => _text(
        zhCn: '杩樻病鏈夎闃呮簮锛屽厛浠庢渶甯哥湅鐨勭珯鐐瑰紑濮嬨€?,
        zhHant: '閭勬矑鏈夎▊闁辨簮锛屽厛寰炴渶甯哥湅鐨勭珯榛為枊濮嬨€?,
        en: 'There are no sources yet. Start with the sites you read most often.',
      );
  String get sourcesAndFilters => _text(
        zhCn: '鏉ユ簮涓庣瓫閫?,
        zhHant: '渚嗘簮鑸囩閬?,
        en: 'Sources & Filters',
      );
  String get bookmarksAndFilters => _text(
        zhCn: '鏀惰棌涓庣瓫閫?,
        zhHant: '鏀惰棌鑸囩閬?,
        en: 'Bookmarks & Filters',
      );
  String get sourceFilterHintTitle => _text(
        zhCn: '鍏堟寜鏉ユ簮绛涗竴灞傦紝鍐嶈繘鏂囩珷浼氭洿娓呮銆?,
        zhHant: '鍏堟寜渚嗘簮绡╀竴灞わ紝鍐嶉€叉枃绔犳渻鏇存竻妤氥€?,
        en: 'Filter by source first so the next step stays clear.',
      );
  String get sourceFilterHintBody => _text(
        zhCn: '榛樿鏄叏閮ㄦ枃绔狅紝涔熷彲浠ラ殢鏃跺垏鍒板崟涓珯鐐广€?,
        zhHant: '闋愯ō鏄叏閮ㄦ枃绔狅紝涔熷彲浠ラ毃鏅傚垏鍒板柈鍊嬬珯榛炪€?,
        en: 'The default is All Articles, but you can narrow down to one site.',
      );
  String get refreshAll =>
      _text(zhCn: '鍒锋柊鍏ㄩ儴', zhHant: '閲嶆柊鏁寸悊鍏ㄩ儴', en: 'Refresh All');
  String get unreadOnly => _text(zhCn: '浠呮湭璇?, zhHant: '鍍呮湭璁€', en: 'Unread Only');
  String get allSources =>
      _text(zhCn: '鍏ㄩ儴鏉ユ簮', zhHant: '鍏ㄩ儴渚嗘簮', en: 'All Sources');
  String get editSource =>
      _text(zhCn: '缂栬緫璁㈤槄婧?, zhHant: '绶ㄨ集瑷傞柋婧?, en: 'Edit Source');
  String get update => _text(zhCn: '鏇存柊', zhHant: '鏇存柊', en: 'Update');
  String get deleteSource =>
      _text(zhCn: '鍒犻櫎璁㈤槄婧?, zhHant: '鍒櫎瑷傞柋婧?, en: 'Delete Source');

  String deleteSourceConfirm(String title) => _text(
        zhCn: '纭鍒犻櫎 $title 鍚楋紵瀵瑰簲鏂囩珷缂撳瓨涔熶細涓€璧风Щ闄ゃ€?,
        zhHant: '纰鸿獚鍒櫎 $title 鍡庯紵灏嶆噳鏂囩珷蹇彇涔熸渻涓€璧风Щ闄ゃ€?,
        en: 'Delete $title? Its cached articles will be removed as well.',
      );

  String get refresh => _text(zhCn: '鍒锋柊', zhHant: '閲嶆柊鏁寸悊', en: 'Refresh');
  String get edit => _text(zhCn: '缂栬緫', zhHant: '绶ㄨ集', en: 'Edit');
  String get delete => _text(zhCn: '鍒犻櫎', zhHant: '鍒櫎', en: 'Delete');
  String get cancel => _text(zhCn: '鍙栨秷', zhHant: '鍙栨秷', en: 'Cancel');
  String get save => _text(zhCn: '淇濆瓨', zhHant: '鍎插瓨', en: 'Save');
  String get feedTitleAutoHint => _text(
        zhCn: '鐣欑┖鏃朵細鑷姩浣跨敤璁㈤槄鏍囬',
        zhHant: '鐣欑┖鏅傛渻鑷嫊浣跨敤瑷傞柋妯欓',
        en: 'Leave empty to use the feed title automatically',
      );
  String get feedUrlExample => _text(
        zhCn: '渚嬪 https://example.com/feed.xml',
        zhHant: '渚嬪 https://example.com/feed.xml',
        en: 'For example https://example.com/feed.xml',
      );
  String get emptySourcePanel => _text(
        zhCn: '鍏堟坊鍔犱竴涓闃呮簮锛屾枃绔犲垪琛ㄦ墠浼氬紑濮嬬敓闀裤€?,
        zhHant: '鍏堟坊鍔犱竴鍊嬭▊闁辨簮锛屾枃绔犲垪琛ㄦ墠鏈冮枊濮嬪嚭鐝俱€?,
        en: 'Add at least one source before the article list can start growing.',
      );

  String sourceStats(int count, int unread) {
    if (_language == _AppTextLanguage.en) {
      return unread > 0
          ? '$count article${count == 1 ? '' : 's'} 路 $unread unread'
          : '$count article${count == 1 ? '' : 's'}';
    }
    return unread > 0 ? '$count 绡囨枃绔?路 $unread 鏈' : '$count 绡囨枃绔?;
  }

  String autoRefreshIntervalLabel(int minutes) {
    switch (minutes) {
      case 15:
        return _text(zhCn: '15 鍒嗛挓', zhHant: '15 鍒嗛悩', en: '15 min');
      case 30:
        return _text(zhCn: '30 鍒嗛挓', zhHant: '30 鍒嗛悩', en: '30 min');
      case 60:
        return _text(zhCn: '1 灏忔椂', zhHant: '1 灏忔檪', en: '1 hour');
      case 180:
        return _text(zhCn: '3 灏忔椂', zhHant: '3 灏忔檪', en: '3 hours');
      case 360:
        return _text(zhCn: '6 灏忔椂', zhHant: '6 灏忔檪', en: '6 hours');
      case 720:
        return _text(zhCn: '12 灏忔椂', zhHant: '12 灏忔檪', en: '12 hours');
      case 1440:
        return _text(zhCn: '1 澶?, zhHant: '1 澶?, en: '1 day');
      case 4320:
        return _text(zhCn: '3 澶?, zhHant: '3 澶?, en: '3 days');
      case 10080:
        return _text(zhCn: '7 澶?, zhHant: '7 澶?, en: '7 days');
      default:
        return _language == _AppTextLanguage.en
            ? '$minutes min'
            : '$minutes 鍒嗛挓';
    }
  }

  String autoRefreshIntervalSummary(int minutes) => _text(
        zhCn: '鑷姩鏇存柊锛氭瘡 ${autoRefreshIntervalLabel(minutes)}',
        zhHant: '鑷嫊鏇存柊锛氭瘡 ${autoRefreshIntervalLabel(minutes)}',
        en: 'Auto refresh: every ${autoRefreshIntervalLabel(minutes)}',
      );

  String get trayShowWindow => _text(
        zhCn: '鏄剧ず涓荤獥鍙?,
        zhHant: '椤ず涓昏绐?,
        en: 'Show Window',
      );
  String get trayRefreshDueFeeds => _text(
        zhCn: '绔嬪嵆鍒锋柊鍒版湡璁㈤槄',
        zhHant: '绔嬪嵆鍒锋柊鍒版湡瑷傞柋',
        en: 'Refresh Due Subscriptions',
      );
  String get trayExitApp => _text(
        zhCn: '閫€鍑哄簲鐢?,
        zhHant: '閫€鍑烘噳鐢?,
        en: 'Exit App',
      );

  String initializationFailed(Object error) => _text(
        zhCn: '鍒濆鍖栨湰鍦版暟鎹け璐ワ細$error',
        zhHant: '鍒濆鍖栨湰鍦拌硣鏂欏け鏁楋細$error',
        en: 'Failed to initialize local data: $error',
      );

  String get duplicateFeedAddress => _text(
        zhCn: '杩欎釜璁㈤槄鍦板潃宸茬粡瀛樺湪',
        zhHant: '閫欏€嬭▊闁变綅鍧€宸茬稉瀛樺湪',
        en: 'This subscription URL already exists',
      );

  String get updatingFeedAddressInUse => _text(
        zhCn: '鍙︿竴涓闃呮簮宸茬粡鍦ㄤ娇鐢ㄨ繖涓湴鍧€',
        zhHant: '鍙︿竴鍊嬭▊闁辨簮宸茬稉鍦ㄤ娇鐢ㄩ€欏€嬩綅鍧€',
        en: 'Another source is already using this URL',
      );

  String get addingSubscription => _text(
        zhCn: '姝ｅ湪娣诲姞璁㈤槄婧?..',
        zhHant: '姝ｅ湪娣诲姞瑷傞柋婧?..',
        en: 'Adding source...',
      );

  String addedFeed(String title) => _text(
        zhCn: '宸叉坊鍔犺闃咃細$title',
        zhHant: '宸叉坊鍔犺▊闁憋細$title',
        en: 'Added source: $title',
      );

  String get updatingSubscription => _text(
        zhCn: '姝ｅ湪鏇存柊璁㈤槄婧?..',
        zhHant: '姝ｅ湪鏇存柊瑷傞柋婧?..',
        en: 'Updating source...',
      );

  String updatedFeed(String title) => _text(
        zhCn: '宸叉洿鏂拌闃咃細$title',
        zhHant: '宸叉洿鏂拌▊闁憋細$title',
        en: 'Updated source: $title',
      );

  String removedFeed(String title) => _text(
        zhCn: '宸插垹闄よ闃咃細$title',
        zhHant: '宸插埅闄よ▊闁憋細$title',
        en: 'Deleted source: $title',
      );

  String get noRefreshableFeeds => _text(
        zhCn: '杩樻病鏈夊彲鍒锋柊鐨勮闃呮簮',
        zhHant: '閭勬矑鏈夊彲閲嶆柊鏁寸悊鐨勮▊闁辨簮',
        en: 'There are no sources to refresh yet',
      );

  String get refreshingAllFeeds => _text(
        zhCn: '姝ｅ湪鍒锋柊鍏ㄩ儴璁㈤槄...',
        zhHant: '姝ｅ湪閲嶆柊鏁寸悊鍏ㄩ儴瑷傞柋...',
        en: 'Refreshing all sources...',
      );

  String refreshedAllFeeds(int count) => _text(
        zhCn: '鍒锋柊瀹屾垚锛屽叡澶勭悊 $count 涓闃呮簮',
        zhHant: '閲嶆柊鏁寸悊瀹屾垚锛屽叡铏曠悊 $count 鍊嬭▊闁辨簮',
        en: 'Refresh complete. Processed $count source${count == 1 ? '' : 's'}.',
      );

  String refreshingFeed(String title) => _text(
        zhCn: '姝ｅ湪鍒锋柊 $title...',
        zhHant: '姝ｅ湪閲嶆柊鏁寸悊 $title...',
        en: 'Refreshing $title...',
      );

  String refreshedFeed(String title) => _text(
        zhCn: '宸插埛鏂?$title',
        zhHant: '宸查噸鏂版暣鐞?$title',
        en: 'Refreshed $title',
      );

  String get unknownSource => _text(
        zhCn: '鏈煡鏉ユ簮',
        zhHant: '鏈煡渚嗘簮',
        en: 'Unknown Source',
      );

  String get subscriptionAddressRequired => _text(
        zhCn: '璁㈤槄鍦板潃涓嶈兘涓虹┖',
        zhHant: '瑷傞柋浣嶅潃涓嶈兘鐐虹┖',
        en: 'Subscription URL cannot be empty',
      );
  String get homeTab => _text(zhCn: '棣栭〉', zhHant: '棣栭爜', en: 'Home');
  String get bookmarksTab => _text(zhCn: '鏀惰棌', zhHant: '鏀惰棌', en: 'Bookmarks');
  String get subscriptionsTab =>
      _text(zhCn: '璁㈤槄', zhHant: '瑷傞柋', en: 'Subscriptions');
  String get settingsTab => _text(zhCn: '璁剧疆', zhHant: '瑷畾', en: 'Settings');
  String get wideMobileNavigation => _text(
        zhCn: '导航选择',
        zhHant: '導覽選擇',
        en: 'Navigation Selection',
      );
  String get wideMobileNavigationHint => _text(
        zhCn: 'Pad宽屏默认使用桌面版导航，也可以手动改成抽屉或窄栏。',
        zhHant: 'Pad 寬螢幕預設使用桌面版導覽，也可以手動改成抽屜或窄欄。',
        en: 'Wide-screen tablets use desktop-style navigation by default, and can still be changed to a drawer or rail manually.',
      );
  String get accountPageTitle => _text(
        zhCn: 'Resonance 璐﹀彿',
        zhHant: 'Resonance 甯宠櫉',
        en: 'Resonance Account',
      );
  String get accountSignedOutHint => _text(
        zhCn: '鍏堢敓鎴愪竴涓韩浠戒唬鐮侊紝鎴栬緭鍏ヤ綘宸叉湁鐨勪唬鐮併€傜幇鍦ㄥ厛鍙繚瀛樺湪鏈満锛屽悗闈細涓轰簯鏈嶅姟棰勭暀鎺ュ彛銆?,
        zhHant: '鍏堢敘鐢熶竴鍊嬭韩鍒嗕唬纰硷紝鎴栬几鍏ヤ綘宸叉湁鐨勪唬纰笺€傜従鍦ㄥ厛鍙繚瀛樺湪鏈锛屽緦闈㈡渻鐐洪洸鏈嶅嫏闋愮暀浠嬮潰銆?,
        en: 'Generate an identity code or enter one you already have. This version keeps everything local and reserves space for future cloud services.',
      );
  String get accountGenerateCode => _text(
        zhCn: '鐢熸垚鐢ㄦ埛浠ｇ爜',
        zhHant: '鐢㈢敓浣跨敤鑰呬唬纰?,
        en: 'Generate My Code',
      );
  String get accountEnterCode => _text(
        zhCn: '杈撳叆鎴戠殑浠ｇ爜',
        zhHant: '杓稿叆鎴戠殑浠ｇ⒓',
        en: 'Enter My Code',
      );
  String get accountApplyIdentityCode => _text(
        zhCn: '淇濆瓨骞跺簲鐢?,
        zhHant: '鍎插瓨涓﹀鐢?,
        en: 'Save and Apply',
      );
  String get accountIdentityCodeLabel => _text(
        zhCn: '韬唤浠ｇ爜',
        zhHant: '韬垎浠ｇ⒓',
        en: 'Identity Code',
      );
  String get accountIdentityCodeHint => _text(
        zhCn: '杈撳叆 14 浣嶅瓧姣嶆垨鏁板瓧',
        zhHant: '杓稿叆 14 浣嶅瓧姣嶆垨鏁稿瓧',
        en: 'Enter 14 letters or numbers',
      );
  String get accountIdentityCodeInvalid => _text(
        zhCn: '韬唤浠ｇ爜鏍煎紡涓嶅锛岄渶瑕佹濂?14 浣嶅瓧姣嶆垨鏁板瓧銆?,
        zhHant: '韬垎浠ｇ⒓鏍煎紡涓嶆纰猴紝闇€瑕佸墰濂?14 浣嶅瓧姣嶆垨鏁稿瓧銆?,
        en: 'The identity code must be exactly 14 letters or numbers.',
      );
  String get accountIdentityCodeCopied => _text(
        zhCn: '韬唤浠ｇ爜宸插鍒?,
        zhHant: '韬垎浠ｇ⒓宸茶瑁?,
        en: 'Identity code copied',
      );
  String get accountCopyIdentityCode => _text(
        zhCn: '澶嶅埗韬唤浠ｇ爜',
        zhHant: '瑜囪＝韬垎浠ｇ⒓',
        en: 'Copy identity code',
      );
  String get accountUnnamedUser => _text(
        zhCn: '鏈懡鍚嶇敤鎴?,
        zhHant: '鏈懡鍚嶄娇鐢ㄨ€?,
        en: 'Unnamed User',
      );
  String get accountGeneratedAndSignedIn => _text(
        zhCn: '鐢ㄦ埛浠ｇ爜宸茬敓鎴愶紝宸茬粡鍒囨崲鍒拌繖涓韩浠姐€?,
        zhHant: '浣跨敤鑰呬唬纰煎凡鐢㈢敓锛屽凡缍撳垏鎻涘埌閫欏€嬭韩鍒嗐€?,
        en: 'Your identity code is ready and this profile is now active.',
      );
  String get accountSignedIn => _text(
        zhCn: '韬唤浠ｇ爜宸插簲鐢ㄣ€?,
        zhHant: '韬垎浠ｇ⒓宸插鐢ㄣ€?,
        en: 'Identity code applied.',
      );
  String get accountSignedOut => _text(
        zhCn: '宸查€€鍑哄綋鍓嶈韩浠姐€?,
        zhHant: '宸查€€鍑虹洰鍓嶈韩鍒嗐€?,
        en: 'Signed out of the current identity.',
      );
  String get accountDisplayNameLabel => _text(
        zhCn: '鐢ㄦ埛鍚?,
        zhHant: '浣跨敤鑰呭悕绋?,
        en: 'User Name',
      );
  String get accountDisplayNameHint => _text(
        zhCn: '缁欒繖涓韩浠借捣涓€涓悕瀛?,
        zhHant: '鏇块€欏€嬭韩鍒嗗彇涓€鍊嬪悕瀛?,
        en: 'Name this identity',
      );
  String get accountEditDisplayName => _text(
        zhCn: '淇敼鐢ㄦ埛鍚?,
        zhHant: '淇敼浣跨敤鑰呭悕绋?,
        en: 'Edit User Name',
      );
  String get accountDisplayNameUpdated => _text(
        zhCn: '鐢ㄦ埛鍚嶅凡鏇存柊銆?,
        zhHant: '浣跨敤鑰呭悕绋卞凡鏇存柊銆?,
        en: 'User name updated.',
      );
  String get accountAvatarLabel => _text(
        zhCn: '澶村儚',
        zhHant: '闋儚',
        en: 'Avatar',
      );
  String get accountAvatarHint => _text(
        zhCn: '閫変竴寮犲浘鐗囷紝浼氳嚜鍔ㄤ粠涓棿瑁佹垚 1:1銆?,
        zhHant: '閬镐竴寮靛湒鐗囷紝鏈冭嚜鍕曞緸涓枔瑁佹垚 1:1銆?,
        en: 'Choose an image and it will be auto-cropped to 1:1 from the center.',
      );
  String get accountChangeAvatar => _text(
        zhCn: '鏇存崲澶村儚',
        zhHant: '鏇存彌闋儚',
        en: 'Change Avatar',
      );
  String get accountAvatarUpdated => _text(
        zhCn: '澶村儚宸叉洿鏂般€?,
        zhHant: '闋儚宸叉洿鏂般€?,
        en: 'Avatar updated.',
      );
  String get accountAvatarUnsupported => _text(
        zhCn: '杩欏紶鍥剧墖鏆傛椂娌℃硶澶勭悊锛岃鎹竴寮犲父瑙佹牸寮忕殑鍥剧墖銆?,
        zhHant: '閫欏嫉鍦栫墖鏆檪鐒℃硶铏曠悊锛岃珛鎻涗竴寮靛父瑕嬫牸寮忕殑鍦栫墖銆?,
        en: 'This image could not be processed. Please choose a common image format.',
      );
  String get accountPersonalInfoTitle => _text(
        zhCn: '涓汉淇℃伅',
        zhHant: '鍊嬩汉璩囪▕',
        en: 'Personal Info',
      );
  String get accountPersonalInfoHint => _text(
        zhCn: '杩欓噷鍙鐞嗕綘褰撳墠韬唤鐨勭敤鎴峰悕銆佸ご鍍忓拰韬唤浠ｇ爜銆?,
        zhHant: '閫欒！鍙鐞嗕綘鐩墠韬垎鐨勪娇鐢ㄨ€呭悕绋便€侀牠鍍忓拰韬垎浠ｇ⒓銆?,
        en: 'Manage the name, avatar, and identity code of the current profile here.',
      );
  String get accountCloudServiceTitle => _text(
        zhCn: '浜戞湇鍔?,
        zhHant: '闆叉湇鍕?,
        en: 'Cloud Services',
      );
  String get accountCloudServiceHint => _text(
        zhCn: '杩欎竴鍧楀厛棰勭暀缁欏悗缁悓姝ュ拰杩滅▼鑳藉姏銆?,
        zhHant: '閫欎竴濉婂厛闋愮暀绲﹀緦绾屽悓姝ュ拰閬犵鑳藉姏銆?,
        en: 'This section is reserved for future sync and remote capabilities.',
      );
  String get accountCloudServiceReserved => _text(
        zhCn: '浜戞湇鍔℃帴鍙ｆ殏鏈帴鍏ャ€傝繖涓€鐗堝彧绠＄悊鏈湴韬唤妗ｆ锛屽悗缁啀鎶婂悓姝ュ拰杩滅▼鑳藉姏鎺ヨ繘鏉ャ€?,
        zhHant: '闆叉湇鍕欎粙闈㈡毇鏈帴鍏ャ€傞€欎竴鐗堝彧绠＄悊鏈湴韬垎妾旀锛屽緦绾屽啀鎶婂悓姝ュ拰閬犵鑳藉姏鎺ラ€蹭締銆?,
        en: 'Cloud services are not connected yet. This version manages a local identity profile and leaves room for future sync.',
      );
  String get accountSignOut => _text(
        zhCn: '閫€鍑哄綋鍓嶈韩浠?,
        zhHant: '閫€鍑虹洰鍓嶈韩鍒?,
        en: 'Sign Out',
      );
  String get accountIdentityCodeGenerationFailed => _text(
        zhCn: '杩炵画鐢熸垚浜嗗娆￠兘鎾炰笂宸叉湁浠ｇ爜锛岃鍐嶈瘯涓€娆°€?,
        zhHant: '閫ｇ簩鐢㈢敓澶氭閮界涓婂凡鏈変唬纰硷紝璜嬪啀瑭︿竴娆°€?,
        en: 'Several generated codes were already in use. Please try again.',
      );
  String get accountSignedOutHintCloud => _text(
        zhCn: '鐢熸垚鐢ㄦ埛浠ｇ爜浼氱洿鎺ユ敞鍐屽埌鎶樼焊浜戙€傝緭鍏ュ凡鏈変唬鐮佹椂锛屼細鍏堝埌鎶樼焊浜戞牎楠岋紝瀛樺湪鎵嶅厑璁哥櫥褰曘€?,
        zhHant: '鐢㈢敓浣跨敤鑰呬唬纰煎緦鏈冪洿鎺ヨɑ鍐婂埌鎶樼礄闆层€傝几鍏ュ凡鏈変唬纰兼檪锛屾渻鍏堝埌鎶樼礄闆查璀夛紝瀛樺湪鎵嶅厑瑷辩櫥鍏ャ€?,
        en: 'Generating a code will register it with Origami Cloud. Entering an existing code first checks the cloud and only signs in if it exists.',
      );
  String get accountGeneratedAndSignedInCloud => _text(
        zhCn: '鐢ㄦ埛浠ｇ爜宸插垱寤哄苟娉ㄥ唽鍒版姌绾镐簯锛屽綋鍓嶈韩浠藉凡鐧诲綍銆?,
        zhHant: '浣跨敤鑰呬唬纰煎凡寤虹珛涓﹁ɑ鍐婂埌鎶樼礄闆诧紝鐩墠韬垎宸茬櫥鍏ャ€?,
        en: 'Your identity code was created, registered with Origami Cloud, and is now active.',
      );
  String get accountSignedInCloud => _text(
        zhCn: '韬唤浠ｇ爜鏍￠獙閫氳繃锛屽綋鍓嶈韩浠藉凡鐧诲綍銆?,
        zhHant: '韬垎浠ｇ⒓椹楄瓑閫氶亷锛岀洰鍓嶈韩鍒嗗凡鐧诲叆銆?,
        en: 'Identity code verified. This profile is now active.',
      );
  String get accountDisplayNameUpdatedCloud => _text(
        zhCn: '鐢ㄦ埛鍚嶅凡鏇存柊骞跺悓姝ュ埌鎶樼焊浜戙€?,
        zhHant: '浣跨敤鑰呭悕绋卞凡鏇存柊涓﹀悓姝ュ埌鎶樼礄闆层€?,
        en: 'User name updated and synced to Origami Cloud.',
      );
  String get accountCloudServiceHintOfficial => _text(
        zhCn: '杩欓噷鍙帴瀹樻柟鎶樼焊浜戙€傛墜鍔ㄤ笂浼犱細鐢ㄦ湰鍦拌鐩栦簯绔紝鎵嬪姩涓嬭浇浼氱敤浜戠瑕嗙洊鏈湴銆?,
        zhHant: '閫欒！鍙帴瀹樻柟鎶樼礄闆层€傛墜鍕曚笂鍌虫渻鐢ㄦ湰姗熻钃嬮洸绔紝鎵嬪嫊涓嬭級鏈冪敤闆茬瑕嗚搵鏈銆?,
        en: 'This section connects only to the official Origami Cloud. Upload overwrites the cloud with local data, and download overwrites local data with the cloud copy.',
      );
  String get accountCloudServiceBodyOfficial => _text(
        zhCn: '褰撳墠浼氭樉绀鸿繛鎺ョ姸鎬併€佹渶杩戝悓姝ョ粨鏋滐紝浠ュ強鎵嬪姩涓婁紶鍜屼笅杞藉叆鍙ｃ€?,
        zhHant: '鐩墠鏈冮’绀洪€ｇ窔鐙€鎱嬨€佹渶杩戝悓姝ョ祼鏋滐紝浠ュ強鎵嬪嫊涓婂偝鍜屼笅杓夊叆鍙ｃ€?,
        en: 'This section shows the connection state, the latest sync result, and manual upload/download actions.',
      );
  String get accountIdentityCodeGenerationFailedCloud => _text(
        zhCn: '杩炵画鐢熸垚浜嗗娆￠兘閬囧埌宸插瓨鍦ㄧ殑韬唤浠ｇ爜锛岃鍐嶈瘯涓€娆°€?,
        zhHant: '閫ｇ簩鐢㈢敓澶氭閮介亣鍒板凡瀛樺湪鐨勮韩鍒嗕唬纰硷紝璜嬪啀瑭︿竴娆°€?,
        en: 'Several generated codes were already registered. Please try again.',
      );
  String get accountIdentityCodeNotFound => _text(
        zhCn: '杩欎釜韬唤浠ｇ爜鍦ㄦ姌绾镐簯閲屼笉瀛樺湪锛屾殏鏃朵笉鑳界櫥褰曘€?,
        zhHant: '閫欏€嬭韩鍒嗕唬纰煎湪鎶樼礄闆茶！涓嶅瓨鍦紝鏆檪涓嶈兘鐧诲叆銆?,
        en: 'This identity code does not exist in Origami Cloud.',
      );
  String get accountCloudUnavailable => _text(
        zhCn: '褰撳墠鏋勫缓杩樻病鏈夋帴鍏ュ畼鏂规姌绾镐簯锛岃鍦ㄦ墦鍖呮椂娉ㄥ叆瀹樻柟浜戝湴鍧€銆?,
        zhHant: '鐩墠閫欏€嬪缓缃倓娌掓湁鎺ュ叆瀹樻柟鎶樼礄闆诧紝璜嬪湪鎵撳寘鏅傛敞鍏ュ畼鏂归洸浣嶅潃銆?,
        en: 'This build is not connected to the official Origami Cloud. Inject the cloud endpoint at build time.',
      );
  String get accountCloudConnectionFailed => _text(
        zhCn: '鏆傛椂杩炰笉涓婃姌绾镐簯锛岃绋嶅悗鍐嶈瘯銆?,
        zhHant: '鏆檪閫ｄ笉涓婃姌绱欓洸锛岃珛绋嶅緦鍐嶈│銆?,
        en: 'The app could not reach Origami Cloud. Please try again later.',
      );
  String get accountUserNameSyncFailed => _text(
        zhCn: '鐢ㄦ埛鍚嶅凡缁忔敼鍒版湰鍦帮紝浣嗗悓姝ュ埌鎶樼焊浜戝け璐ヤ簡銆?,
        zhHant: '浣跨敤鑰呭悕绋卞凡鏀瑰埌鏈锛屼絾鍚屾鍒版姌绱欓洸澶辨晽浜嗐€?,
        en: 'The user name was updated locally, but syncing it to Origami Cloud failed.',
      );
  String get accountCloudUploadFailed => _text(
        zhCn: '涓婁紶鍒版姌绾镐簯澶辫触浜嗭紝鏈湴鍐呭娌℃湁鍔ㄣ€?,
        zhHant: '涓婂偝鍒版姌绱欓洸澶辨晽浜嗭紝鏈鍏у娌掓湁璁婂嫊銆?,
        en: 'Uploading to Origami Cloud failed. Local data was left unchanged.',
      );
  String get accountCloudDownloadFailed => _text(
        zhCn: '浠庢姌绾镐簯涓嬭浇澶辫触浜嗭紝鏈湴鍐呭娌℃湁琚鐩栥€?,
        zhHant: '寰炴姌绱欓洸涓嬭級澶辨晽浜嗭紝鏈鍏у娌掓湁琚钃嬨€?,
        en: 'Downloading from Origami Cloud failed. Local data was not overwritten.',
      );
  String get accountCloudRegistrationCompleted => _text(
        zhCn: '韬唤浠ｇ爜宸茬粡娉ㄥ唽鍒版姌绾镐簯銆?,
        zhHant: '韬垎浠ｇ⒓宸茬稉瑷诲唺鍒版姌绱欓洸銆?,
        en: 'The identity code has been registered with Origami Cloud.',
      );
  String get accountCloudLoginLoaded => _text(
        zhCn: '宸蹭粠鎶樼焊浜戣鍙栧綋鍓嶈韩浠戒俊鎭€?,
        zhHant: '宸插緸鎶樼礄闆茶畝鍙栫洰鍓嶈韩鍒嗚硣鏂欍€?,
        en: 'Loaded the current profile from Origami Cloud.',
      );
  String get accountCloudUploadCompleted => _text(
        zhCn: '褰撳墠璁㈤槄銆佹枃绔犲拰澶村儚宸蹭笂浼犲埌鎶樼焊浜戙€?,
        zhHant: '鐩墠鐨勮▊闁便€佹枃绔犲拰闋儚宸蹭笂鍌冲埌鎶樼礄闆层€?,
        en: 'Subscriptions, articles, and avatar were uploaded to Origami Cloud.',
      );
  String get accountCloudDownloadCompleted => _text(
        zhCn: '鎶樼焊浜戦噷鐨勫唴瀹瑰凡缁忎笅杞藉埌鏈湴銆?,
        zhHant: '鎶樼礄闆茶！鐨勫収瀹瑰凡缍撲笅杓夊埌鏈銆?,
        en: 'Data from Origami Cloud was downloaded to this device.',
      );
  String get accountCloudOfficialName => _text(
        zhCn: '瀹樻柟鎶樼焊浜?,
        zhHant: '瀹樻柟鎶樼礄闆?,
        en: 'Official Origami Cloud',
      );
  String accountCloudConnected(String endpoint) => _text(
        zhCn: '褰撳墠杩炴帴锛?endpoint',
        zhHant: '鐩墠閫ｇ窔锛?endpoint',
        en: 'Connected to: $endpoint',
      );
  String get accountCloudUploadAction => _text(
        zhCn: '涓婁紶鍒版姌绾镐簯',
        zhHant: '涓婂偝鍒版姌绱欓洸',
        en: 'Upload to Origami Cloud',
      );
  String get accountCloudDownloadAction => _text(
        zhCn: '浠庢姌绾镐簯涓嬭浇',
        zhHant: '寰炴姌绱欓洸涓嬭級',
        en: 'Download from Origami Cloud',
      );
  String get accountCloudStatusIdle => _text(
        zhCn: '杩樻病鏈夋墽琛岃繃鎵嬪姩鍚屾銆?,
        zhHant: '閭勬矑鏈夊煼琛岄亷鎵嬪嫊鍚屾銆?,
        en: 'No manual cloud sync has run yet.',
      );
  String get accountCloudStatusSynced => _text(
        zhCn: '鏈€杩戜竴娆′簯鍚屾鎴愬姛銆?,
        zhHant: '鏈€杩戜竴娆￠洸绔悓姝ユ垚鍔熴€?,
        en: 'The latest cloud sync completed successfully.',
      );
  String get accountCloudStatusFailed => _text(
        zhCn: '鏈€杩戜竴娆′簯鍚屾娌℃湁鎴愬姛銆?,
        zhHant: '鏈€杩戜竴娆￠洸绔悓姝ユ矑鏈夋垚鍔熴€?,
        en: 'The latest cloud sync did not finish successfully.',
      );
  String accountCloudLastSync(String time) => _text(
        zhCn: '鏈€杩戝悓姝ワ細$time',
        zhHant: '鏈€杩戝悓姝ワ細$time',
        en: 'Last sync: $time',
      );
  String get accountGeneratedOfflinePending => _text(
        zhCn: '褰撳墠绂荤嚎锛岃韩浠戒唬鐮佸凡缁忓厛淇濆瓨鍦ㄦ湰鍦帮紝鑱旂綉鍚庝細鑷姩娉ㄥ唽鍒版姌绾镐簯銆?,
        zhHant: '鐩墠闆㈢窔锛岃韩鍒嗕唬纰煎凡鍏堜繚瀛樺湪鏈锛岄€ｇ恫寰屾渻鑷嫊瑷诲唺鍒版姌绱欓洸銆?,
        en: 'You are offline. The identity code was saved locally and will register with Origami Cloud once the app is back online.',
      );
  String get accountCloudCreatePending => _text(
        zhCn: '杩欎釜韬唤杩樻病鏈夋敞鍐屽埌鎶樼焊浜戯紝鑱旂綉鍚庝細鑷姩琛ヤ紶銆?,
        zhHant: '閫欏€嬭韩鍒嗛倓娌掓湁瑷诲唺鍒版姌绱欓洸锛岄€ｇ恫寰屾渻鑷嫊瑁滃偝銆?,
        en: 'This identity is not registered with Origami Cloud yet. It will sync automatically when the network is back.',
      );
  String get accountAvatarPendingSync => _text(
        zhCn: '澶村儚宸茬粡鏇存柊鍒版湰鍦帮紝鑱旂綉鍚庝細鑷姩鍚屾鍒版姌绾镐簯銆?,
        zhHant: '闋儚宸叉洿鏂板埌鏈锛岄€ｇ恫寰屾渻鑷嫊鍚屾鍒版姌绱欓洸銆?,
        en: 'The avatar was updated locally and will sync to Origami Cloud automatically when online.',
      );
  String get accountCloudAutoSyncCompleted => _text(
        zhCn: '妫€娴嬪埌鑱旂綉锛岃处鍙疯祫鏂欏凡缁忚嚜鍔ㄥ悓姝ュ埌鎶樼焊浜戙€?,
        zhHant: '鍋垫脯鍒伴€ｇ恫寰岋紝甯宠櫉璩囨枡宸茶嚜鍕曞悓姝ュ埌鎶樼礄闆层€?,
        en: 'The app is back online and account details were synced to Origami Cloud automatically.',
      );
  String get accountCloudAutoSyncPending => _text(
        zhCn: '璐﹀彿璧勬枡杩樻病鍚屾瀹屾垚锛屽簲鐢ㄤ細鍦ㄤ笅娆¤仈缃戝悗缁х画琛ヤ紶銆?,
        zhHant: '甯宠櫉璩囨枡閭勬矑鍚屾瀹屾垚锛屾噳鐢ㄦ渻鍦ㄤ笅娆￠€ｇ恫寰岀辜绾岃鍌炽€?,
        en: 'Account details are still waiting to sync. The app will retry automatically the next time it can reach the cloud.',
      );
}

extension AppStringsBuildContextX on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
