import 'package:flutter/material.dart';

void main() {
  runApp(const PhishingWarningApp());
}

class PhishingWarningApp extends StatelessWidget {
  const PhishingWarningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phishing Warning System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF2B2D31),
          primary: Color(0xFF5865F2),
        ),
        scaffoldBackgroundColor: const Color(0xFF313338),
        useMaterial3: true,
      ),
      home: const ConversationScreen(),
    );
  }
}

class Message {
  final String sender;
  final String content;
  final bool isPhishing;
  final String? linkUrl;

  const Message({
    required this.sender,
    required this.content,
    this.isPhishing = false,
    this.linkUrl,
  });
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  bool _isAnalyzing = false;

  final List<Message> _messages = [
    const Message(
      sender: 'Alex Chen',
      content: 'Hey! Did you see the announcement about the new server roles?',
    ),
    const Message(sender: 'You', content: 'No, what happened?'),
    const Message(
      sender: 'Alex Chen',
      content:
          'The mods are giving out special roles to active members. You should claim yours before they run out.',
    ),
    const Message(
      sender: 'Alex Chen',
      content:
          'Here is the link to claim it: http://discord-roles-claim.net/verify',
      isPhishing: true,
      linkUrl: 'http://discord-roles-claim.net/verify',
    ),
  ];

  Future<String> _generateWarning(String messageContent, String linkUrl) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'This message is attempting to trick you into clicking a suspicious link by creating a false sense of urgency around claiming a server role. The domain "discord-roles-claim.net" is not affiliated with Discord and is designed to steal your login credentials. Official Discord role assignments never require visiting external websites.';
  }

  Future<void> _handleLinkClick(Message message) async {
    setState(() => _isAnalyzing = true);

    String warningText;
    try {
      warningText = await _generateWarning(
        message.content,
        message.linkUrl ?? '',
      );
    } catch (e) {
      warningText =
          'This link appears suspicious. It may be attempting to steal your credentials or personal information.';
    }

    setState(() => _isAnalyzing = false);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WarningModal(
            warningText: warningText,
            linkUrl: message.linkUrl ?? '',
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF313338),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B2D31),
        title: Row(
          children: [
            const Icon(Icons.tag, color: Color(0xFF80848E), size: 20),
            const SizedBox(width: 6),
            const Text(
              'general',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 20, color: const Color(0xFF4E5058)),
            const SizedBox(width: 8),
            const Text(
              'CS 4850 Server',
              style: TextStyle(color: Color(0xFF80848E), fontSize: 14),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return MessageBubble(
                      message: message,
                      onLinkTap:
                          message.isPhishing
                              ? () => _handleLinkClick(message)
                              : null,
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF2B2D31),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF383A40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Message #general',
                    style: TextStyle(color: Color(0xFF6D6F78)),
                  ),
                ),
              ),
            ],
          ),
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF5865F2)),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing message...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onLinkTap;

  const MessageBubble({super.key, required this.message, this.onLinkTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF5865F2),
            child: Text(
              message.sender[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.sender,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                if (message.linkUrl != null)
                  GestureDetector(
                    onTap: onLinkTap,
                    child: Text(
                      message.content,
                      style: const TextStyle(
                        color: Color(0xFF00A8FC),
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF00A8FC),
                      ),
                    ),
                  )
                else
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: Color(0xFFDBDEE1),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WarningModal extends StatelessWidget {
  final String warningText;
  final String linkUrl;

  const WarningModal({
    super.key,
    required this.warningText,
    required this.linkUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2B2D31),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFED4245), width: 2),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFED4245),
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Phishing Warning',
                  style: TextStyle(
                    color: Color(0xFFED4245),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              warningText,
              style: const TextStyle(
                color: Color(0xFFDBDEE1),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1F22),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                linkUrl,
                style: const TextStyle(
                  color: Color(0xFF80848E),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Go Back (Safe)',
                    style: TextStyle(color: Color(0xFF57F287)),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message reported.')),
                    );
                  },
                  child: const Text(
                    'Report',
                    style: TextStyle(color: Color(0xFF80848E)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED4245),
                  ),
                  child: const Text(
                    'Proceed Anyway',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
