part of 'detector_cubit.dart';

sealed class DetectorState extends Equatable {
  const DetectorState();
  @override
  List<Object?> get props => [];
}

final class DetectorIdle extends DetectorState {}

final class DetectorRunning extends DetectorState {}

final class DetectorPaused extends DetectorState {}

final class DetectorResults extends DetectorState {
  final List<Detection> detections;
  const DetectorResults(this.detections);
  @override
  List<Object?> get props => [detections];
}

final class DetectorError extends DetectorState {
  final String message;
  const DetectorError(this.message);
  @override
  List<Object?> get props => [message];
}
