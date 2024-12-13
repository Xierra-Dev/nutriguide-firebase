import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final OpenAI _openAI;
  bool _isInitialized = false;

  final ChatUser _user = ChatUser(
    id: '1',
    firstName: 'User',
  );

  final ChatUser _gptChatUser = ChatUser(
    id: '2',
    firstName: 'Assistant',
  );

  List<ChatMessage> _messages = <ChatMessage>[];
  List<ChatUser> _typingUsers = <ChatUser>[];

  @override
  void initState() {
    super.initState();
    _initializeOpenAI();
  }

  void _initializeOpenAI() {
    try {
      _openAI = OpenAI.instance.build(
        token: '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', // Replace with your actual OpenAI API key
        baseOption: HttpSetup(
          receiveTimeout: const Duration(seconds: 60),
          connectTimeout: const Duration(seconds: 60),
        ),
        enableLog: true,
      );
      _isInitialized = true;
      debugPrint('OpenAI initialized successfully');
    } catch (e) {
      debugPrint('Error initializing OpenAI: $e');
      _showError('Failed to initialize chat. Please check your API key and try again.');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 166, 126, 1),
        title: const Text(
          'GPT Chat',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: DashChat(
        currentUser: _user,
        messageOptions: const MessageOptions(
          currentUserContainerColor: Colors.black,
          containerColor: Color.fromRGBO(0, 166, 126, 1),
          textColor: Colors.white,
        ),
        onSend: (ChatMessage m) {
          getChatResponse(m);
        },
        messages: _messages,
        typingUsers: _typingUsers,
      ),
    );
  }

  Future<void> getChatResponse(ChatMessage m) async {
    if (!_isInitialized) {
      _showError('Chat is not initialized. Please check your API key and try again.');
      return;
    }

    setState(() {
      _messages.insert(0, m);
      _typingUsers.add(_gptChatUser);
    });

    try {
      debugPrint('Preparing chat completion request...');
      final List<Map<String, String>> messagesHistory = _messages.reversed.map((msg) {
        return {
          'role': msg.user.id == _user.id ? 'user' : 'assistant',
          'content': msg.text,
        };
      }).toList();

      messagesHistory.insert(0, {
        'role': 'system',
        'content': 'You are a helpful assistant.',
      });

      final request = ChatCompleteText(
        model: Gpt4oMiniChatModel(),
        messages: messagesHistory,
        maxToken: 2000,
        temperature: 0.7,
      );

      debugPrint('Sending request to OpenAI...');
      final response = await _openAI.onChatCompletion(request: request);
      debugPrint('Received response from OpenAI');

      if (response != null && response.choices.isNotEmpty) {
        final assistantMessage = response.choices.first.message;
        if (assistantMessage != null && assistantMessage.content.isNotEmpty) {
          debugPrint('Assistant response: ${assistantMessage.content}');
          setState(() {
            _messages.insert(
              0,
              ChatMessage(
                user: _gptChatUser,
                createdAt: DateTime.now(),
                text: assistantMessage.content,
              ),
            );
          });
        } else {
          debugPrint('Error: Assistant message is empty');
          _showError('Received empty response from assistant. Please try again.');
        }
      } else {
        debugPrint('Error: No response from OpenAI');
        _showError('No response received from assistant. Please check your internet connection and try again.');
      }
    } catch (e) {
      debugPrint('Error during chat completion: $e');
      _showError('Failed to get response from assistant. Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _typingUsers.remove(_gptChatUser);
        });
      }
    }
  }
}

