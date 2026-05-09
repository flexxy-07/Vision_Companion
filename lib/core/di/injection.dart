import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_companion/features/analyzer/cubit/analyzer_cubit.dart';
import 'package:vision_companion/features/analyzer/repository/analyzer_repository.dart';
import 'package:vision_companion/features/detector/cubit/detector_cubit.dart';
import 'package:vision_companion/features/history/repository/history_repository.dart';
import 'package:vision_companion/features/settings/cubit/settings_cubit.dart';

import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/repository/auth_repository.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());
  getIt.registerLazySingleton<HistoryRepository>(() => HistoryRepository());
  getIt.registerLazySingleton<AnalyzerRepository>(() => AnalyzerRepository());



  getIt.registerFactory<SettingsCubit>(
    () => SettingsCubit(getIt<SharedPreferences>())
  );
  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<DetectorCubit>(
    () => DetectorCubit(getIt<HistoryRepository>()),
  );
  getIt.registerFactory<AnalyzerCubit>(
    () =>
        AnalyzerCubit(getIt<AnalyzerRepository>(), getIt<HistoryRepository>()),
  );
}
