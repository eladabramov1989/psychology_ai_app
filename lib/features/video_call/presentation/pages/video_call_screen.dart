import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:camera/camera.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../shared/models/appointment_model.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../widgets/dr_sarah_avatar.dart';

// Video chat message model
class VideoChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  VideoChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

// Video chat provider
final videoChatMessagesProvider = StateNotifierProvider<VideoChatNotifier, List<VideoChatMessage>>((ref) {
  return VideoChatNotifier();
});

final isVideoLoadingProvider = StateProvider<bool>((ref) => false);
final isMicMutedProvider = StateProvider<bool>((ref) => false);
final isCameraOffProvider = StateProvider<bool>((ref) => false);
final currentEmotionProvider = StateProvider<String>((ref) => 'neutral');

class VideoChatNotifier extends StateNotifier<List<VideoChatMessage>> {
  VideoChatNotifier() : super([]) {
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final welcomeMessage = VideoChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: "Hello! I'm Dr. Sarah. I'm so glad you could join me for our video session today. How are you feeling, and what would you like to focus on in our time together?",
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = [welcomeMessage];
  }

  void addMessage(VideoChatMessage message) {
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

class VideoCallScreen extends ConsumerStatefulWidget {
  final AppointmentModel appointment;

  const VideoCallScreen({
    super.key,
    required this.appointment,
  });

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _avatarAnimationController;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  bool _isAvatarSpeaking = false;
  
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeechEnabled = false;
  bool _isListening = false;

  // Video call related variables
  RTCVideoRenderer? _localRenderer;
  MediaStream? _localStream;
  bool _isCameraInitialized = false;

  Future<void> _initializeCamera() async {
    try {
      // We'll use WebRTC for camera access instead of the camera plugin
      // This ensures we have a single video stream that can be displayed
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _initializeWebRTC() async {
    try {
      // Initialize the renderer
      _localRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();

      // Get user media stream
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
          'frameRate': {'ideal': 30}
        }
      };

      // Get the media stream
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      
      // Set the stream as source for the renderer
      _localRenderer!.srcObject = _localStream;
      
      // Set camera as initialized when stream is ready
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          print('WebRTC initialized successfully');
        });
      }
    } catch (e) {
      print('Error initializing WebRTC: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _initializeTextToSpeech();
    // Initialize WebRTC first as it handles camera access
    _initializeWebRTC();
    
    _avatarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _breathingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _breathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeSpeech() async {
    // Get user's language preference
    final currentUser = ref.read(currentUserProvider).value;
    final userLanguage = currentUser?.preferences?.language ?? 'en';
    
    // Map language code to locale for speech recognition
    final localeMap = {
      'en': 'en-US',
      'es': 'es-ES',
      'fr': 'fr-FR',
      'de': 'de-DE',
      'zh': 'zh-CN',
      'ja': 'ja-JP',
      'ru': 'ru-RU',
      'ar': 'ar-SA',
      'hi': 'hi-IN',
      'pt': 'pt-BR',
    };
    
    final locale = localeMap[userLanguage] ?? 'en-US';
    
    _isSpeechEnabled = await _speechToText.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) {
        if (status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    
    // Set the locale for speech recognition if available
    if (_isSpeechEnabled) {
      final availableLocales = await _speechToText.locales();
      final matchingLocale = availableLocales.where((loc) => loc.localeId.startsWith(userLanguage)).toList();
      
      if (matchingLocale.isNotEmpty) {
        await _speechToText.listen(localeId: matchingLocale.first.localeId);
        await _speechToText.stop();
      }
    }
  }

  Future<void> _initializeTextToSpeech() async {
    // Get user's language preference
    final currentUser = ref.read(currentUserProvider).value;
    final userPreferences = currentUser?.preferences;
    final userLanguage = userPreferences?.language ?? 'en';
    final voiceSpeed = userPreferences?.voiceSpeed ?? 1.0;
    
    // Map language code to locale for text-to-speech
    final localeMap = {
      'en': 'en-US',
      'es': 'es-ES',
      'fr': 'fr-FR',
      'de': 'de-DE',
      'zh': 'zh-CN',
      'ja': 'ja-JP',
      'ru': 'ru-RU',
      'ar': 'ar-SA',
      'hi': 'hi-IN',
      'pt': 'pt-BR',
    };
    
    final locale = localeMap[userLanguage] ?? 'en-US';
    
    await _flutterTts.setLanguage(locale);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(voiceSpeed * 0.5); // Adjust speed based on user preference
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _avatarAnimationController.dispose();
    _breathingController.dispose();
    _flutterTts.stop();
    
    // Properly dispose of WebRTC resources
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) => track.stop());
    }
    _localRenderer?.dispose();
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

    // Detect emotion from user message
    final detectedEmotion = EmotionDetector.detectEmotion(messageText);
    ref.read(currentEmotionProvider.notifier).state = detectedEmotion;

    // Add user message
    final userMessage = VideoChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: messageText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    ref.read(videoChatMessagesProvider.notifier).addMessage(userMessage);
    _scrollToBottom();

    // Set loading state and avatar speaking
    ref.read(isVideoLoadingProvider.notifier).state = true;
    setState(() {
      _isAvatarSpeaking = true;
    });
    _avatarAnimationController.repeat();

    try {
      // Get conversation history
      final history = ref.read(videoChatMessagesProvider.notifier).getConversationHistory();
      
      // Get AI response
      final aiResponse = await AIService.sendMessage(messageText, history);

      // Update emotion based on AI response
      final responseEmotion = EmotionDetector.detectEmotion(aiResponse);
      ref.read(currentEmotionProvider.notifier).state = responseEmotion;

      // Add AI message
      final aiMessage = VideoChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      ref.read(videoChatMessagesProvider.notifier).addMessage(aiMessage);
      _scrollToBottom();

      // Speak the response if voice is enabled in user preferences
      final currentUser = ref.read(currentUserProvider).value;
      final voiceEnabled = currentUser?.preferences.voiceEnabled ?? false;
      
      if (voiceEnabled) {
        await _flutterTts.speak(aiResponse);
      }

      // Keep avatar speaking until TTS is done
      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isAvatarSpeaking = false;
          });
          _avatarAnimationController.stop();
          _avatarAnimationController.reset();
        }
      });
    } catch (e) {
      // Handle error
      final errorMessage = VideoChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: "I apologize, but I'm having trouble responding right now. Please try again in a moment.",
        isUser: false,
        timestamp: DateTime.now(),
      );

      ref.read(videoChatMessagesProvider.notifier).addMessage(errorMessage);
    } finally {
      ref.read(isVideoLoadingProvider.notifier).state = false;
      setState(() {
        _isAvatarSpeaking = false;
      });
      _avatarAnimationController.stop();
      _avatarAnimationController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(videoChatMessagesProvider);
    final isLoading = ref.watch(isVideoLoadingProvider);
    final isMicMuted = ref.watch(isMicMutedProvider);
    final isCameraOff = ref.watch(isCameraOffProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Video call header
            _buildVideoHeader(),
            
            // Main video area
            Expanded(
              flex: 3,
              child: _buildVideoArea(),
            ),
            
            // Chat area
            Expanded(
              flex: 2,
              child: _buildChatArea(messages, isLoading),
            ),
            
            // Controls
            _buildVideoControls(isMicMuted, isCameraOff),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.appointment.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '${widget.appointment.type.displayName} • ${_formatDuration()}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    final currentEmotion = ref.watch(currentEmotionProvider);
    
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.1),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Dr. Sarah's video area
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // AI Psychologist Avatar with breathing animation
                AnimatedBuilder(
                  animation: _breathingAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _breathingAnimation.value,
                      child: child,
                    );
                  },
                  child: DrSarahAvatar(
                    isSpeaking: _isAvatarSpeaking,
                    isListening: !_isAvatarSpeaking && !ref.watch(isVideoLoadingProvider),
                    currentEmotion: currentEmotion,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  'Dr. Sarah',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isAvatarSpeaking 
                      ? 'Speaking...' 
                      : ref.watch(isVideoLoadingProvider)
                          ? 'Thinking...'
                          : 'Listening',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                if (currentEmotion != 'neutral')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Feeling ${currentEmotion}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // User's video preview (small)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 100,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: ref.watch(isCameraOffProvider)
                    ? const Center(
                        child: Icon(
                          Icons.videocam_off,
                          color: Colors.white,
                          size: 30,
                        ),
                      )
                    : _isCameraInitialized && _localRenderer != null && _localRenderer!.srcObject != null
                        ? RTCVideoView(
                            _localRenderer!,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          )
                        : const Center(
                            child: CircularProgressIndicator(),
                          ),
              ),
            ),
          ),
          
          // Session info overlay
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AI Therapy Session',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(List<VideoChatMessage> messages, bool isLoading) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusLarge),
        ),
      ),
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              children: [
                Icon(
                  Icons.chat_outlined,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Text(
                  'Session Chat',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
              itemCount: messages.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isLoading) {
                  return _buildTypingIndicator();
                }
                
                final message = messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          // Message input
          _buildMessageInput(isLoading),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(VideoChatMessage message) {
    final currentUser = ref.read(currentUserProvider).value;

    final userAvatarUrl = currentUser?.profileImageUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: const Icon(
                Icons.psychology_outlined,
                size: 12,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.primaryColor
                    : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message.content,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: message.isUser
                      ? Colors.white
                      : AppTheme.textPrimary,
                ),
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
                      (currentUser?.firstName ?? 'U')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: const Icon(
              Icons.psychology_outlined,
              size: 12,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Dr. Sarah is responding...',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
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

  Widget _buildMessageInput(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !isLoading,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: isLoading ? null : _sendMessage,
            backgroundColor: AppTheme.primaryColor,
            mini: true,
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 16,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls(bool isMicMuted, bool isCameraOff) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Microphone toggle
          FloatingActionButton(
            heroTag: 'mic_button',
            onPressed: () async {
              if (!_isSpeechEnabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Speech recognition not available')),
                );
                return;
              }

              if (_isListening) {
                await _speechToText.stop();
                setState(() => _isListening = false);
              } else {
                final bool available = await _speechToText.initialize();
                if (available) {
                  setState(() => _isListening = true);
                  
                  // Get user's language preference
                  final currentUser = ref.read(currentUserProvider).value;
                  final userLanguage = currentUser?.preferences?.language ?? 'en';
                  
                  // Map language code to locale for speech recognition
                  final localeMap = {
                    'en': 'en-US',
                    'es': 'es-ES',
                    'fr': 'fr-FR',
                    'de': 'de-DE',
                    'zh': 'zh-CN',
                    'ja': 'ja-JP',
                    'ru': 'ru-RU',
                    'ar': 'ar-SA',
                    'hi': 'hi-IN',
                    'pt': 'pt-BR',
                  };
                  
                  // Get available locales and find a matching one
                  final availableLocales = await _speechToText.locales();
                  final matchingLocale = availableLocales
                      .where((loc) => loc.localeId.startsWith(userLanguage))
                      .toList();
                  
                  final localeId = matchingLocale.isNotEmpty 
                      ? matchingLocale.first.localeId 
                      : localeMap[userLanguage] ?? 'en-US';
                  
                  await _speechToText.listen(
                    localeId: localeId,
                    onResult: (result) {
                      if (result.finalResult) {
                        _handleMessageSubmit(result.recognizedWords);
                        setState(() => _isListening = false);
                      }
                    },
                  );
                }
              }
              ref.read(isMicMutedProvider.notifier).state = !_isListening;
              
              // Mute/unmute audio tracks if available
              if (_localStream != null) {
                _localStream!.getAudioTracks().forEach((track) {
                  track.enabled = !ref.read(isMicMutedProvider);
                });
              }
            },
            backgroundColor: _isListening ? AppTheme.primaryColor : Colors.grey[800],
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_off,
              color: Colors.white,
            ),
          ),
          
          // Camera toggle
          FloatingActionButton(
            heroTag: 'camera_button',
            onPressed: () {
              ref.read(isCameraOffProvider.notifier).state = !isCameraOff;
              
              // Enable/disable video tracks if available
              if (_localStream != null) {
                _localStream!.getVideoTracks().forEach((track) {
                  track.enabled = !ref.read(isCameraOffProvider);
                });
              }
            },
            backgroundColor: isCameraOff ? AppTheme.errorColor : Colors.grey[800],
            child: Icon(
              isCameraOff ? Icons.videocam_off : Icons.videocam,
              color: Colors.white,
            ),
          ),
          
          // End call
          FloatingActionButton(
            heroTag: 'end_call_button',
            onPressed: () {
              _showEndCallDialog();
            },
            backgroundColor: AppTheme.errorColor,
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMessageSubmit(String messageText) async {
    if (messageText.trim().isEmpty) return;

    // Add user message
    final userMessage = VideoChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: messageText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    ref.read(videoChatMessagesProvider.notifier).addMessage(userMessage);
    _scrollToBottom();

    // Set loading state and avatar speaking
    ref.read(isVideoLoadingProvider.notifier).state = true;
    setState(() {
      _isAvatarSpeaking = true;
    });
    _avatarAnimationController.repeat();

    try {
      // Get conversation history
      final history = ref.read(videoChatMessagesProvider.notifier).getConversationHistory();
      
      // Get AI response
      final aiResponse = await AIService.sendMessage(messageText, history);

      // Update emotion based on AI response
      final responseEmotion = EmotionDetector.detectEmotion(aiResponse);
      ref.read(currentEmotionProvider.notifier).state = responseEmotion;

      // Add AI message
      final aiMessage = VideoChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      ref.read(videoChatMessagesProvider.notifier).addMessage(aiMessage);
      _scrollToBottom();

      // Speak the response
      await _flutterTts.speak(aiResponse);
    } catch (e) {
      // Handle error
      final errorMessage = VideoChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: "I apologize, but I'm having trouble responding right now. Please try again in a moment.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      ref.read(videoChatMessagesProvider.notifier).addMessage(errorMessage);
    } finally {
      ref.read(isVideoLoadingProvider.notifier).state = false;
      setState(() {
        _isAvatarSpeaking = false;
      });
      _avatarAnimationController.stop();
      _avatarAnimationController.reset();
    }
  }

 

  void _showEndCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'End Session',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to end this therapy session?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close video call
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Session ended. Thank you for joining!'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  String _formatDuration() {
    // This would normally track actual session time
    return '05:32';
  }
}

extension on AppointmentType {
  String get displayName {
    switch (this) {
      case AppointmentType.videoCall:
        return 'Video Call';
      case AppointmentType.chatSession:
        return 'Chat Session';
    }
  }
}