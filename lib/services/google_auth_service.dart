import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../firebase_options.dart';
import '../utils/app_logger.dart';
import '../utils/storage_utils.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // GoogleSignIn for mobile only (web uses Firebase Auth directly)
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<Map<String, dynamic>> signInWithGoogle() async {
    await _ensureFirebaseInitialized();

    // WEB: Use Firebase Auth signInWithPopup directly
    // This avoids gapi.auth2 double-initialization conflict
    if (kIsWeb) {
      return _signInWithGoogleWeb();
    }
    // MOBILE: Use GoogleSignIn package
    return _signInWithGoogleMobile();
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e, stackTrace) {
        AppLogger.authError('Firebase initializeApp failed',
            error: e, stackTrace: stackTrace);
        rethrow;
      }
    }
  }

  /// Web-specific Google Sign-In using Firebase Auth popup
  /// Avoids gapi.auth2 init conflict by not using google_sign_in package on web
  Future<Map<String, dynamic>> _signInWithGoogleWeb() async {
    try {
      // Create Google Auth Provider
      final googleProvider = GoogleAuthProvider();

      // Sign in with popup (Firebase handles everything on web)
      final UserCredential userCredential =
          await _auth.signInWithPopup(googleProvider);
      final User? user = userCredential.user;

      if (user == null) {
        return {
          'success': false,
          'message': 'Firebase user not found after Google Sign-In',
          'error': 'FIREBASE_USER_NULL'
        };
      }

      // Send to backend
      final String? firebaseIdToken = await user.getIdToken();
      if (firebaseIdToken == null) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Failed to get Firebase ID token',
          'error': 'ID_TOKEN_NULL'
        };
      }

      final backendResponse = await _sendToBackend(user, firebaseIdToken);
      return await _handleBackendResponse(backendResponse, isWeb: true);
    } catch (e, stackTrace) {
      AppLogger.authError('Web Google Sign-In failed',
          error: e, stackTrace: stackTrace);
      await _auth.signOut();
      return {
        'success': false,
        'message': 'Google Sign-In failed: ${e.toString()}',
        'error': 'GOOGLE_SIGN_IN_ERROR'
      };
    }
  }

  /// Mobile-specific Google Sign-In using google_sign_in package
  Future<Map<String, dynamic>> _signInWithGoogleMobile() async {
    try {
      // Step 1: Google account select karen
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {
          'success': false,
          'message': 'Google Sign-In cancelled by user',
          'error': 'SIGN_IN_CANCELLED'
        };
      }

      // Step 2: Auth details lein
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null && idToken == null) {
        AppLogger.authError('Google auth tokens missing',
            error: 'Both accessToken and idToken are null');
        await _auth.signOut();
        await _googleSignIn.signOut();
        return {
          'success': false,
          'message': 'Google authentication failed: missing tokens',
          'error': 'GOOGLE_AUTH_TOKENS_MISSING'
        };
      }

      // Step 3: Firebase credential banayein
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // Step 4: Firebase me sign-in karein
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        return {
          'success': false,
          'message': 'Firebase user not found',
          'error': 'FIREBASE_USER_NULL'
        };
      }

      // Step 5: Backend ko call karein
      final String? firebaseIdToken = await user.getIdToken();
      final backendResponse = await _sendToBackend(user, firebaseIdToken!);
      return await _handleBackendResponse(backendResponse, isWeb: false);
    } catch (e, stackTrace) {
      AppLogger.authError('Mobile Google Sign-In failed',
          error: e, stackTrace: stackTrace);
      await _auth.signOut();
      await _googleSignIn.signOut();
      return {
        'success': false,
        'message': 'Google Sign-In failed: ${e.toString()}',
        'error': 'GOOGLE_SIGN_IN_ERROR'
      };
    }
  }

  /// Handle backend response - shared between web and mobile
  Future<Map<String, dynamic>> _handleBackendResponse(
    Map<String, dynamic> backendResponse, {
    required bool isWeb,
  }) async {
    if (backendResponse['success']) {
      // Save token
      final token = backendResponse['data']['token'];
      await StorageUtils.saveToken(token);

      // Save user data
      if (backendResponse['data']['user'] != null) {
        await StorageUtils.saveUserData(backendResponse['data']['user']);
        final userObj = backendResponse['data']['user'];
        if (userObj['userId'] != null) {
          await StorageUtils.saveUserId(userObj['userId']);
        } else if (userObj['id'] != null) {
          await StorageUtils.saveUserId(userObj['id']);
        }
        // Note: AuthProvider update should be handled by the calling widget
        // to avoid BuildContext usage across async gaps in service layer
      }

      return {
        'success': true,
        'message': 'Google Sign-In successful',
        'data': backendResponse['data']
      };
    } else {
      await _auth.signOut();
      if (!isWeb) {
        await _googleSignIn.signOut();
      }
      return {
        'success': false,
        'message':
            backendResponse['message'] ?? 'Backend authentication failed',
        'error': 'BACKEND_AUTH_FAILED'
      };
    }
  }

  Future<Map<String, dynamic>> _sendToBackend(User user, String idToken) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/google-signin');
      AppLogger.info('Sending Google sign-in request to: $url');

      final requestBody = jsonEncode({
        'firebaseUid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
      });

      AppLogger.info('Request body: $requestBody');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30));

      AppLogger.info('Response status: ${response.statusCode}');
      AppLogger.info('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseData['data']};
      } else {
        AppLogger.apiError('/api/auth/google-signin',
            statusCode: response.statusCode, responseBody: response.body);
        return {
          'success': false,
          'message': responseData['message'] ??
              'Backend authentication failed (Status: ${response.statusCode})',
          'error': 'BACKEND_ERROR'
        };
      }
    } catch (e, stackTrace) {
      AppLogger.error('Google sign-in backend request failed',
          error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NETWORK_ERROR'
      };
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await StorageUtils.clearAll();
    } catch (e, stackTrace) {
      AppLogger.authError('Google signOut failed',
          error: e, stackTrace: stackTrace);
    }
  }

  bool get isSignedIn => _auth.currentUser != null;
  dynamic get currentUser => _auth.currentUser;
}

