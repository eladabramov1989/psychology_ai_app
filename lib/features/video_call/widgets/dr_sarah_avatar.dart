import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class DrSarahAvatar extends StatefulWidget {
  final bool isSpeaking;
  final bool isListening;
  final String currentEmotion;

  const DrSarahAvatar({
    super.key,
    this.isSpeaking = false,
    this.isListening = false,
    this.currentEmotion = 'neutral',
  });

  @override
  State<DrSarahAvatar> createState() => _DrSarahAvatarState();
}

class _DrSarahAvatarState extends State<DrSarahAvatar>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _breathingController;
  late AnimationController _speakingController;
  late Animation<double> _blinkAnimation;
  late Animation<double> _breathingAnimation;
  late Animation<double> _speakingAnimation;

  @override
  void initState() {
    super.initState();
    
    // Blinking animation
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.1).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    
    // Breathing animation
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    
    // Speaking animation
    _speakingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _speakingAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _speakingController, curve: Curves.easeInOut),
    );
    
    // Start random blinking
    _startBlinking();
  }

  void _startBlinking() {
    Future.delayed(Duration(seconds: 2 + (DateTime.now().millisecond % 3)), () {
      if (mounted) {
        _blinkController.forward().then((_) {
          _blinkController.reverse().then((_) {
            _startBlinking();
          });
        });
      }
    });
  }

  @override
  void didUpdateWidget(DrSarahAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _speakingController.repeat(reverse: true);
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _speakingController.stop();
      _speakingController.reset();
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _breathingController.dispose();
    _speakingController.dispose();
    super.dispose();
  }

  Color _getEmotionColor() {
    switch (widget.currentEmotion) {
      case 'happy':
        return Colors.orange;
      case 'empathetic':
        return Colors.blue;
      case 'concerned':
        return Colors.purple;
      case 'encouraging':
        return Colors.green;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _breathingAnimation,
        _speakingAnimation,
        _blinkAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _breathingAnimation.value * 
                 (widget.isSpeaking ? _speakingAnimation.value : 1.0),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _getEmotionColor(),
                  _getEmotionColor().withOpacity(0.7),
                  AppTheme.secondaryColor,
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: _getEmotionColor().withOpacity(
                    widget.isSpeaking ? 0.6 : 0.3,
                  ),
                  blurRadius: widget.isSpeaking ? 25 : 15,
                  spreadRadius: widget.isSpeaking ? 8 : 3,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Face base
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    child: Stack(
                      children: [
                        // Eyes
                        Positioned(
                          top: 25,
                          left: 20,
                          child: Transform.scale(
                            scaleY: _blinkAnimation.value,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.textPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 25,
                          right: 20,
                          child: Transform.scale(
                            scaleY: _blinkAnimation.value,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.textPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        
                        // Mouth
                        Positioned(
                          bottom: 25,
                          left: 30,
                          right: 30,
                          child: Container(
                            height: widget.isSpeaking ? 12 : 6,
                            decoration: BoxDecoration(
                              color: widget.isSpeaking 
                                  ? AppTheme.primaryColor 
                                  : AppTheme.textSecondary,
                              borderRadius: BorderRadius.circular(
                                widget.isSpeaking ? 6 : 3,
                              ),
                            ),
                          ),
                        ),
                        
                        // Psychology symbol overlay
                        Center(
                          child: Icon(
                            Icons.psychology_outlined,
                            size: 30,
                            color: _getEmotionColor().withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Status indicator
                if (widget.isSpeaking || widget.isListening)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isSpeaking 
                            ? Colors.green 
                            : Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.isSpeaking ? 'Speaking' : 'Listening',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Emotion detector based on conversation content
class EmotionDetector {
  static String detectEmotion(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('happy') || 
        lowerMessage.contains('good') || 
        lowerMessage.contains('better') ||
        lowerMessage.contains('grateful')) {
      return 'happy';
    }
    
    if (lowerMessage.contains('sad') || 
        lowerMessage.contains('anxious') || 
        lowerMessage.contains('worried') ||
        lowerMessage.contains('depressed') ||
        lowerMessage.contains('difficult')) {
      return 'empathetic';
    }
    
    if (lowerMessage.contains('help') || 
        lowerMessage.contains('support') || 
        lowerMessage.contains('encourage')) {
      return 'encouraging';
    }
    
    if (lowerMessage.contains('serious') || 
        lowerMessage.contains('problem') || 
        lowerMessage.contains('issue')) {
      return 'concerned';
    }
    
    return 'neutral';
  }
}