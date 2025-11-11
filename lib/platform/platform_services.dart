// --------------------------------------------------------------------------
// Platform Services Interface
// --------------------------------------------------------------------------

import 'dart:async';
import '../models/inventory_entry.dart';

/// Abstract interface for platform-specific services
abstract class PlatformServices {
  /// Google Sign-In functionality
  Future<bool> initializeGoogleSignIn();
  Future<GoogleSignInResult?> signInWithGoogle();
  Future<void> signOutFromGoogle();
  Future<GoogleSignInResult?> attemptSilentSignIn();
  Stream<GoogleSignInResult?> get onAuthStateChanged;
  
  /// File operations
  Future<String?> exportCsvFile(List<InventoryEntry> entries);
  Future<List<InventoryEntry>?> importCsvFile();
  
  /// Platform identification
  bool get isAndroid;
  bool get isIOS;
  bool get isWindows;
  bool get isMacOS;
  bool get isLinux;
  bool get isWeb;
  
  /// Platform-specific initialization
  Future<void> initialize();
  
  /// Clean up resources
  Future<void> dispose();
}

/// Result from Google Sign-In operations
class GoogleSignInResult {
  final String displayName;
  final String email;
  final String? accessToken;
  final bool isSuccess;
  final String? errorMessage;

  const GoogleSignInResult({
    required this.displayName,
    required this.email,
    this.accessToken,
    required this.isSuccess,
    this.errorMessage,
  });

  factory GoogleSignInResult.success({
    required String displayName,
    required String email,
    String? accessToken,
  }) {
    return GoogleSignInResult(
      displayName: displayName,
      email: email,
      accessToken: accessToken,
      isSuccess: true,
    );
  }

  factory GoogleSignInResult.failure(String errorMessage) {
    return GoogleSignInResult(
      displayName: '',
      email: '',
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}