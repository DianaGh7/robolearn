import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageNotifier extends ChangeNotifier {
  static final LanguageNotifier instance = LanguageNotifier._();
  LanguageNotifier._();

  static const _prefKey = 'app_language';

  bool _isArabic = false;
  bool get isArabic => _isArabic;
  Locale get locale => _isArabic ? const Locale('ar') : const Locale('en');

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isArabic = (prefs.getString(_prefKey) ?? 'en') == 'ar';
  }

  Future<void> setLanguage(bool arabic) async {
    if (_isArabic == arabic) return;
    _isArabic = arabic;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, arabic ? 'ar' : 'en');
  }
}

class LangScope extends InheritedNotifier<LanguageNotifier> {
  const LangScope({
    super.key,
    required LanguageNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static LanguageNotifier of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LangScope>()!.notifier!;
}
