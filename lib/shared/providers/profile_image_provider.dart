import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:psychology_ai_app/shared/providers/auth_provider.dart';

// Profile image service to handle image uploads and management
class ProfileImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      // Create a unique filename
      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      
      // Create reference to Firebase Storage
      final ref = _storage.ref().child('profile_images').child(fileName);
      
      // Upload the file
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting profile image: $e');
      return false;
    }
  }
}

// Provider for the profile image service
final profileImageServiceProvider = Provider<ProfileImageService>((ref) {
  return ProfileImageService();
});

// Provider for managing profile image upload state
final profileImageUploadProvider = StateNotifierProvider<ProfileImageUploadNotifier, AsyncValue<String?>>((ref) {
  return ProfileImageUploadNotifier(ref);
});

class ProfileImageUploadNotifier extends StateNotifier<AsyncValue<String?>> {
  final Ref _ref;
  
  ProfileImageUploadNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> uploadImage(File imageFile) async {
    state = const AsyncValue.loading();
    
    try {
      final currentUser = _ref.read(currentUserProvider).value;
      if (currentUser == null) {
        state = AsyncValue.error('User not authenticated', StackTrace.current);
        return;
      }

      final profileImageService = _ref.read(profileImageServiceProvider);
      final downloadUrl = await profileImageService.uploadProfileImage(imageFile, currentUser.uid);
      
      if (downloadUrl != null) {
        // Update user profile with new image URL
        final authService = _ref.read(authServiceProvider);
        await authService.updateUserProfile(profileImageUrl: downloadUrl);
        
        state = AsyncValue.data(downloadUrl);
      } else {
        state = AsyncValue.error('Failed to upload image', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeImage() async {
    state = const AsyncValue.loading();
    
    try {
      final currentUser = _ref.read(currentUserProvider).value;
      if (currentUser == null) {
        state = AsyncValue.error('User not authenticated', StackTrace.current);
        return;
      }

      // Delete from Firebase Storage if exists
      if (currentUser.profileImageUrl != null) {
        final profileImageService = _ref.read(profileImageServiceProvider);
        await profileImageService.deleteProfileImage(currentUser.profileImageUrl!);
      }

      // Update user profile to remove image URL
      final authService = _ref.read(authServiceProvider);
      await authService.updateUserProfile(profileImageUrl: null);
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}