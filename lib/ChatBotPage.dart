import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:gym/config/config.dart';
import 'package:animate_do/animate_do.dart';


class ChatBotPage extends StatefulWidget {
  @override
  _ChatBotPageState createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getString('chat_history');
    if (savedMessages != null) {
      setState(() {
        _messages.addAll(List<Map<String, String>>.from(jsonDecode(savedMessages)));
      });
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_history', jsonEncode(_messages));
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": message});
      _isLoading = true;
    });
    await _saveChatHistory();

    try {
      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro:generateContent?key=$geminiApiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": _messages
              .map((msg) => {
            "role": msg["role"],
            "parts": [{"text": msg["content"]}]
          })
              .toList(),
          "generationConfig": {"maxOutputTokens": 2048}
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final fullText = responseData['candidates']?[0]['content']['parts'][0]['text'] ?? "No response from AI.";

        setState(() {
          _messages.add({"role": "assistant", "content": fullText});
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _messages.add({"role": "assistant", "content": "Error: ${errorData["error"]?["message"] ?? "Unknown error"}"});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"role": "assistant", "content": "Error: Network issue or API failure."});
      });
    } finally {
      _isLoading = false;
      await _saveChatHistory();
    }
  }

  void _showCopyShareOptions(String content) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.copy),
              title: Text('Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.share),
              title: Text('Share'),
              onTap: () {
                Share.share(content);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(Map<String, String> msg, int index) {
    final isUser = msg["role"] == "user";
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isUser ? Colors.blue[300] : Colors.grey[300];

    return FadeInUp(
      duration: Duration(milliseconds: 300 + index * 50),
      child: Align(
        alignment: alignment,
        child: GestureDetector(
          onLongPress: () => _showCopyShareOptions(msg["content"]!),
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Text(msg["content"]!),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Chatbot"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: false,
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final msg = _messages[index];
                return _buildChatBubble(msg, index);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _sendMessage(value);
                        _controller.clear();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: "Ask something...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                FloatingActionButton.small(
                  heroTag: null,
                  backgroundColor: Colors.blueAccent,
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                  child: const Icon(Icons.send),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
