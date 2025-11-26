// --------------------------------------------------------------------------
// Mobile Google Authentication Service - Web Implementation
// --------------------------------------------------------------------------
// 
// PLATFORM SUPPORT: Web only
// Uses GoogleSignIn wrapper (web implementation with gapi.auth2)
// --------------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'drive_config.dart';
import 'drive_crud_client.dart';
import '../google_sign_in_wrapper.dart';

/// Web implementation with full OAuth2 support
class MobileGoogleAuthService {
  final GoogleDriveConfig _config;
  late final GoogleSignIn _googleSignIn;
  GoogleSignInAccount? _currentUser;
  String? _accessToken;
  
  final StreamController<GoogleSignInAccount?> _authStateController = 
      StreamController<GoogleSignInAccount?>.broadcast();

  MobileGoogleAuthService({required GoogleDriveConfig config})
      : _config = config {
    _googleSignIn = GoogleSignIn(
      clientId: '628217349107-5d4fmt92g4pomceuedgsva1263ms9lir.apps.googleusercontent.com',
      scopes: [config.scope],
    );
  }

  /// Current authenticated user
  GoogleSignInAccount? get currentUser => _currentUser;
  
  /// Current access token
  String? get accessToken => _accessToken;
  
  /// Drive configuration
  GoogleDriveConfig get config => _config;
  
  /// Check if user is signed in
  bool get isSignedIn => _currentUser != null;
  
  /// Check if authenticated (has user and token)
  bool get isAuthenticated => _currentUser != null && _accessToken != null;

  /// Stream of authentication state changes
  Stream<GoogleSignInAccount?> get onAuthStateChanged => _authStateController.stream;

  /// Initialize auth service
  Future<void> initialize() async {
    try {
      // Listen to sign-in state changes
      _googleSignIn.onCurrentUserChanged.listen((account) {
        _currentUser = account;
        _authStateController.add(account);
        if (account != null) {
          _refreshAccessToken();
        } else {
          _accessToken = null;
        }
      });

      // Try silent sign-in
      await signInSilently();
      if (kDebugMode) print('MobileGoogleAuthService (web): Initialized');
    } catch (e) {
      if (kDebugMode) print('MobileGoogleAuthService (web): Initialize failed: $e');
    }
  }

  /// Initialize auth service (alias for initialize)
  Future<void> initializeAuth() => initialize();

  /// Sign in silently
  Future<bool> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        _currentUser = account;
        await _refreshAccessToken();
        if (kDebugMode) print('MobileGoogleAuthService (web): Silent sign-in successful');
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('MobileGoogleAuthService (web): Silent sign-in failed: $e');
    }
    return false;
  }

  /// Sign in interactively
  Future<bool> signIn() async {
    try {
      if (kDebugMode) print('MobileGoogleAuthService (web): Starting sign-in...');
      final account = await _googleSignIn.signIn();
      if (account != null) {
        _currentUser = account;
        await _refreshAccessToken();
        _authStateController.add(account);
        if (kDebugMode) print('MobileGoogleAuthService (web): Sign-in successful - ${account.email}');
        return true;
      } else {
        if (kDebugMode) print('MobileGoogleAuthService (web): Sign-in returned null (user cancelled?)');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('MobileGoogleAuthService (web): Sign-in failed: $e');
        print('Stack trace: $stackTrace');
      }
    }
    return false;
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _accessToken = null;
      _authStateController.add(null);
      if (kDebugMode) print('MobileGoogleAuthService (web): Signed out');
    } catch (e) {
      if (kDebugMode) print('MobileGoogleAuthService (web): Sign-out failed: $e');
    }
  }

  /// Listen to auth changes
  void listenToAuthChanges(Function(GoogleSignInAccount?) callback) {
    _googleSignIn.onCurrentUserChanged.listen(callback);
  }

  /// Create Drive CRUD client
  Future<GoogleDriveCrudClient?> createDriveClient() async {
    if (_accessToken == null) {
      if (kDebugMode) print('MobileGoogleAuthService (web): No access token available');
      return null;
    }

    try {
      return await GoogleDriveCrudClient.create(
        accessToken: _accessToken!,
        config: _config,
      );
    } catch (e) {
      if (kDebugMode) print('MobileGoogleAuthService (web): Failed to create Drive client: $e');
      return null;
    }
  }

  /// Get fresh access token
  Future<String?> getFreshAccessToken() async {
    await _refreshAccessToken();
    return _accessToken;
  }

  /// Refresh access token from current user
  Future<void> _refreshAccessToken() async {
    if (_currentUser == null) {
      _accessToken = null;
      return;
    }

    try {
      final auth = await _currentUser!.authentication;
      _accessToken = auth.accessToken;
      if (kDebugMode) print('MobileGoogleAuthService (web): Access token refreshed');
    } catch (e) {
      if (kDebugMode) print('MobileGoogleAuthService (web): Failed to refresh token: $e');
      _accessToken = null;
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
