import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'transport_brain.dart';
import '../../common/services/language_service.dart'; // IMPORT TTS SERVICE

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final TransportBrain _brain = TransportBrain();
  final LanguageService _lang = LanguageService(); // VOICE ENGINE
  
  final List<Map<String, String>> _messages = [
    {"role": "bot", "text": "Hello! I am CampusBot. Ask me about any bus."}
  ];
  bool _isTyping = false;
  bool _voiceEnabled = true; // Toggle for sound

  @override
  void dispose() {
    _lang.stop(); // Stop talking when leaving screen
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _controller.clear();
      _isTyping = true;
    });

    // 1. GET ANSWER FROM AI
    final response = await _brain.askAI(text);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({"role": "bot", "text": response});
      });

      // 2. SPEAK THE ANSWER (TTS)
      if (_voiceEnabled) {
        await _lang.speak(response);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.psychology, color: Colors.purple),
            const SizedBox(width: 10),
            Text("AI Assistant", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white, 
        elevation: 1,
        actions: [
          // MUTE/UNMUTE BUTTON
          IconButton(
            icon: Icon(_voiceEnabled ? Icons.volume_up : Icons.volume_off, color: Colors.purple),
            onPressed: () {
              setState(() => _voiceEnabled = !_voiceEnabled);
              if (!_voiceEnabled) _lang.stop();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final isUser = _messages[i]['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.purple : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: isUser ? const Radius.circular(15) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(15),
                      ),
                    ),
                    child: Text(
                      _messages[i]['text']!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
                  ).animate().fade().slideY(begin: 0.1, end: 0),
                );
              },
            ),
          ),
          
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 10),
                    Text("CampusBot is thinking...", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),

          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask me anything...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _isTyping ? null : _sendMessage,
                  mini: true,
                  backgroundColor: Colors.purple,
                  child: const Icon(Icons.send, color: Colors.white),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}