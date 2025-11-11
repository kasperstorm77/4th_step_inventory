// --------------------------------------------------------------------------
// Platform Integration Service
// --------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import '../models/inventory_entry.dart';
import '../platform/platform_services_export.dart';
import '../services/drive_service.dart';

/// Service to integrate platform services with existing app architecture
class PlatformIntegrationService {
  static PlatformIntegrationService? _instance;
  static PlatformIntegrationService get instance {
    _instance ??= PlatformIntegrationService._();
    return _instance!;
  }

  late final PlatformServices _platformServices;
  GoogleSignInResult? _currentUser;
  
  PlatformIntegrationService._() {
    _platformServices = PlatformFactory.instance;
  }

  /// Initialize the platform integration
  Future<void> initialize() async {
    try {
      await _platformServices.initialize();
      
      // Listen to auth state changes and bridge to existing DriveService
      _platformServices.onAuthStateChanged.listen(_handleAuthStateChange);
      
      // Attempt silent sign-in for supported platforms
      if (_platformServices.isAndroid || _platformServices.isIOS) {
        final result = await _platformServices.attemptSilentSignIn();
        if (result?.isSuccess == true) {
          await _handleAuthStateChange(result);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('PlatformIntegrationService: Initialization failed: $e');
      }
    }
  }

  /// Handle authentication state changes
  Future<void> _handleAuthStateChange(GoogleSignInResult? result) async {
    _currentUser = result;
    
    if (result?.isSuccess == true && result?.accessToken != null) {
      // For Android, we can create the GoogleDriveClient
      if (_platformServices.isAndroid) {
        try {
          // Note: This is a bridge implementation
          // In practice, we'd need to extract the GoogleSignInAccount from the platform service
          // For now, this shows the integration pattern
          
          if (kDebugMode) {
            print('PlatformIntegrationService: User signed in: ${result!.displayName}');
          }
          
          // TODO: Create platform-agnostic drive client
          // This would need the actual GoogleSignInAccount which we'd need to store
          // in the AndroidPlatformServices implementation
          
        } catch (e) {
          if (kDebugMode) {
            print('PlatformIntegrationService: Failed to create drive client: $e');
          }
        }
      }
    } else {
      // User signed out or sign-in failed
      DriveService.instance.clearClient();
    }
  }

  /// Get current user information
  GoogleSignInResult? get currentUser => _currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _currentUser?.isSuccess == true;

  /// Get platform services
  PlatformServices get platformServices => _platformServices;

  /// Sign in with Google (delegated to platform service)
  Future<GoogleSignInResult?> signIn() async {
    return await _platformServices.signInWithGoogle();
  }

  /// Sign out (delegated to platform service)
  Future<void> signOut() async {
    await _platformServices.signOutFromGoogle();
  }

  /// Export CSV (delegated to platform service)
  Future<String?> exportCsv(List<InventoryEntry> entries) async {
    return await _platformServices.exportCsvFile(entries);
  }

  /// Import CSV (delegated to platform service)
  Future<List<InventoryEntry>?> importCsv() async {
    return await _platformServices.importCsvFile();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _platformServices.dispose();
  }
}