import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SharedPreferences _prefs;
  static const _key = 'selected_locale';

  SettingsCubit(this._prefs) : super(const SettingsState(locale: Locale('en')));

  void loadSettings() {
    final code = _prefs.getString(_key) ?? 'en';
    emit(SettingsState(locale: Locale(code)));
  }
  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_key, locale.languageCode);
    emit(SettingsState(locale: locale));
  }
  
} 