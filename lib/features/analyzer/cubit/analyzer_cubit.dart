import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:vision_companion/features/analyzer/model/analysis_data.dart';
import 'package:vision_companion/features/analyzer/repository/analyzer_repository.dart';
import 'package:vision_companion/features/history/repository/history_repository.dart';
part 'analyzer_state.dart';

class AnalyzerCubit extends Cubit<AnalyzerState>{
  final AnalyzerRepository _repo;
  final HistoryRepository _historyRepo;

  AnalyzerCubit(this._repo, this._historyRepo) : super(AnalyzerIdle());

  Future<void> analyzeImage(File imageFile, String language) async {
    emit(AnalyzerProcessing());
    try {
      final result = await _repo.analyzeImage(imageFile, language);
      await _historyRepo.saveHistory(featureType: 'image_analysis', resultSummary: result.summarForHistory);
      emit(AnalyzerResult(result));
    }on SocketException {
      emit(const AnalyzerError('Network error. Check your connection.'));
    } catch (e) {
      emit(AnalyzerError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void reset() => emit(AnalyzerIdle());
}