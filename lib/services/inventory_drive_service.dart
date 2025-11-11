import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/inventory_entry.dart';
import '../utils/sync_utils.dart';
import 'google_drive/drive_config.dart';
import 'google_drive/google_drive_service.dart';

// --------------------------------------------------------------------------
// App-Specific Inventory Drive Service
// --------------------------------------------------------------------------

/// App-specific Google Drive service for inventory data
/// Uses the generic GoogleDriveService with inventory-specific logic
class InventoryDriveService {
  static InventoryDriveService? _instance;
  static InventoryDriveService get instance {
    _instance ??= InventoryDriveService._();
    return _instance!;
  }

  late final GoogleDriveService _driveService;
  final StreamController<int> _uploadCountController = StreamController<int>.broadcast();

  InventoryDriveService._() {
    // Configure for inventory app
    const config = GoogleDriveConfig(
      fileName: 'aa4step_inventory_data.json',
      mimeType: 'application/json',
      scope: 'https://www.googleapis.com/auth/drive.appdata',
      parentFolder: 'appDataFolder',
    );

    _driveService = GoogleDriveService(config: config);
    
    // Note: We don't auto-listen to all upload events anymore
    // UI notifications are only triggered for user-initiated actions
  }

  // Expose underlying service properties
  bool get syncEnabled => _driveService.syncEnabled;
  bool get isAuthenticated => _driveService.isAuthenticated;
  Stream<bool> get onSyncStateChanged => _driveService.onSyncStateChanged;
  Stream<int> get onUpload => _uploadCountController.stream;
  Stream<String> get onError => _driveService.onError;

  /// Initialize the service
  Future<void> initialize() async {
    await _driveService.initialize();
    await _loadSyncState();
  }

  /// Sign in to Google
  Future<bool> signIn() => _driveService.signIn();

  /// Sign out from Google  
  Future<void> signOut() async {
    await _driveService.signOut();
    await _saveSyncState(false);
  }

  /// Enable/disable sync
  Future<void> setSyncEnabled(bool enabled) async {
    _driveService.setSyncEnabled(enabled);
    await _saveSyncState(enabled);
  }

  /// Upload raw content directly
  Future<void> uploadContent(String content) async {
    await _driveService.uploadContent(content);
  }

  /// Upload inventory entries from Hive box
  Future<void> uploadFromBox(Box<InventoryEntry> box, {bool notifyUI = false}) async {
    if (!syncEnabled || !isAuthenticated) {
      return;
    }

    try {
      // Serialize entries in background isolate
      final jsonString = await compute(
        serializeEntries,
        box.values.map((e) => {
          'resentment': e.resentment,
          'reason': e.reason,
          'affect': e.affect,
          'part': e.part,
          'defect': e.defect,
        }).toList(),
      );

      await _driveService.uploadContent(jsonString);
      
      // Only notify UI for user-initiated uploads
      if (notifyUI) {
        _notifyUploadCount();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Schedule debounced upload from box (background sync - no UI notifications)
  void scheduleUploadFromBox(Box<InventoryEntry> box) {
    if (!syncEnabled || !isAuthenticated) return;

    // Serialize entries for upload
    final entries = box.values.map((e) => {
      'resentment': e.resentment,
      'reason': e.reason,
      'affect': e.affect,
      'part': e.part,
      'defect': e.defect,
    }).toList();

    // Use compute for serialization, then schedule upload
    // Note: This is background sync, so no UI notifications are triggered
    compute(serializeEntries, entries).then((jsonString) {
      _driveService.scheduleUpload(jsonString);
    }).catchError((e) {
      // Serialization failed, upload will be skipped
    });
  }

  /// Upload from box with UI notification (for user-initiated actions)
  Future<void> uploadFromBoxWithNotification(Box<InventoryEntry> box) async {
    await uploadFromBox(box, notifyUI: true);
  }

  /// Download and restore inventory entries
  Future<List<InventoryEntry>?> downloadEntries() async {
    if (!isAuthenticated) {
      if (kDebugMode) print('InventoryDriveService: Download skipped - not authenticated');
      return null;
    }

    try {
      final content = await _driveService.downloadContent();
      if (content == null) return null;

      return await _parseInventoryContent(content);
    } catch (e) {
      if (kDebugMode) print('InventoryDriveService: Download failed - $e');
      rethrow;
    }
  }

  /// Check if inventory file exists on Drive
  Future<bool> inventoryFileExists() => _driveService.fileExists();

  /// Delete inventory file from Drive
  Future<bool> deleteInventoryFile() => _driveService.deleteContent();

  /// Parse downloaded content into InventoryEntry objects
  Future<List<InventoryEntry>> _parseInventoryContent(String content) async {
    return compute(_parseInventoryJson, content);
  }

  /// Load sync state from Hive
  Future<void> _loadSyncState() async {
    try {
      final settingsBox = await Hive.openBox('settings');
      final enabled = settingsBox.get('syncEnabled', defaultValue: false) ?? false;
      _driveService.setSyncEnabled(enabled);
    } catch (e) {
      if (kDebugMode) print('InventoryDriveService: Failed to load sync state - $e');
    }
  }

  /// Save sync state to Hive
  Future<void> _saveSyncState(bool enabled) async {
    try {
      final settingsBox = await Hive.openBox('settings');
      await settingsBox.put('syncEnabled', enabled);
    } catch (e) {
      if (kDebugMode) print('InventoryDriveService: Failed to save sync state - $e');
    }
  }

  /// Notify upload count to listeners
  void _notifyUploadCount() {
    try {
      if (Hive.isBoxOpen('entries')) {
        final box = Hive.box<InventoryEntry>('entries');
        _uploadCountController.add(box.length);
      }
    } catch (e) {
      if (kDebugMode) print('InventoryDriveService: Failed to get entries count - $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _driveService.dispose();
    _uploadCountController.close();
  }
}

// --------------------------------------------------------------------------
// Static parsing function for compute isolate
// --------------------------------------------------------------------------

/// Parse JSON content into InventoryEntry list (runs in isolate)  
List<InventoryEntry> _parseInventoryJson(String content) {
  try {
    final decoded = json.decode(content) as Map<String, dynamic>;
    
    final entries = decoded['entries'] as List<dynamic>?;
    if (entries == null) return [];

    return entries
        .cast<Map<String, dynamic>>()
        .map((item) => InventoryEntry(
              item['resentment']?.toString() ?? '',
              item['reason']?.toString() ?? '',
              item['affect']?.toString() ?? '',
              item['part']?.toString() ?? '',
              item['defect']?.toString() ?? '',
            ))
        .toList();
  } catch (e) {
    if (kDebugMode) print('Failed to parse inventory JSON: $e');
    return [];
  }
}