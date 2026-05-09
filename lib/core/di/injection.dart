import 'package:get_it/get_it.dart';
import 'package:vision_companion/features/detector/cubit/detector_cubit.dart';
import 'package:vision_companion/features/history/repository/history_repository.dart';

import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/repository/auth_repository.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());
  getIt.registerLazySingleton<HistoryRepository>(() => HistoryRepository());

  getIt.registerLazySingleton<AuthCubit>(() => AuthCubit(getIt<AuthRepository>()));
  getIt.registerLazySingleton<DetectorCubit>(
    () => DetectorCubit(getIt<HistoryRepository>())
  );
}
