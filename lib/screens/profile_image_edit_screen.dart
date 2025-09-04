import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../shared/providers/profile_image_provider.dart';

// Local profile image provider to manage the current profile image before upload
final localProfileImageProvider = StateProvider<File?>((ref) => null);

class ProfileImageEditScreen extends ConsumerWidget {
  const ProfileImageEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localProfileImage = ref.watch(localProfileImageProvider);
    final uploadState = ref.watch(profileImageUploadProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile Picture',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Current Profile Image Display
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF4F46E5),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: localProfileImage != null
                          ? Image.file(
                              localProfileImage,
                              fit: BoxFit.cover,
                              width: 200,
                              height: 200,
                            )
                          : Container(
                              color: const Color(0xFF4F46E5).withOpacity(0.1),
                              child: const Icon(
                                Icons.person,
                                size: 80,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                    ),
                  ),
                  
                  // Edit button overlay
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Action Buttons
            _buildActionButton(
              context: context,
              ref: ref,
              icon: FontAwesomeIcons.camera,
              title: 'Take Photo',
              subtitle: 'Use camera to capture a new photo',
              onTap: () => _pickImage(ref, ImageSource.camera),
            ),
            
            const SizedBox(height: 16),
            
            _buildActionButton(
              context: context,
              ref: ref,
              icon: FontAwesomeIcons.images,
              title: 'Choose from Gallery',
              subtitle: 'Select an existing photo from your gallery',
              onTap: () => _pickImage(ref, ImageSource.gallery),
            ),
            
            if (localProfileImage != null) ...[
              const SizedBox(height: 16),
              _buildActionButton(
                context: context,
                ref: ref,
                icon: FontAwesomeIcons.trash,
                title: 'Remove Photo',
                subtitle: 'Remove current profile picture',
                onTap: () => _removeImage(ref),
                isDestructive: true,
              ),
            ],
            
            const SizedBox(height: 40),
            
            // Save Button
            if (localProfileImage != null)
              uploadState.when(
                data: (_) => Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _saveProfileImage(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Save Profile Picture',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                loading: () => Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                error: (error, _) => Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Upload Failed - Retry',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDestructive 
                        ? const Color(0xFFEF4444).withOpacity(0.1)
                        : const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive 
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF4F46E5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDestructive 
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: const Color(0xFF718096),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(WidgetRef ref, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        ref.read(localProfileImageProvider.notifier).state = File(image.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeImage(WidgetRef ref) {
    ref.read(localProfileImageProvider.notifier).state = null;
  }

  Future<void> _saveProfileImage(BuildContext context, WidgetRef ref) async {
    final localImage = ref.read(localProfileImageProvider);
    if (localImage == null) return;

    try {
      // Upload the image using the profile image service
      await ref.read(profileImageUploadProvider.notifier).uploadImage(localImage);
      
      // Clear the local image after successful upload
      ref.read(localProfileImageProvider.notifier).state = null;
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile picture updated successfully!',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile picture. Please try again.',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}