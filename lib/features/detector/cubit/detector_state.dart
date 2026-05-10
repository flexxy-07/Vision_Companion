part of 'detector_cubit.dart';

class DetectorState extends Equatable {
  final List<Detection> detections;
  final bool isPaused;
  final bool isLoading;
  final String? error;

  const DetectorState({
    this.detections = const [],
    this.isPaused = false,
    this.isLoading = false,
    this.error,
  });

  DetectorState copyWith({
    List<Detection>? detections,
    bool? isPaused,
    bool? isLoading,
    String? error,
  }) {
    return DetectorState(
      detections: detections ?? this.detections,
      isPaused: isPaused ?? this.isPaused,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [detections, isPaused, isLoading, error];
}
