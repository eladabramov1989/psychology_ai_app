# Video Call Feature Documentation

## Overview
The video call feature provides an immersive AI therapy session experience with Dr. Sarah, the AI psychologist. When users join a video call appointment, they are presented with a professional therapy session interface featuring an animated AI avatar.

## Key Features

### 1. AI Psychologist Avatar (Dr. Sarah)
- **Animated Character**: Dr. Sarah appears as an animated avatar with realistic behaviors
- **Emotional Intelligence**: The avatar changes colors and expressions based on conversation context
- **Breathing Animation**: Subtle breathing animation to make the avatar feel alive
- **Speaking Indicators**: Visual and animation cues when Dr. Sarah is speaking
- **Blinking**: Random blinking animation for natural appearance

### 2. Emotion Detection System
The system automatically detects emotions from both user messages and AI responses:
- **Happy**: Detected from positive words like "happy", "good", "better", "grateful"
- **Empathetic**: Triggered by words like "sad", "anxious", "worried", "depressed"
- **Encouraging**: Activated by "help", "support", "encourage"
- **Concerned**: For serious topics like "problem", "issue", "serious"
- **Neutral**: Default state

### 3. Video Call Interface

#### Main Video Area
- Large central area featuring Dr. Sarah's avatar
- Real-time emotion display ("Feeling empathetic", etc.)
- Session status indicators (Speaking, Listening, Thinking)
- Small user video preview in corner
- Professional session overlay with "AI Therapy Session" label

#### Interactive Chat
- Real-time text chat during video session
- Message bubbles with user and AI responses
- Typing indicators when Dr. Sarah is responding
- Scroll functionality for long conversations

#### Video Controls
- **Microphone Toggle**: Mute/unmute microphone
- **Camera Toggle**: Turn camera on/off
- **End Call Button**: Safely end the therapy session

### 4. Session Management
- Professional session header with duration timer
- Live session indicator
- Appointment details integration
- Proper session termination with confirmation dialog

## Technical Implementation

### Avatar Animations
- **Breathing**: 4-second cycle for natural appearance
- **Speaking**: Mouth movement and color changes during responses
- **Blinking**: Random intervals (2-5 seconds) for realism
- **Emotional States**: Color gradients change based on detected emotions

### State Management
- Uses Flutter Riverpod for state management
- Separate providers for:
  - Video chat messages
  - Loading states
  - Microphone/camera states
  - Current emotion
  - Avatar speaking state

### AI Integration
- Integrates with existing AIService
- Conversation history maintained throughout session
- Response timing based on message length for realistic speaking duration
- Emotion detection affects avatar appearance in real-time

## User Experience

### Starting a Video Session
1. User schedules a "Video Call" appointment
2. Clicks "Join" button on appointment card
3. Automatically navigates to video call screen
4. Dr. Sarah greets user with welcome message

### During the Session
1. Dr. Sarah's avatar responds to user's emotional state
2. Real-time visual feedback during conversation
3. Professional therapy environment with calming colors
4. Easy-to-use controls for audio/video management

### Ending the Session
1. User clicks red "End Call" button
2. Confirmation dialog appears
3. Session ends with thank you message
4. Returns to appointments screen

## Benefits

### For Users
- **Immersive Experience**: Feels like talking to a real therapist
- **Visual Feedback**: Avatar emotions help users feel understood
- **Professional Environment**: Serious, therapeutic atmosphere
- **Accessibility**: Text chat backup during video calls

### For Therapy Effectiveness
- **Emotional Connection**: Avatar creates sense of presence
- **Non-judgmental Environment**: AI doesn't show negative emotions
- **Consistent Availability**: Dr. Sarah is always ready for sessions
- **Privacy**: Secure, confidential AI interactions

## Future Enhancements
- Voice recognition for hands-free interaction
- More sophisticated avatar expressions
- Session recording capabilities
- Integration with therapy progress tracking
- Multi-language support for avatar responses

This video call feature transforms the AI therapy experience from simple text chat into an engaging, professional therapy session that closely mimics in-person psychological counseling.