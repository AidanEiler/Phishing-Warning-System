import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_service.dart';

/// Minimal test that runs a single participant through a single session
/// to verify the full pipeline works without exhausting API quota.
/// Tests: persona generation, contextual warning generation,
/// participant response simulation, and memory summary generation.
class AiServiceTest extends StatefulWidget {
  const AiServiceTest({super.key});

  @override
  State<AiServiceTest> createState() => _AiServiceTestState();
}

class _AiServiceTestState extends State<AiServiceTest> {
  String _status = 'Press the button to run a minimal pipeline test.';
  bool _isLoading = false;

  /// A single hardcoded phishing stimulus for testing purposes
  static const String _testConversation =
      'Alex: Hey did you see the new server roles?\n'
      'You: No, what happened?\n'
      'Alex: The mods are giving out special roles to active members.';

  static const String _testFinalMessage =
      'Here is the link to claim your role: http://discord-roles-claim.net/verify';

  static const String _testLink = 'http://discord-roles-claim.net/verify';

  Future<void> _runTest() async {
    setState(() {
      _isLoading = true;
      _status = 'Starting minimal pipeline test...\n';
    });

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        setState(() {
          _status = 'ERROR: GEMINI_API_KEY not found in .env file.';
          _isLoading = false;
        });
        return;
      }

      final service = AiService(apiKey);

      /// Step 1: Generate persona (1 API call)
      _appendStatus('Step 1: Generating persona...');
      final personaMap = await service.generatePersona('TEST-001');
      _appendStatus('Persona generated: $personaMap\n');

      /// Step 2: Generate contextual warning (1 API call)
      _appendStatus('Step 2: Generating contextual warning...');
      final warning = await service.generateContextualWarning(
        conversationContext: _testConversation,
        suspiciousMessage: _testFinalMessage,
        suspiciousLink: _testLink,
      );
      _appendStatus('Warning generated: $warning\n');

      /// Step 3: Simulate participant response (1 API call)
      _appendStatus('Step 3: Simulating participant response...');
      final response = await service.simulateParticipantResponse(
        persona: personaMap,
        conversationContext: _testConversation,
        finalMessage: _testFinalMessage,
        warningText: warning,
        deliveryMode: 'interruptive',
        sessionNumber: 1,
        memoryContext: '',
      );
      _appendStatus('Response simulated: $response\n');

      /// Step 4: Generate memory summary (1 API call)
      _appendStatus('Step 4: Generating memory summary...');
      final memory = await service.generateMemorySummary(
        sessionTranscript:
            'Participant evaluated 1 stimulus. '
            'Decision: ${response['detection_decision']}. '
            'Confidence: ${response['confidence_rating']}.',
        sessionNumber: 1,
        previousMemory: null,
      );
      _appendStatus('Memory summary: $memory\n');

      _appendStatus('All steps passed. Total API calls used: 4.');
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _status = '$_status\nERROR: $e';
        _isLoading = false;
      });
    }
  }

  void _appendStatus(String message) {
    setState(() => _status = '$_status$message\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Service Test')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _runTest,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Run Pipeline Test'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}