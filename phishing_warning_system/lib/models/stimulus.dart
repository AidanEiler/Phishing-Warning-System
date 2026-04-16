/// Represents a single conversation snippet presented to a participant.
/// Each stimulus consists of a short conversation thread (3-5 messages)
/// culminating in either a phishing attempt or a legitimate message.
/// Stimuli are pre-written, manually reviewed, and loaded from stimuli.json.
class Stimulus {
  /// Unique identifier for this stimulus (e.g. "S01", "S02")
  final String id;

  /// Which session this stimulus belongs to (1, 2, or 3)
  /// Session 1: stimuli 1-5, Session 2: stimuli 6-10, Session 3: stimuli 11-15
  final int sessionNumber;

  /// Whether the final message in the conversation is a phishing attempt
  /// true = phishing, false = legitimate
  final bool isPhishing;

  /// The conversation thread leading up to the final message
  /// Each entry is a map with 'sender' and 'content' keys
  final List<Map<String, String>> conversationMessages;

  /// The final message in the conversation that the participant evaluates
  /// This is the message that may or may not be a phishing attempt
  final String finalMessage;

  /// The sender of the final message
  final String finalMessageSender;

  /// The suspicious link contained in the final message, if any
  /// null for legitimate messages
  final String? suspiciousLink;

  /// A brief description of the phishing tactic used, for researcher reference
  /// null for legitimate messages
  final String? phishingTactic;

  const Stimulus({
    required this.id,
    required this.sessionNumber,
    required this.isPhishing,
    required this.conversationMessages,
    required this.finalMessage,
    required this.finalMessageSender,
    this.suspiciousLink,
    this.phishingTactic,
  });

  /// Creates a Stimulus from a JSON map loaded from stimuli.json
  factory Stimulus.fromJson(Map<String, dynamic> json) {
    return Stimulus(
      id: json['id'] as String,
      sessionNumber: json['session_number'] as int,
      isPhishing: json['is_phishing'] as bool,
      conversationMessages: (json['conversation_messages'] as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList(),
      finalMessage: json['final_message'] as String,
      finalMessageSender: json['final_message_sender'] as String,
      suspiciousLink: json['suspicious_link'] as String?,
      phishingTactic: json['phishing_tactic'] as String?,
    );
  }

  /// Converts the stimulus to a map for use in API prompts
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_number': sessionNumber,
      'is_phishing': isPhishing,
      'conversation_messages': conversationMessages,
      'final_message': finalMessage,
      'final_message_sender': finalMessageSender,
      'suspicious_link': suspiciousLink,
      'phishing_tactic': phishingTactic,
    };
  }

  @override
  String toString() {
    return 'Stimulus(id: $id, session: $sessionNumber, '
        'isPhishing: $isPhishing, sender: $finalMessageSender)';
  }
}