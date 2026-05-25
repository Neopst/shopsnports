import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageState {
  final String code;
  final String name;

  const LanguageState({this.code = 'EN', this.name = 'English'});

  LanguageState copyWith({String? code, String? name}) => LanguageState(
        code: code ?? this.code,
        name: name ?? this.name,
      );
}

class LanguageNotifier extends StateNotifier<LanguageState> {
  LanguageNotifier() : super(const LanguageState());

  static const _prefsKey = 'selected_language';

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && saved.isNotEmpty) {
        state = state.copyWith(code: saved, name: _getLanguageName(saved));
      }
    } catch (_) {
      // ignore and keep defaults
    }
  }

  Future<void> setLanguage(String code) async {
    try {
      state = state.copyWith(code: code, name: _getLanguageName(code));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, code);
    } catch (_) {
      // fallback: update only code
      state = state.copyWith(code: code, name: _getLanguageName(code));
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'EN':
        return 'English';
      case 'ES':
        return 'Español';
      case 'FR':
        return 'Français';
      case 'AR':
        return 'العربية';
      case 'HI':
        return 'हिन्दी';
      case 'PT':
        return 'Português';
      default:
        return 'English';
    }
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>(
    (ref) => LanguageNotifier());
