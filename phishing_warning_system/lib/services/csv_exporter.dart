import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../models/response.dart';

/// Handles writing experiment response data to CSV format.
/// Writes incrementally after each participant completes to ensure
/// data is not lost in the event of a crash or unexpected app closure.
class CsvExporter {
  /// The name of the CSV file written to the documents directory
  static const String _fileName = 'experiment_responses.csv';

  /// Returns the full path to the CSV file in the app documents directory
  Future<String> get _filePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }

  /// Returns the CSV header row.
  /// Order must match the toCsvRow() method in response.dart.
  List<String> get _headerRow => [
        'participant_id',
        'session_number',
        'stimulus_id',
        'message_type',
        'delivery_mode',
        'language_specificity',
        'visual_presentation',
        'detection_decision',
        'confidence_rating',
        'timestamp',
      ];

  /// Checks whether the CSV file already exists on disk.
  /// Used to determine whether to write the header row.
  Future<bool> get _fileExists async {
    final path = await _filePath;
    return File(path).exists();
  }

  /// Appends a list of responses for a single participant to the CSV file.
  /// Creates the file and writes the header row if it does not already exist.
  /// Called after each participant completes to ensure incremental persistence.
  Future<void> appendResponses(List<Response> responses) async {
    final path = await _filePath;
    final file = File(path);
    final exists = await _fileExists;

    final List<List<dynamic>> rows = [];

    /// Write header row only if file is being created for the first time
    if (!exists) {
      rows.add(_headerRow);
    }

    /// Add a row for each response
    for (final response in responses) {
      rows.add(response.toCsvRow());
    }

    /// Convert to CSV string and append to file
    final csvString = const ListToCsvConverter().convert(rows);
    await file.writeAsString(
      '$csvString\n',
      mode: exists ? FileMode.append : FileMode.write,
      flush: true,
    );
  }

  /// Returns the full path to the CSV file for display in the export screen.
  Future<String> getExportPath() async {
    return await _filePath;
  }

  /// Returns the number of response rows already written to the CSV file.
  /// Used on startup to show how much data has already been collected.
  /// Returns 0 if the file does not exist.
  Future<int> getResponseCount() async {
    final exists = await _fileExists;
    if (!exists) return 0;

    final path = await _filePath;
    final content = await File(path).readAsString();
    final rows = const CsvToListConverter().convert(content);

    /// Subtract 1 for the header row
    return rows.length > 1 ? rows.length - 1 : 0;
  }

  /// Deletes the CSV file from disk.
  /// Used when starting a fresh experiment run.
  Future<void> deleteFile() async {
    final exists = await _fileExists;
    if (exists) {
      final path = await _filePath;
      await File(path).delete();
    }
  }
}