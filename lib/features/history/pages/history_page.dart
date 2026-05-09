import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vision_companion/l10n/app_localizations.dart';

import '../../../core/di/injection.dart';
import '../repository/history_repository.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: StreamBuilder<List<HistoryEntry>>(
        stream: getIt<HistoryRepository>().watchHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noHistory,
                    style: const TextStyle(color: Colors.grey),
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
                    '${isDetector ? l10n.objectDetection : l10n.imageAnalysis}: ${e.resultSummary}. $formatted',
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
                      isDetector ? l10n.detector : l10n.analyzer,
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
