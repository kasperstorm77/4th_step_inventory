// --------------------------------------------------------------------------
// Platform Factory - Automatic Platform Detection
// --------------------------------------------------------------------------

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../models/inventory_entry.dart';
import 'platform_services.dart';
import 'android_platform_services.dart';
import 'ios_platform_services.dart';
import 'windows_platform_services.dart';

/// Factory class to create platform-specific services
class PlatformFactory {
  static PlatformServices? _instance;

  /// Get the appropriate platform services instance
  static PlatformServices get instance {
    _instance ??= _createPlatformServices();
    return _instance!;
  }

  /// Create platform-specific services based on the current platform
  static PlatformServices _createPlatformServices() {
    if (kIsWeb) {
      // For web, we could create a separate implementation
      // For now, use a fallback that doesn't support platform features
      if (kDebugMode) {
        print('PlatformFactory: Web platform detected - limited functionality');
      }
      return _createWebFallback();
    }

    // For non-web platforms, detect the actual platform
    if (Platform.isAndroid) {
      if (kDebugMode) {
        print('PlatformFactory: Android platform detected');
      }
      return AndroidPlatformServices.instance;
    } else if (Platform.isIOS) {
      if (kDebugMode) {
        print('PlatformFactory: iOS platform detected (stub implementation)');
      }
      return IOSPlatformServices.instance;
    } else if (Platform.isWindows) {
      if (kDebugMode) {
        print('PlatformFactory: Windows platform detected (stub implementation)');
      }
      return WindowsPlatformServices.instance;
    } else if (Platform.isMacOS) {
      if (kDebugMode) {
        print('PlatformFactory: macOS platform detected (using iOS stub)');
      }
      // macOS can use similar implementation to iOS
      return IOSPlatformServices.instance;
    } else if (Platform.isLinux) {
      if (kDebugMode) {
        print('PlatformFactory: Linux platform detected (using Windows stub)');
      }
      // Linux can use similar implementation to Windows
      return WindowsPlatformServices.instance;
    } else {
      if (kDebugMode) {
        print('PlatformFactory: Unknown platform detected - using fallback');
      }
      return _createWebFallback();
    }
  }

  /// Create a web/fallback implementation with limited functionality
  static PlatformServices _createWebFallback() {
    return _WebFallbackPlatformServices();
  }

  /// Reset the instance (useful for testing)
  static void reset() {
    _instance = null;
  }
}

/// Fallback implementation for web and unknown platforms
class _WebFallbackPlatformServices implements PlatformServices {
  @override
  Future<void> initialize() async {
    if (kDebugMode) {
      print('WebFallbackPlatformServices: Limited functionality available');
    }
  }

  @override
  Future<bool> initializeGoogleSignIn() async => false;

  @override
  Future<GoogleSignInResult?> signInWithGoogle() async {
    return GoogleSignInResult.failure('Google Sign-In not available on this platform');
  }

  @override
  Future<void> signOutFromGoogle() async {}

  @override
  Future<GoogleSignInResult?> attemptSilentSignIn() async => null;

  @override
  Stream<GoogleSignInResult?> get onAuthStateChanged => const Stream.empty();

  @override
  Future<String?> exportCsvFile(List<InventoryEntry> entries) async {
    throw UnimplementedError('File export not available on this platform');
  }

  @override
  Future<List<InventoryEntry>?> importCsvFile() async {
    throw UnimplementedError('File import not available on this platform');
  }

  @override
  bool get isAndroid => false;

  @override
  bool get isIOS => false;

  @override
  bool get isWindows => false;

  @override
  bool get isMacOS => false;

  @override
  bool get isLinux => false;

  @override
  bool get isWeb => kIsWeb;

  @override
  Future<void> dispose() async {}
}