import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/persona.dart';
import '../models/stimulus.dart';
import '../models/response.dart';
import '../models/condition.dart';

/// Service responsible for all AI API calls to Google Gemini.
/// Handles persona generation, stimulus responses, warning text generation,
/// memory summarization, and batch experiment orchestration.
/// Includes rate limit handling with automatic retry and backoff logic.
class AiService {
  /// Gemini API endpoint for the flash model
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Maximum number of retries before giving up on a request
  static const int _maxRetries = 3;

  /// Base delay in milliseconds for exponential backoff
  static const int _baseDelayMs = 2000;

  /// Minimum delay between requests to respect rate limits
  /// Gemini free tier allows 5 requests per minute = 1 request per 12 seconds
  static const int _requestDelayMs = 12000;

  /// Timestamp of the last API request, used to enforce rate limiting
  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// The Gemini API key loaded from .env
  final String _apiKey;

  AiService(this._apiKey);

  /// Enforces a minimum delay between API requests to avoid hitting
  /// the 5 requests per minute rate limit on the Gemini free tier.
  Future<void> _respectRateLimit() async {
    final now = DateTime.now();
    final timeSinceLastRequest =
        now.difference(_lastRequestTime).inMilliseconds;
    if (timeSinceLastRequest < _requestDelayMs) {
      final waitTime = _requestDelayMs - timeSinceLastRequest;
      await Future.delayed(Duration(milliseconds: waitTime));
    }
    _lastRequestTime = DateTime.now();
  }

  /// Core method for sending a prompt to the Gemini API.
  /// Handles rate limiting, retries, and exponential backoff automatically.
  /// Throws an exception if all retries are exhausted.
  Future<String> _sendPrompt(String prompt) async {
    int attempt = 0;

    while (attempt < _maxRetries) {
      try {
        await _respectRateLimit();

        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'maxOutputTokens': 300,
              'temperature': 0.7,
            },
          }),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () =>
              throw Exception('Request timed out after 30 seconds'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['candidates'][0]['content']['parts'][0]['text'] as String;
        } else if (response.statusCode == 429) {
          /// Rate limit hit — wait with exponential backoff before retrying
          final waitTime = _baseDelayMs * (attempt + 1) * 2;
          await Future.delayed(Duration(milliseconds: waitTime));
          attempt++;
        } else {
          throw Exception(
              'Gemini API error: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        if (attempt >= _maxRetries - 1) {
          throw Exception('Attempt $attempt failed with: ${e.runtimeType}: $e');
        }
        final waitTime = _baseDelayMs * (attempt + 1);
        await Future.delayed(Duration(milliseconds: waitTime));
        attempt++;
      }
    }

    throw Exception('Max retries exceeded for Gemini API request');
  }

  /// Generates a randomized persona profile for a simulated participant.
  /// The AI generates realistic demographic and behavioral characteristics
  /// within the defined parameter ranges.
  Future<Map<String, dynamic>> generatePersona(String participantId) async {
    final prompt = '''
Generate a randomized participant profile for a phishing susceptibility experiment.
Return ONLY a valid JSON object with exactly these fields, no other text:
{
  "age": <integer between 18 and 65>,
  "sex": <"male", "female", or "non-binary">,
  "cybersecurity_training": <"none", "minimal", "moderate", or "extensive">,
  "daily_messaging_usage": <integer representing hours per day>,
  "stress_level": <"low", "moderate", or "high">
}
Make the profile realistic and varied. Do not include any explanation or markdown.
''';

    final responseText = await _sendPrompt(prompt);
    final cleanedResponse = responseText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    return jsonDecode(cleanedResponse) as Map<String, dynamic>;
  }

  /// Simulates a participant's response to a phishing stimulus.
  /// The AI adopts the persona's characteristics and responds as a human
  /// participant would, including neurobiological susceptibility simulation.
  /// Returns a map with 'detection_decision' (bool) and 'confidence_rating' (int).
  Future<Map<String, dynamic>> simulateParticipantResponse({
    required Map<String, dynamic> persona,
    required String conversationContext,
    required String finalMessage,
    required String warningText,
    required String deliveryMode,
    required int sessionNumber,
    required String memoryContext,
  }) async {
    final prompt = '''
You are simulating a human participant in a phishing detection experiment.
Adopt this persona completely, including realistic neurobiological responses:

PERSONA:
- Age: ${persona['age']}
- Sex: ${persona['sex']}
- Cybersecurity training: ${persona['cybersecurity_training']}
- Daily messaging app usage: ${persona['daily_messaging_usage']} hours
- Current stress level: ${persona['stress_level']}

${memoryContext.isNotEmpty ? 'MEMORY FROM PREVIOUS SESSIONS:\n$memoryContext\n' : ''}

CONVERSATION CONTEXT:
$conversationContext

FINAL MESSAGE TO EVALUATE:
$finalMessage

WARNING DISPLAYED ($deliveryMode delivery, session $sessionNumber):
$warningText

Based on this persona characteristics, cognitive state, and the warning shown,
simulate how this person would respond. Consider:
- Their stress level affects heuristic processing
- Their cybersecurity training affects suspicion levels
- Their messaging usage affects notification fatigue
- The session number affects habituation to warnings

Return ONLY a valid JSON object with exactly these fields, no other text:
{
  "detection_decision": <true if they identify it as phishing, false if they think it is legitimate>,
  "confidence_rating": <integer from 1 to 5, where 1 is not confident and 5 is very confident>
}
Do not include any explanation or markdown.
''';

    final responseText = await _sendPrompt(prompt);
    final cleanedResponse = responseText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    return jsonDecode(cleanedResponse) as Map<String, dynamic>;
  }

  /// Generates a contextually specific warning for a phishing message.
  /// Used in contextual language specificity conditions and prototype mode.
  /// The warning is tailored to the specific message content and conversation context.
  Future<String> generateContextualWarning({
    required String conversationContext,
    required String suspiciousMessage,
    required String suspiciousLink,
  }) async {
    final prompt = '''
You are a phishing warning system for a messaging application.
A user is about to click a suspicious link in the following conversation.

CONVERSATION:
$conversationContext

SUSPICIOUS MESSAGE:
$suspiciousMessage

LINK:
$suspiciousLink

Generate a brief, clear warning (2-3 sentences maximum) that:
1. Explains specifically why this message is suspicious based on its context
2. Identifies the specific risk the user faces
3. Is written in plain language without technical jargon

Provide only the warning text, no preamble or labels.
''';

    return await _sendPrompt(prompt);
  }

  /// Generates a degraded memory summary after a session.
  /// Simulates partial forgetting between sessions by retaining general
  /// awareness of warning types while losing specific visual and linguistic details.
  /// This summary is injected into the next session context.
  Future<String> generateMemorySummary({
    required String sessionTranscript,
    required int sessionNumber,
    required String? previousMemory,
  }) async {
    final prompt = '''
You are simulating human memory decay between sessions in an experiment.
${previousMemory != null ? 'Previous memory summary:\n$previousMemory\n' : ''}

Session $sessionNumber transcript summary:
$sessionTranscript

Generate a degraded memory summary that:
1. Retains general awareness that security warnings were encountered
2. Loses specific visual details about warning appearance
3. Loses specific warning text and phrasing
4. Retains a vague sense of whether warnings felt relevant or generic
5. Becomes progressively vaguer with each session

Keep the summary to 2-3 sentences maximum.
Provide only the memory summary text, no preamble.
''';

    return await _sendPrompt(prompt);
  }

  /// Returns a generic warning text for the generic language specificity condition.
  /// This is a fixed string that does not change between stimuli or sessions,
  /// consistent with the generic condition definition.
  String getGenericWarning() {
    return 'This message may be a phishing attempt. '
        'Exercise caution before clicking any links or providing personal information.';
  }

  /// Runs the full batch experiment for a single participant across all three sessions.
  /// Handles persona generation, stimulus presentation, response collection,
  /// and memory summarization between sessions.
  /// Returns a list of Response objects for CSV export.
  /// The onProgress callback reports progress as a value between 0.0 and 1.0.
  Future<List<Response>> runParticipantExperiment({
    required String participantId,
    required Condition condition,
    required List<Stimulus> allStimuli,
    required void Function(double progress, String status) onProgress,
  }) async {
    final List<Response> responses = [];
    String memoryContext = '';

    /// Generate persona for this participant
    onProgress(0.0, 'Generating persona for $participantId...');
    final personaMap = await generatePersona(participantId);
    final persona = Persona(
      id: participantId,
      age: personaMap['age'] as int,
      sex: personaMap['sex'] as String,
      cybersecurityTraining: personaMap['cybersecurity_training'] as String,
      dailyMessagingUsage: personaMap['daily_messaging_usage'] as int,
      stressLevel: personaMap['stress_level'] as String,
    );

    /// Run three sessions
    for (int session = 1; session <= 3; session++) {
      /// Get stimuli for this session (5 per session, grouped by session number)
      final sessionStimuli = allStimuli
          .where((s) => s.sessionNumber == session)
          .toList()
        ..shuffle();

      /// Present each stimulus and collect response
      for (int i = 0; i < sessionStimuli.length; i++) {
        final stimulus = sessionStimuli[i];
        final totalSteps = 15.0;
        final currentStep = ((session - 1) * 5 + i + 1).toDouble();
        onProgress(
          currentStep / totalSteps,
          'Session $session, stimulus ${i + 1}/5 for $participantId...',
        );

        /// Build conversation context string from messages
        final conversationContext = stimulus.conversationMessages
            .map((m) => '${m['sender']}: ${m['content']}')
            .join('\n');

        /// Determine warning text based on condition
        String warningText = '';
        if (!condition.isControl) {
          if (stimulus.isPhishing) {
            if (condition.languageSpecificity == 'contextual') {
              warningText = await generateContextualWarning(
                conversationContext: conversationContext,
                suspiciousMessage: stimulus.finalMessage,
                suspiciousLink: stimulus.suspiciousLink ?? '',
              );
            } else {
              warningText = getGenericWarning();
            }
          }
        }

        /// Simulate participant response
        final responseMap = await simulateParticipantResponse(
          persona: personaMap,
          conversationContext: conversationContext,
          finalMessage: stimulus.finalMessage,
          warningText: warningText,
          deliveryMode: condition.deliveryMode,
          sessionNumber: session,
          memoryContext: memoryContext,
        );

        responses.add(Response(
          participantId: participantId,
          sessionNumber: session,
          stimulusId: stimulus.id,
          messageType: stimulus.isPhishing,
          deliveryMode: condition.deliveryMode,
          languageSpecificity: condition.languageSpecificity,
          visualPresentation: condition.visualPresentation,
          detectionDecision: responseMap['detection_decision'] as bool,
          confidenceRating: responseMap['confidence_rating'] as int,
          timestamp: DateTime.now(),
        ));
      }

      /// Generate degraded memory summary after sessions 1 and 2
      if (session < 3) {
        onProgress(
          (session * 5) / 15.0,
          'Generating memory summary after session $session...',
        );
        final sessionTranscript = responses
            .where((r) => r.sessionNumber == session)
            .map((r) =>
                'Stimulus ${r.stimulusId}: decided ${r.detectionDecision ? "phishing" : "legitimate"} with confidence ${r.confidenceRating}')
            .join('\n');

        memoryContext = await generateMemorySummary(
          sessionTranscript: sessionTranscript,
          sessionNumber: session,
          previousMemory: memoryContext.isNotEmpty ? memoryContext : null,
        );
      }
    }

    onProgress(1.0, 'Participant $participantId complete.');
    return responses;
  }

  /// Runs the full batch experiment for all 270 participants across all 9 conditions.
  /// 30 participants per condition, 3 sessions each, 5 stimuli per session.
  /// Results are aggregated and returned as a flat list of Response objects.
  /// The onProgress callback reports overall progress and current status.
  Future<List<Response>> runFullExperiment({
    required List<Stimulus> allStimuli,
    required void Function(double progress, String status) onProgress,
  }) async {
    final List<Response> allResponses = [];
    const int participantsPerCondition = 30;
    const int totalParticipants = 270;
    int completedParticipants = 0;

    for (final condition in Condition.allConditions) {
      for (int p = 1; p <= participantsPerCondition; p++) {
        final participantId =
            'C${condition.conditionNumber.toString().padLeft(2, '0')}-P${p.toString().padLeft(2, '0')}';

        onProgress(
          completedParticipants / totalParticipants,
          'Running condition ${condition.conditionNumber}/9, '
          'participant $p/$participantsPerCondition ($participantId)...',
        );

        try {
          final participantResponses = await runParticipantExperiment(
            participantId: participantId,
            condition: condition,
            allStimuli: allStimuli,
            onProgress: (_, status) => onProgress(
              completedParticipants / totalParticipants,
              status,
            ),
          );
          allResponses.addAll(participantResponses);
        } catch (e) {
          /// Log failed participant but continue with experiment
          onProgress(
            completedParticipants / totalParticipants,
            'WARNING: $participantId failed with error: $e. Continuing...',
          );
        }

        completedParticipants++;
      }
    }

    onProgress(1.0, 'Experiment complete. ${allResponses.length} responses collected.');
    return allResponses;
  }
}