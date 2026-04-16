import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Tracks which participants have completed the experiment.
/// Written to disk after each participant completes so the experiment
/// can resume from the correct point after a crash or app restart.
class ProgressTracker {
  /// The name of the progress file written to the documents directory
  static const String _fileName = 'experiment_progress.json';

  /// Returns the full path to the progress file
  Future<String> get _filePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }

  /// Loads the set of completed participant IDs from disk.
  /// Returns an empty set if no progress file exists.
  Future<Set<String>> loadCompletedParticipants() async {
    final path = await _filePath;
    final file = File(path);

    if (!await file.exists()) return {};

    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;
    final completed = data['completed_participants'] as List<dynamic>;
    return completed.map((e) => e as String).toSet();
  }

  /// Marks a participant as completed by adding their ID to the progress file.
  /// Creates the file if it does not exist.
  Future<void> markParticipantComplete(String participantId) async {
    final completed = await loadCompletedParticipants();
    completed.add(participantId);

    final path = await _filePath;
    await File(path).writeAsString(
      jsonEncode({'completed_participants': completed.toList()}),
      flush: true,
    );
  }

  /// Returns the number of participants who have completed the experiment.
  Future<int> getCompletedCount() async {
    final completed = await loadCompletedParticipants();
    return completed.length;
  }

  /// Returns true if a specific participant has already completed the experiment.
  /// Used to skip already completed participants when resuming after a crash.
  Future<bool> isParticipantComplete(String participantId) async {
    final completed = await loadCompletedParticipants();
    return completed.contains(participantId);
  }

  /// Deletes the progress file from disk.
  /// Used when starting a fresh experiment run.
  Future<void> deleteFile() async {
    final path = await _filePath;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}