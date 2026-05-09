import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../repository/history_repository.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detection History')),
      body: StreamBuilder<List<HistoryEntry>>(
        stream: getIt<HistoryRepository>().watchHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No history yet. Start using features!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final e = entries[i];
              final isDetector = e.featureType == 'object_detection';
              final formatted = e.timestamp != null
                  ? DateFormat.yMMMd().add_jm().format(e.timestamp!)
                  : '';
              return Semantics(
                label:
                    '${isDetector ? 'Object detection' : 'Image analysis'}: ${e.resultSummary}. $formatted',
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      isDetector ? Icons.camera_alt : Icons.auto_awesome,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    e.resultSummary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(formatted),
                  trailing: Chip(
                    label: Text(
                      isDetector ? 'Detector' : 'Analyzer',
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
