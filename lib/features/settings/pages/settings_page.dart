import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vision_companion/features/settings/cubit/settings_cubit.dart';
import 'package:vision_companion/l10n/app_localizations.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/tts_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final isEnglish = state.locale.languageCode == 'en';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.languageLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        label:
                            '${l10n.english}${isEnglish ? ", ${l10n.selected}" : ""}',
                        button: true,
                        child: RadioListTile<String>(
                          title: Text(l10n.english),
                          value: 'en',
                          groupValue: state.locale.languageCode,
                          onChanged: (v) =>
                              _changeLanguage(context, v!, l10n),
                        ),
                      ),
                      Semantics(
                        label:
                            '${l10n.hindi}${!isEnglish ? ", ${l10n.selected}" : ""}',
                        button: true,
                        child: RadioListTile<String>(
                          title: Text(l10n.hindi),
                          value: 'hi',
                          groupValue: state.locale.languageCode,
                          onChanged: (v) =>
                              _changeLanguage(context, v!, l10n),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _changeLanguage(
      BuildContext context, String code, AppLocalizations l10n) {
    context.read<SettingsCubit>().setLocale(Locale(code));
    final langName = code == 'en' ? l10n.english : l10n.hindi;
    getIt<TtsService>().speak(
      l10n.selectedLanguage(langName),
      code, // Use the new code immediately
    );
  }
}