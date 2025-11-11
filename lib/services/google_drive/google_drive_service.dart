import 'dart:async';
import 'package:flutter/foundation.dart';
import 'drive_config.dart';
import 'drive_crud_client.dart';
import 'google_auth_service.dart';

// --------------------------------------------------------------------------
// Generic Google Drive Service - Reusable Business Logic
// --------------------------------------------------------------------------

/// High-level Google Drive service with business logic
/// Generic and reusable across different projects
class GoogleDriveService {
  final GoogleAuthService _authService;
  
  GoogleDriveCrudClient? _driveClient;
  bool _syncEnabled;
  
  // Debouncing for uploads
  Timer? _uploadTimer;
  final Duration _uploadDelay;

  // Events
  final StreamController<bool> _syncStateController = StreamController.broadcast();
  final StreamController<String> _uploadController = StreamController.broadcast();
  final StreamController<String> _downloadController = StreamController.broadcast();
  final StreamController<String> _errorController = StreamController.broadcast();

  GoogleDriveService({
    required GoogleDriveConfig config,
    bool syncEnabled = false,
    Duration uploadDelay = const Duration(milliseconds: 700),
  })  : _syncEnabled = syncEnabled,
        _uploadDelay = uploadDelay,
        _authService = GoogleAuthService(config: config);

  // Getters
  bool get syncEnabled => _syncEnabled;
  bool get isAuthenticated => _authService.isSignedIn;
  GoogleAuthService get authService => _authService;
  
  // Streams
  Stream<bool> get onSyncStateChanged => _syncStateController.stream;
  Stream<String> get onUpload => _uploadController.stream;
  Stream<String> get onDownload => _downloadController.stream;
  Stream<String> get onError => _errorController.stream;

  /// Initialize the service
  Future<void> initialize() async {
    await _authService.initializeAuth();
    if (_authService.isSignedIn) {
      await _createDriveClient();
    }
    
    // Listen to auth changes
    _authService.listenToAuthChanges((account) async {
      if (account != null) {
        await _createDriveClient();
      } else {
        _driveClient = null;
      }
    });
  }

  /// Sign in to Google
  Future<bool> signIn() async {
    final success = await _authService.signIn();
    if (success) {
      await _createDriveClient();
    }
    return success;
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _driveClient = null;
    setSyncEnabled(false);
  }

  /// Enable or disable sync
  void setSyncEnabled(bool enabled) {
    _syncEnabled = enabled;
    _syncStateController.add(enabled);
  }

  /// Upload content to Drive
  Future<void> uploadContent(String content) async {
    if (!_syncEnabled) {
      return;
    }

    if (_driveClient == null) {
      if (!await _ensureAuthenticated()) {
        _errorController.add('Upload failed - not authenticated');
        return;
      }
    }

    try {
      await _driveClient!.upsertFile(content);
      _uploadController.add('Upload successful');
    } catch (e) {
      final errorMsg = 'Upload failed: $e';
      _errorController.add(errorMsg);
      rethrow;
    }
  }

  /// Download content from Drive
  Future<String?> downloadContent() async {
    if (_driveClient == null) {
      if (!await _ensureAuthenticated()) {
        _errorController.add('Download failed - not authenticated');
        return null;
      }
    }

    try {
      final content = await _driveClient!.readFileContent();
      if (content != null) {
        _downloadController.add('Download successful');
        if (kDebugMode) print('Drive download successful');
      }
      return content;
    } catch (e) {
      final errorMsg = 'Download failed: $e';
      _errorController.add(errorMsg);
      if (kDebugMode) print(errorMsg);
      rethrow;
    }
  }

  /// Delete file from Drive
  Future<bool> deleteContent() async {
    if (_driveClient == null) {
      if (!await _ensureAuthenticated()) {
        _errorController.add('Delete failed - not authenticated');
        return false;
      }
    }

    try {
      final deleted = await _driveClient!.deleteFileByName();
      if (deleted && kDebugMode) print('Drive file deleted');
      return deleted;
    } catch (e) {
      final errorMsg = 'Delete failed: $e';
      _errorController.add(errorMsg);
      if (kDebugMode) print(errorMsg);
      return false;
    }
  }

  /// Schedule debounced upload
  void scheduleUpload(String content) {
    _uploadTimer?.cancel();
    _uploadTimer = Timer(_uploadDelay, () {
      uploadContent(content);
    });
  }

  /// Check if file exists on Drive
  Future<bool> fileExists() async {
    if (_driveClient == null) {
      if (!await _ensureAuthenticated()) return false;
    }

    try {
      return await _driveClient!.fileExists();
    } catch (e) {
      if (kDebugMode) print('File exists check failed: $e');
      return false;
    }
  }

  /// Create Drive client if authenticated
  Future<void> _createDriveClient() async {
    try {
      _driveClient = await _authService.createDriveClient();
    } catch (e) {
      if (kDebugMode) print('Failed to create Drive client: $e');
    }
  }

  /// Ensure user is authenticated
  Future<bool> _ensureAuthenticated() async {
    if (_authService.isSignedIn) {
      if (_driveClient == null) {
        await _createDriveClient();
      }
      return _driveClient != null;
    }
    return false;
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