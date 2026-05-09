

part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final Locale locale;
  const SettingsState({required this.locale});

  @override
  List<Object?> get props => [locale];
}