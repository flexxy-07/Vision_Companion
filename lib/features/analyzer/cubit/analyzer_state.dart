part of 'analyzer_cubit.dart';

sealed class AnalyzerState extends Equatable {
  const AnalyzerState();
  @override
  List<Object?> get props => [];
}

final class AnalyzerIdle extends AnalyzerState {}
final class AnalyzerProcessing extends AnalyzerState {}

final class AnalyzerResult extends AnalyzerState {
  final AnalysisData data;
  const AnalyzerResult(this.data);
  @override
  List<Object?> get props => [data];
}

final class AnalyzerError extends AnalyzerState {
  final String message;
  const AnalyzerError(this.message);
  @override
  List<Object?> get props => [message];
}