import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../cubit/analyzer_cubit.dart';
import '../model/analysis_data.dart';

class AnalyzerPage extends StatefulWidget {
  const AnalyzerPage({super.key});

  @override
  State<AnalyzerPage> createState() => _AnalyzerPageState();
}

class _AnalyzerPageState extends State<AnalyzerPage> {
  CameraController? _cameraController;
  bool _cameraReady = false;
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() => _cameraReady = true);
  }

  Future<void> _captureAndAnalyze(BuildContext context) async {
    if (_cameraController == null || !_cameraReady) return;

    // TalkBack announcement
    SemanticsService.announce(
        'Analyzing image, please wait', TextDirection.ltr);

    final xFile = await _cameraController!.takePicture();
    final file = File(xFile.path);

    setState(() => _capturedImage = file);

    if (mounted) {
      context.read<AnalyzerCubit>().analyzeImage(file);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AnalyzerCubit>(),
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(title: const Text('AI Image Analyzer')),
          body: BlocConsumer<AnalyzerCubit, AnalyzerState>(
            listener: (context, state) {
              if (state is AnalyzerError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                    action: SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () {
                        if (_capturedImage != null) {
                          context
                              .read<AnalyzerCubit>()
                              .analyzeImage(_capturedImage!);
                        }
                      },
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              final isProcessing = state is AnalyzerProcessing;

              return Column(
                children: [
                  Expanded(
                    child: state is AnalyzerResult
                        ? _ResultView(
                            data: state.data,
                            image: _capturedImage,
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              // Camera or captured image
                              if (_capturedImage != null)
                                Image.file(
                                  _capturedImage!,
                                  fit: BoxFit.cover,
                                )
                              else if (_cameraReady &&
                                  _cameraController != null)
                                CameraPreview(_cameraController!)
                              else
                                const Center(
                                    child: CircularProgressIndicator()),
                              // Processing overlay
                              if (isProcessing)
                                Container(
                                  color: Colors.black54,
                                  child: Center(
                                    child: Semantics(
                                      label: 'Processing',
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(
                                              color: Colors.white),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Analyzing image, please wait',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  // Bottom controls
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 24),
                    child: state is AnalyzerResult
                        ? Semantics(
                            button: true,
                            label: 'Retake photo',
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() => _capturedImage = null);
                                context.read<AnalyzerCubit>().reset();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retake Photo'),
                            ),
                          )
                        : Semantics(
                            button: true,
                            label: 'Capture image',
                            child: ElevatedButton.icon(
                              onPressed: isProcessing
                                  ? null
                                  : () => _captureAndAnalyze(context),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Capture & Analyze'),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        );
      }),
    );
  }
}

class _ResultView extends StatelessWidget {
  final AnalysisData data;
  final File? image;

  const _ResultView({required this.data, this.image});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Captured image thumbnail
          if (image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                image!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          // Description
          Text('Analysis Results',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(data.description,
              style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          // Tags
          if (data.tags.isNotEmpty) ...[
            Text('Detected Tags',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.tags
                  .map(
                    (tag) => Semantics(
                      label: 'Tag: ${tag.label}, ${tag.confidencePercentage}% confidence',
                      child: Chip(
                        label: Text(
                            '${tag.label}  ${tag.confidencePercentage}%'),
                        backgroundColor:
                            theme.colorScheme.primaryContainer,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          // Colors
          if (data.dominantColors.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Dominant Colors',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: data.dominantColors
                  .map((c) => Chip(label: Text(c)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}