import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/simple_openrouter_service.dart';
import '../../../services/user_repository.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isLoadingUser = true;
  String _userName = 'Magyasaka';

  List<ChatMessage> messages = [];

  List<String> recommendations = [
    "Tips menyimpan sampah organik agar tidak menimbulkan aroma bau?",
    "Kota penghasil sampah terbesar",
    "Cara membuat prakarya dari sampah botol",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      // Get user data from Firebase Auth first
      final user = FirebaseAuth.instance.currentUser;
      String displayName = 'Magyasaka'; // Default fallback
      
      if (user != null) {
        // Try to get display name from Firebase Auth
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          displayName = user.displayName!;
        } else {
          // If no display name in Auth, try to get from Firestore
          try {
            final userProfile = await UserRepository().getProfile();
            if (userProfile['displayName'] != null && userProfile['displayName'].toString().isNotEmpty) {
              displayName = userProfile['displayName'];
            } else {
              // Extract name from email if no display name
              final email = user.email ?? '';
              if (email.isNotEmpty) {
                displayName = email.split('@')[0].replaceAll('.', ' ').replaceAll('_', ' ');
                // Capitalize first letter of each word
                displayName = displayName.split(' ').map((word) => 
                  word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : ''
                ).join(' ');
              }
            }
          } catch (e) {
            // If Firestore fails, keep the default or use email
            if (user.email != null) {
              displayName = user.email!.split('@')[0];
            }
          }
        }
      }

      setState(() {
        _userName = displayName;
        _isLoadingUser = false;
        // Add initial greeting message with user's name
        messages = [
          ChatMessage(
            text: "Halo, $_userName 👋\nAda yang bisa saya bantu?",
            isBot: true,
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            showRecommendations: true,
          ),
        ];
      });
    } catch (e) {
      // If anything fails, use default
      setState(() {
        _userName = 'Magyasaka';
        _isLoadingUser = false;
        messages = [
          ChatMessage(
            text: "Halo, $_userName 👋\nAda yang bisa saya bantu?",
            isBot: true,
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            showRecommendations: true,
          ),
        ];
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    String userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      messages.add(
        ChatMessage(
          text: userMessage,
          isBot: false,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Get response from OpenRouter API
      String botResponse = await SimpleOpenRouterService.sendMessage(userMessage, userName: _userName);
      
      // If response is empty, provide a fallback
      if (botResponse.trim().isEmpty) {
        botResponse = "Maaf, saya tidak dapat memberikan jawaban saat ini. Silakan coba dengan pertanyaan yang berbeda.";
      }

      setState(() {
        messages.add(
          ChatMessage(
            text: botResponse,
            isBot: true,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        messages.add(
          ChatMessage(
            text: "Maaf, terjadi kesalahan. Silakan coba lagi nanti.",
            isBot: true,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }



  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendRecommendation(String recommendation) async {
    if (_isLoading) return;

    setState(() {
      messages.add(
        ChatMessage(
          text: recommendation,
          isBot: false,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Get response from OpenRouter API
      String botResponse = await SimpleOpenRouterService.sendMessage(recommendation, userName: _userName);
      
      // If response is empty, provide a fallback
      if (botResponse.trim().isEmpty) {
        botResponse = "Maaf, saya tidak dapat memberikan jawaban saat ini. Silakan coba dengan pertanyaan yang berbeda.";
      }

      setState(() {
        messages.add(
          ChatMessage(
            text: botResponse,
            isBot: true,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        messages.add(
          ChatMessage(
            text: "Maaf, terjadi kesalahan. Silakan coba lagi nanti.",
            isBot: true,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ChatBot',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingUser
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3E7B27)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Memuat data pengguna...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Chat messages area
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && _isLoading) {
                        return _buildLoadingIndicator();
                      }
                      
                      final message = messages[index];
                      return Column(
                        children: [
                          if (index == 0) _buildDateHeader(),
                          _buildMessageBubble(message),
                          if (message.showRecommendations) _buildRecommendations(),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ),
                // Input area
                _buildInputArea(),
              ],
            ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Hari Ini',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Row(
      mainAxisAlignment: message.isBot
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.isBot) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3E7B27), Color(0xFF85A947)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3E7B27).withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.isBot
            ? Colors.grey[100]
            : const Color(0xFF3E7B27),
        borderRadius: BorderRadius.circular(16),
        boxShadow: message.isBot
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF3E7B27).withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: message.isBot ? Colors.black : Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 8),
            child: Text(
              '[ Rekomendasi ]',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ...recommendations
              .map((recommendation) => _buildRecommendationCard(recommendation)),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String recommendation) {
    return Container(
      margin: const EdgeInsets.only(left: 40, bottom: 8),
      child: InkWell(
        onTap: () => _sendRecommendation(recommendation),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF123524), Color(0xFF3E7B27), Color(0xFF85A947)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3E7B27).withValues(alpha: 0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3E7B27), Color(0xFF85A947)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3E7B27).withValues(alpha: 0.3),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF3E7B27),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Sedang mengetik...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Ketik Sesuatu...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isLoading 
                    ? [Colors.grey[400]!, Colors.grey[500]!, Colors.grey[600]!]
                    : [const Color(0xFF123524), const Color(0xFF3E7B27), const Color(0xFF85A947)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: _isLoading ? [] : [
                  BoxShadow(
                    color: const Color(0xFF3E7B27).withValues(alpha: 0.4),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final bool showRecommendations;

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
    this.showRecommendations = false,
  });
}
