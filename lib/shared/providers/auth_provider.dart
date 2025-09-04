import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

// Current user provider
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user != null) {
        final firestore = ref.watch(firestoreProvider);
        return firestore
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .map((doc) {
          if (doc.exists) {
            return UserModel.fromFirestore(doc);
          }
          return null;
        });
      }
      return Stream.value(null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return AuthService(auth: auth, firestore: firestore);
});

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    String? phoneNumber,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document in Firestore
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          dateOfBirth: dateOfBirth,
          phoneNumber: phoneNumber,
          profileImageUrl: null,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isActive: true,
          preferences: UserPreferences(),
          sessionStats: SessionStats(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toFirestore());

        // Update display name
        await credential.user!.updateDisplayName('$firstName $lastName');
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'An error occurred during sign up');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update last login time
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'An error occurred during sign in');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('An error occurred during sign out');
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'An error occurred while resetting password');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final updateData = <String, dynamic>{};
        
        if (firstName != null || lastName != null) {
          updateData['firstName'] = firstName;
          updateData['lastName'] = lastName;
          
          // Update display name
          final displayName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
          await user.updateDisplayName(displayName);
        }
        
        if (phoneNumber != null) {
          updateData['phoneNumber'] = phoneNumber;
        }
        
        if (profileImageUrl != null) {
          updateData['profileImageUrl'] = profileImageUrl;
          await user.updatePhotoURL(profileImageUrl);
        }

        if (updateData.isNotEmpty) {
          updateData['updatedAt'] = FieldValue.serverTimestamp();
          await _firestore
              .collection('users')
              .doc(user.uid)
              .update(updateData);
        }
      }
    } catch (e) {
      throw AuthException('An error occurred while updating profile');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        
        // Delete user authentication
        await user.delete();
      }
    } catch (e) {
      throw AuthException('An error occurred while deleting account');
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}