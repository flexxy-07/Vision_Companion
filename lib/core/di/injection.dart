import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:vision_companion/features/analyzer/cubit/analyzer_cubit.dart';
import 'package:vision_companion/features/analyzer/repository/analyzer_repository.dart';
import 'package:vision_companion/features/detector/cubit/detector_cubit.dart';
import 'package:vision_companion/features/history/repository/history_repository.dart';

import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/repository/auth_repository.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());
  getIt.registerLazySingleton<HistoryRepository>(() => HistoryRepository());
  getIt.registerLazySingleton<AnalyzerRepository>(() => AnalyzerRepository());

  getIt.registerLazySingleton<AuthCubit>(() => AuthCubit(getIt<AuthRepository>()));
  getIt.registerLazySingleton<DetectorCubit>(
    () => DetectorCubit(getIt<HistoryRepository>())
  );
  getIt.registerFactory<AnalyzerCubit>(
    () => AnalyzerCubit(getIt<AnalyzerRepository>(), getIt<HistoryRepository>())
  );
}
