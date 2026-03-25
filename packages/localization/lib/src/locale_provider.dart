import 'package:flutter/material.dart';

/// Manages language switching without requiring an app restart.
/// It uses a ChangeNotifier so apps can wrap their MaterialApp logic in a Consumer
/// mapping the locale over natively.
class LocaleProvider extends ChangeNotifier {
  Locale _locale;

  /// Default to Malayalam for localized areas or fallback to English.
  LocaleProvider({Locale initialLocale = const Locale('ml')}) : _locale = initialLocale;

  Locale get locale => _locale;

  /// Switches the locale directly enforcing a rebuild of the Material Tree.
  void setLocale(Locale newLocale) {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
  }

  /// Helper toggling specifically between en and ml.
  void toggleLocale() {
    _locale = _locale.languageCode == 'en' ? const Locale('ml') : const Locale('en');
    notifyListeners();
  }

  /// Lists the officially supported Application Locales.
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ml'),
  ];
}
