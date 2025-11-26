// --------------------------------------------------------------------------
// Mobile Google Drive Service - Web Implementation
// --------------------------------------------------------------------------
// 
// PLATFORM SUPPORT: Web only
// Uses OAuth2 for Google Drive sync on web
// --------------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'drive_config.dart';
import 'mobile_google_auth_service_web.dart';
import '../google_drive_client.dart';

/// Web implementation with full Drive sync support
class MobileDriveService {
  final MobileGoogleAuthService _authService;
  GoogleDriveClient? _driveClient;
  bool _syncEnabled;
  Timer? _uploadTimer;
  String? _pendingUpload;
  final Duration _uploadDelay;
  
  // Events
  final StreamController<bool> _syncStateController = StreamController.broadcast();
  final StreamController<String> _uploadController = StreamController.broadcast();
  final StreamController<String> _downloadController = StreamController.broadcast();
  final StreamController<String> _errorController = StreamController.broadcast();

  MobileDriveService({
    required GoogleDriveConfig config,
    bool syncEnabled = false,
    Duration uploadDelay = const Duration(milliseconds: 700),
  })  : _syncEnabled = syncEnabled,
        _uploadDelay = uploadDelay,
        _authService = MobileGoogleAuthService(config: config);

  // Getters
  bool get syncEnabled => _syncEnabled;
  bool get isAuthenticated => _authService.isAuthenticated;
  MobileGoogleAuthService get authService => _authService;
  
  // Streams
  Stream<bool> get onSyncStateChanged => _syncStateController.stream;
  Stream<String> get onUpload => _uploadController.stream;
  Stream<String> get onDownload => _downloadController.stream;
  Stream<String> get onError => _errorController.stream;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      await _authService.initialize();
      if (_authService.isAuthenticated && _authService.accessToken != null) {
        // Web: GoogleSignInAccount not used, pass dynamic null
        _driveClient = await GoogleDriveClient.create(null as dynamic, _authService.accessToken!);
        if (kDebugMode) print('MobileDriveService (web): Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) print('MobileDriveService (web): Initialize failed: $e');
      _errorController.add('Initialization failed: $e');
    }
  }

  /// Sign in to Google
  Future<bool> signIn() async {
    try {
      final success = await _authService.signIn();
      if (success && _authService.accessToken != null) {
        // Web: GoogleSignInAccount not used, pass dynamic null
        _driveClient = await GoogleDriveClient.create(null as dynamic, _authService.accessToken!);
        if (kDebugMode) print('MobileDriveService (web): Sign-in successful');
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('MobileDriveService (web): Sign-in failed: $e');
      _errorController.add('Sign-in failed: $e');
    }
    return false;
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _driveClient = null;
      setSyncEnabled(false);
      if (kDebugMode) print('MobileDriveService (web): Signed out');
    } catch (e) {
      if (kDebugMode) print('MobileDriveService (web): Sign-out failed: $e');
      _errorController.add('Sign-out failed: $e');
    }
  }

  /// Enable or disable sync
  void setSyncEnabled(bool enabled) {
    _syncEnabled = enabled;
    _syncStateController.add(enabled);
  }

  /// Upload content to Drive
  Future<void> uploadContent(String content) async {
    if (!syncEnabled || !isAuthenticated || _driveClient == null) {
      if (kDebugMode) print('MobileDriveService (web): Upload skipped - not authenticated');
      return;
    }

    try {
      await _driveClient!.uploadFile(content);
      _uploadController.add(content);
      if (kDebugMode) print('MobileDriveService (web): Upload successful');
    } catch (e) {
      if (kDebugMode) print('MobileDriveService (web): Upload failed: $e');
      _errorController.add('Upload failed: $e');
      rethrow;
    }
  }

  /// Schedule upload with debounce
  void scheduleUpload(String content) {
    _pendingUpload = content;
    _uploadTimer?.cancel();
    _uploadTimer = Timer(_uploadDelay, () {
      if (_pendingUpload != null) {
        uploadContent(_pendingUpload!).catchError((e) {
          if (kDebugMode) print('Scheduled upload failed: $e');
        });
        _pendingUpload = null;
      }
    });
  }

  /// Cancel scheduled upload
  void cancelScheduledUpload() {
    _uploadTimer?.cancel();
    _pendingUpload = null;
  }

  /// Download content from Drive
  Future<String?> downloadContent() async {
    if (!isAuthenticated || _driveClient == null) {
      if (kDebugMode) print('MobileDriveService (web): Download skipped - not authenticated');
      return null;
    }

    try {
      final content = await _driveClient!.downloadFile();
      if (content != null) {
        _downloadController.add(content);
        if (kDebugMode) print('MobileDriveService (web): Download successful');
      }
      return content;
    } catch (e) {
      if (kDebugMode) print('MobileDriveService (web): Download failed: $e');
      _errorController.add('Download failed: $e');
      rethrow;
    }
  }

  /// List available backup restore points (not implemented for web yet)
  Future<List<Map<String, dynamic>>> listAvailableBackups() async {
    if (kDebugMode) print('MobileDriveService (web): Backups not yet implemented');
    return [];
  }

  /// Download specific backup file content (not implemented for web yet)
  Future<String?> downloadBackupContent(String fileName) async {
    if (kDebugMode) print('MobileDriveService (web): Backup download not yet implemented');
    return null;
  }

  /// Check if file exists on Drive
  Future<bool> fileExists() async {
    if (!isAuthenticated || _driveClient == null) return false;
    
    try {
      final content = await _driveClient!.downloadFile();
      return content != null;
    } catch (e) {
      return false;
    }
  }

  /// Delete content from Drive
  Future<bool> deleteContent() async {
    if (!isAuthenticated || _driveClient == null) {
      if (kDebugMode) print('MobileDriveService (web): Delete skipped - not authenticated');
      return false;
    }

    try {
      await _driveClient!.deleteFile();
      if (kDebugMode) print('MobileDriveService (web): Delete successful');
      return true;
    } catch (e) {
      if (kDebugMode) print('MobileDriveService (web): Delete failed: $e');
      _errorController.add('Delete failed: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _uploadTimer?.cancel();
    _syncStateController.close();
    _uploadController.close();
    _downloadController.close();
    _errorController.close();
  }
}
