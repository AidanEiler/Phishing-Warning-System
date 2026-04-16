import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

class AiServiceTest extends StatefulWidget {
  const AiServiceTest({super.key});

  @override
  State<AiServiceTest> createState() => _AiServiceTestState();
}

class _AiServiceTestState extends State<AiServiceTest> {
  String _status = 'Press the button to test the Gemini API connection.';
  bool _isLoading = false;

  Future<void> _runTest() async {
  setState(() {
    _isLoading = true;
    _status = 'Testing basic network connectivity...';
  });

  try {
    // Test basic connectivity first
    final testResponse = await http.get(
      Uri.parse('https://generativelanguage.googleapis.com/'),
    ).timeout(const Duration(seconds: 10));
    
    setState(() => _status = 'Network reachable. Status: ${testResponse.statusCode}\nNow testing API...');

    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final service = AiService(apiKey);
    
    setState(() => _status = '$_status\nGenerating persona...');
    final persona = await service.generatePersona('TEST-001');
    setState(() {
      _status = '$_status\n\nSuccess:\n$persona';
      _isLoading = false;
    });

  } catch (e) {
    setState(() {
      _status = 'ERROR TYPE: ${e.runtimeType}\nERROR: $e';
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gemini API Test')),
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
                  : const Text('Run API Test'),
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
