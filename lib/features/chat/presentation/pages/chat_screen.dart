import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:psychology_ai_app/shared/providers/auth_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/ai_service.dart';

// Message model
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

// Chat provider
final chatMessagesProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier();
});

final isLoadingProvider = StateProvider<bool>((ref) => false);

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]) {
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: AIService.getWelcomeMessage(),
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = [welcomeMessage];
  }

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void clearChat() {
    state = [];
    _addWelcomeMessage();
  }

  List<Map<String, String>> getConversationHistory() {
    return state.map((message) => {
      'role': message.isUser ? 'user' : 'assistant',
      'content': message.content,
    }).toList();
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Clear input
    _messageController.clear();

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: messageText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    ref.read(chatMessagesProvider.notifier).addMessage(userMessage);
    _scrollToBottom();

    // Set loading state
    ref.read(isLoadingProvider.notifier).state = true;

    try {
      // Get conversation history
      final history = ref.read(chatMessagesProvider.notifier).getConversationHistory();
      
      // Get AI response
      final aiResponse = await AIService.sendMessage(messageText, history);

      // Add AI message
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      ref.read(chatMessagesProvider.notifier).addMessage(aiMessage);
      _scrollToBottom();
    } catch (e) {
      // Handle error
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: "I apologize, but I'm having trouble responding right now. Please try again in a moment.",
        isUser: false,
        timestamp: DateTime.now(),
      );

      ref.read(chatMessagesProvider.notifier).addMessage(errorMessage);
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  void _sendSuggestedMessage(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(isLoadingProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: const Icon(
                Icons.psychology_outlined,
                size: 18,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.aiPsychologistName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'AI Psychologist',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              _showChatOptions(context);
            },
            icon: const Icon(
              Icons.more_vert,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    itemCount: messages.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && isLoading) {
                        return _buildTypingIndicator();
                      }
                      
                      final message = messages[index];
                      return _buildMessageBubble(message, index);
                    },
                  ),
          ),

          // Suggested Topics (show when no messages or few messages)
          if (messages.length <= 1) _buildSuggestedTopics(),

          // Message Input
          _buildMessageInput(isLoading),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInUp(
            child: Icon(
              Icons.psychology_outlined,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Start Your Therapy Session',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: Text(
              'Dr. Sarah is here to listen and support you',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    // Get user avatar URL from profile provider
    final currentUser = ref.read(currentUserProvider).value;
    final userAvatarUrl = currentUser?.profileImageUrl;

    return FadeInUp(
      delay: Duration(milliseconds: index * 100),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
        child: Row(
          mainAxisAlignment:
              message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                backgroundImage: const NetworkImage(
                  'https://cdn-icons-png.flaticon.com/512/4712/4712035.png',
                ),
                child: Container(), // fallback if image fails
              ),
              const SizedBox(width: AppConstants.paddingSmall),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? AppTheme.primaryColor
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: message.isUser
                            ? Colors.white
                            : AppTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    Text(
                      _formatTime(message.timestamp),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: message.isUser
                            ? Colors.white.withOpacity(0.7)
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (message.isUser) ...[
              const SizedBox(width: AppConstants.paddingSmall),
              userAvatarUrl != null && userAvatarUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                      backgroundImage: NetworkImage(userAvatarUrl),
                    )
                  : CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                      child: Text(
                        (currentUser?.firstName ?? 'U').substring(0, 1).toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: const Icon(
              Icons.psychology_outlined,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Dr. Sarah is typing',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedTopics() {
    final suggestedTopics = AIService.getSuggestedTopics();
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested Topics',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Wrap(
            spacing: AppConstants.paddingSmall,
            runSpacing: AppConstants.paddingSmall,
            children: suggestedTopics.map((topic) {
              return GestureDetector(
                onTap: () => _sendSuggestedMessage(topic),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium,
                    vertical: AppConstants.paddingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    topic,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !isLoading,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Share your thoughts with Dr. Sarah...',
                hintStyle: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          FloatingActionButton(
            onPressed: isLoading ? null : _sendMessage,
            backgroundColor: AppTheme.primaryColor,
            mini: true,
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
        ],
      ),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusLarge),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh, color: AppTheme.primaryColor),
              title: const Text('New Session'),
              subtitle: const Text('Start a fresh conversation'),
              onTap: () {
                Navigator.pop(context);
                ref.read(chatMessagesProvider.notifier).clearChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppTheme.secondaryColor),
              title: const Text('About Dr. Sarah'),
              subtitle: const Text('Learn about your AI psychologist'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'About ${AppConstants.aiPsychologistName}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Dr. Sarah is an AI psychologist specializing in ${AppConstants.aiPsychologistSpecialty}. She\'s here to provide supportive, evidence-based guidance in a safe and non-judgmental environment.\n\nRemember: This is an AI assistant and not a replacement for professional therapy. For serious mental health concerns, please consult with a licensed professional.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}