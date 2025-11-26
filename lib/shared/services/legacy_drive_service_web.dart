// --------------------------------------------------------------------------
// Legacy Drive Service - Web Stub
// --------------------------------------------------------------------------
// 
// PLATFORM SUPPORT: Web only
// This is a stub implementation for web platform where Google Drive sync
// is not supported yet. All methods are no-ops.
// 
// Future: Implement proper OAuth2 + Drive API for web when needed.
// --------------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'google_drive_client.dart';

/// Legacy Drive Service - Web stub implementation
class DriveService {
  static final DriveService _instance = DriveService._internal();
  
  static DriveService get instance => _instance;
  
  DriveService._internal();

  GoogleDriveClient? _client;
  bool _syncEnabled = false;

  final StreamController<int> _uploadCountController = StreamController<int>.broadcast();
  Stream<int> get onUpload => _uploadCountController.stream;

  /// Get the current Drive client (always null on web)
  GoogleDriveClient? get client => _client;
  
  /// Check if sync is enabled
  bool get syncEnabled => _syncEnabled;

  /// Set the Drive client (no-op on web)
  void setClient(GoogleDriveClient? client) {
    _client = client;
    if (kDebugMode) {
      print('DriveService (web): Client setting not supported on web platform');
    }
  }

  /// Get the current Drive client (always null on web)
  GoogleDriveClient? getClient() => _client;

  /// Enable or disable sync
  Future<void> setSyncEnabled(bool enabled) async {
    _syncEnabled = enabled;
  }

  /// Check if sync is enabled
  bool isSyncEnabled() => _syncEnabled;

  /// Upload data to Drive (no-op on web)
  Future<void> uploadData(String jsonData) async {
    if (kDebugMode) {
      print('DriveService (web): Upload not supported on web platform');
    }
  }

  /// Download data from Drive (returns null on web)
  Future<String?> downloadData() async {
    if (kDebugMode) {
      print('DriveService (web): Download not supported on web platform');
    }
    return null;
  }

  /// Download file from Drive (alias for downloadData, returns null on web)
  Future<String?> downloadFile() async {
    if (kDebugMode) {
      print('DriveService (web): Download file not supported on web platform');
    }
    return null;
  }

  /// List available backup restore points (returns empty list on web)
  Future<List<Map<String, dynamic>>> listAvailableBackups() async {
    if (kDebugMode) {
      print('DriveService (web): Backups not supported on web platform');
    }
    return [];
  }

  /// Download specific backup file content (returns null on web)
  Future<String?> downloadBackupContent(String fileName) async {
    if (kDebugMode) {
      print('DriveService (web): Backup download not supported on web platform');
    }
    return null;
  }

  /// Check if file exists on Drive (returns false on web)
  Future<bool> fileExists() async {
    return false;
  }

  /// Delete file from Drive (no-op on web)
  Future<void> deleteFile() async {
    if (kDebugMode) {
      print('DriveService (web): Delete not supported on web platform');
    }
  }

  /// Clear the Drive client (no-op on web)
  void clearClient() {
    _client = null;
    if (kDebugMode) {
      print('DriveService (web): Clear client not supported on web platform');
    }
  }

  /// Upload from box with UI notification (no-op on web)
  Future<void> uploadFromBoxWithNotification(dynamic box) async {
    if (kDebugMode) {
      print('DriveService (web): Upload with notification not supported on web platform');
    }
  }

  /// Schedule debounced upload from box (no-op on web)
  void scheduleUploadFromBox(dynamic box) {
    if (kDebugMode) {
      print('DriveService (web): Schedule upload not supported on web platform');
    }
  }

  /// Load sync state from storage (no-op on web)
  Future<void> loadSyncState() async {
    if (kDebugMode) {
      print('DriveService (web): Load sync state not supported on web platform');
    }
  }

  /// Notify upload count
  void notifyUploadCount(int count) {
    _uploadCountController.add(count);
  }

  /// Dispose resources
  void dispose() {
    _uploadCountController.close();
  }
}
