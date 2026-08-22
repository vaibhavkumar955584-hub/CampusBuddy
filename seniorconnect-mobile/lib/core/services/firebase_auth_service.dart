import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '937923495962-664o43do0nb8niev32t8naaqrdif9o7l.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  FirebaseAuthService();

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current logged in user
  User? get currentUser => _auth.currentUser;

  // 1. Email & Password Sign Up
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 1b. Email & Password Sign In
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 2. Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('[AUTH_DIAG] Step 1: Starting Google Sign-In...');
      if (kIsWeb) {
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(authProvider);
      } else {
        debugPrint('[AUTH_DIAG] Step 2: Calling _googleSignIn.signIn() with 20s timeout...');
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn().timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException('Google Sign-In did not respond within 20 seconds');
          },
        );

        if (googleUser == null) {
          debugPrint('[AUTH_DIAG] Step 2b: User cancelled Google account selection.');
          return null;
        }

        debugPrint('[AUTH_DIAG] Step 3: Google account selected: email=${googleUser.email}, displayName=${googleUser.displayName}');
        debugPrint('[AUTH_DIAG] Step 4: Fetching authentication tokens...');
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        debugPrint('[AUTH_DIAG] Step 5: ID token present: ${googleAuth.idToken != null}, Access token present: ${googleAuth.accessToken != null}');

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        debugPrint('[AUTH_DIAG] Step 6: Exchanging credential with Firebase Auth...');
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        debugPrint('[AUTH_DIAG] Step 7: Firebase Sign-In SUCCESS! UID=${userCredential.user?.uid}, Email=${userCredential.user?.email}');
        return userCredential;
      }
    } on TimeoutException catch (e, stack) {
      debugPrint('SIGN_IN_FAILURE (TimeoutException): $e');
      debugPrint('SIGN_IN_STACK: $stack');
      throw Exception('Google Sign-In timed out. Please check your network connection.');
    } on FirebaseAuthException catch (e, stack) {
      debugPrint('SIGN_IN_FAILURE (FirebaseAuthException): ${e.code} - ${e.message}');
      debugPrint('SIGN_IN_STACK: $stack');
      throw _handleAuthException(e);
    } catch (e, stack) {
      debugPrint('SIGN_IN_FAILURE (General): $e');
      debugPrint('SIGN_IN_STACK: $stack');
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // 3. Phone Authentication
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException e) onVerificationFailed,
    required void Function(PhoneAuthCredential credential) onVerificationCompleted,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  // 3b. Verify SMS Code with verificationId
  Future<UserCredential> signInWithPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (_) {
      await _auth.signOut();
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-verification-code':
        return 'The OTP entered is invalid. Please check and try again.';
      case 'invalid-verification-id':
        return 'The verification session has expired. Please request a new OTP.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      default:
        return e.message ?? 'Authentication error occurred (${e.code}).';
    }
  }
}
