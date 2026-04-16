/// Represents a single participant response to a stimulus.
/// One response is recorded for each of the 5 stimuli presented per session,
/// yielding 15 total responses per participant across 3 sessions.
/// Response objects are collected during the experiment and written to CSV on export.
class Response {
  /// Unique identifier for this participant
  final String participantId;

  /// Which session this response was recorded in (1, 2, or 3)
  final int sessionNumber;

  /// The ID of the stimulus this response is for (e.g. "S01")
  final String stimulusId;

  /// Whether the stimulus was a phishing attempt or legitimate message
  /// true = phishing, false = legitimate
  final bool messageType;

  /// Delivery mode condition assigned to this participant
  /// Values: interruptive, passive
  final String deliveryMode;

  /// Language specificity condition assigned to this participant
  /// Values: generic, contextual
  final String languageSpecificity;

  /// Visual presentation condition assigned to this participant
  /// Values: static, polymorphic
  final String visualPresentation;

  /// The participant's binary detection decision
  /// true = identified as phishing, false = identified as legitimate
  final bool detectionDecision;

  /// The participant's confidence in their detection decision (1-5)
  /// 1 = not confident at all, 5 = very confident
  final int confidenceRating;

  /// Timestamp when this response was recorded
  final DateTime timestamp;

  const Response({
    required this.participantId,
    required this.sessionNumber,
    required this.stimulusId,
    required this.messageType,
    required this.deliveryMode,
    required this.languageSpecificity,
    required this.visualPresentation,
    required this.detectionDecision,
    required this.confidenceRating,
    required this.timestamp,
  });

  /// Converts the response to a list of values for CSV export.
  /// The order matches the CSV header row defined in csv_exporter.dart.
  List<dynamic> toCsvRow() {
    return [
      participantId,
      sessionNumber,
      stimulusId,
      messageType ? 'phishing' : 'legitimate',
      deliveryMode,
      languageSpecificity,
      visualPresentation,
      detectionDecision ? 'phishing' : 'legitimate',
      confidenceRating,
      timestamp.toIso8601String(),
    ];
  }

  @override
  String toString() {
    return 'Response(participant: $participantId, session: $sessionNumber, '
        'stimulus: $stimulusId, decision: $detectionDecision, '
        'confidence: $confidenceRating)';
  }
}