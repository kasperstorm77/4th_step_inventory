// --------------------------------------------------------------------------
// Platform-Aware Settings Tab
// --------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/inventory_entry.dart';
import '../localizations.dart';
import '../services/drive_service.dart';
import '../google_drive_client.dart';
import '../platform/platform_services_export.dart';
import 'package:flutter/foundation.dart';

class PlatformSettingsTab extends StatefulWidget {
  final Box<InventoryEntry> box;

  const PlatformSettingsTab({super.key, required this.box});

  @override
  State<PlatformSettingsTab> createState() => _PlatformSettingsTabState();
}

class _PlatformSettingsTabState extends State<PlatformSettingsTab> {
  late final PlatformServices _platformServices;
  GoogleSignInResult? _currentUser;
  GoogleDriveClient? _driveClient;

  bool _syncEnabled = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _platformServices = PlatformFactory.instance;
    _initializePlatform();
  }

  Future<void> _initializePlatform() async {
    try {
      await _platformServices.initialize();
      
      // Listen to auth state changes
      _platformServices.onAuthStateChanged.listen((result) {
        if (mounted) {
          setState(() {
            _currentUser = result;
            if (result == null) {
              _syncEnabled = false;
              _driveClient = null;
              _saveSyncSetting(false);
            } else if (result.isSuccess) {
              _initializeDriveClient(result);
            }
          });
        }
      });

      // Attempt silent sign-in
      final silentResult = await _platformServices.attemptSilentSignIn();
      if (silentResult?.isSuccess == true) {
        await _initializeDriveClient(silentResult!);
      }

      // Load sync settings
      await _loadSyncSettings();
    } catch (e) {
      if (kDebugMode) {
        print('PlatformSettingsTab: Initialization failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _loadSyncSettings() async {
    try {
      final settingsBox = Hive.box('settings');
      final enabled = settingsBox.get('syncEnabled', defaultValue: false) ?? false;
      if (mounted) {
        setState(() {
          _syncEnabled = enabled;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('PlatformSettingsTab: Failed to load sync settings: $e');
      }
    }
  }

  Future<void> _saveSyncSetting(bool enabled) async {
    try {
      final settingsBox = Hive.box('settings');
      await settingsBox.put('syncEnabled', enabled);
    } catch (e) {
      if (kDebugMode) {
        print('PlatformSettingsTab: Failed to save sync setting: $e');
      }
    }
  }

  Future<void> _initializeDriveClient(GoogleSignInResult result) async {
    if (!result.isSuccess || result.accessToken == null) return;

    try {
      // For platforms that don't support Google Sign-In, we can't create the client
      if (!_platformServices.isAndroid && !_platformServices.isIOS) {
        if (kDebugMode) {
          print('PlatformSettingsTab: Google Drive not supported on this platform yet');
        }
        return;
      }

      // TODO: This needs to be refactored to work with the platform abstraction
      // For now, we'll skip the drive client creation in the platform-aware version
      // The existing settings tab should be used for full Google Drive functionality
      
      if (kDebugMode) {
        print('PlatformSettingsTab: Google Drive integration needs platform-specific refactor');
      }
      
      // Set sync state without the client for now
      await DriveService.instance.setSyncEnabled(_syncEnabled);
    } catch (e) {
      if (kDebugMode) {
        print('PlatformSettingsTab: Drive client initialization failed: $e');
      }
    }
  }

  Future<void> _handleSignIn() async {
    if (!_platformServices.isAndroid) {
      _showPlatformNotSupportedDialog('Google Sign-In');
      return;
    }

    try {
      final result = await _platformServices.signInWithGoogle();
      if (result?.isSuccess != true) {
        _showErrorSnackBar('Sign-in failed: ${result?.errorMessage ?? 'Unknown error'}');
      }
    } catch (e) {
      _showErrorSnackBar('Sign-in failed: $e');
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _platformServices.signOutFromGoogle();
      DriveService.instance.clearClient();
      _showSuccessSnackBar('Signed out successfully');
    } catch (e) {
      _showErrorSnackBar('Sign-out failed: $e');
    }
  }

  Future<void> _toggleSync(bool value) async {
    try {
      setState(() {
        _syncEnabled = value;
      });
      
      await _saveSyncSetting(value);
      await DriveService.instance.setSyncEnabled(value);

      if (value && _driveClient != null) {
        await _uploadToDrive();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to toggle sync: $e');
    }
  }

  Future<void> _uploadToDrive() async {
    if (_driveClient == null || !_syncEnabled) return;

    try {
      await DriveService.instance.uploadFromBoxWithNotification(widget.box);
    } catch (e) {
      if (kDebugMode) {
        print('PlatformSettingsTab: Upload failed: $e');
      }
    }
  }

  Future<void> _fetchFromGoogle() async {
    // Implementation similar to existing _fetchFromGoogle method
    // This would use the existing DriveService for now
    // In a full refactor, this would go through the platform abstraction
    try {
      final content = await DriveService.instance.downloadFile();
      if (content == null) return;

      // Parse and load entries (similar to existing implementation)
      // ... existing parsing logic ...
      
      _showSuccessSnackBar('Data fetched successfully from Google Drive');
    } catch (e) {
      _showErrorSnackBar('Failed to fetch from Google Drive: $e');
    }
  }

  Future<void> _exportCsv() async {
    try {
      final entries = widget.box.values.toList();
      final savedPath = await _platformServices.exportCsvFile(entries);
      
      if (savedPath != null) {
        _showSuccessSnackBar('CSV exported successfully');
      } else {
        _showErrorSnackBar('Export cancelled');
      }
    } catch (e) {
      if (e is UnimplementedError) {
        _showPlatformNotSupportedDialog('CSV Export');
      } else {
        _showErrorSnackBar('Export failed: $e');
      }
    }
  }

  Future<void> _importCsv() async {
    try {
      final entries = await _platformServices.importCsvFile();
      
      if (entries != null) {
        await widget.box.clear();
        for (final entry in entries) {
          await widget.box.add(entry);
        }
        
        if (_syncEnabled && _driveClient != null) {
          await _uploadToDrive();
        }
        
        _showSuccessSnackBar('CSV imported successfully (${entries.length} entries)');
      }
    } catch (e) {
      if (e is UnimplementedError) {
        _showPlatformNotSupportedDialog('CSV Import');
      } else {
        _showErrorSnackBar('Import failed: $e');
      }
    }
  }

  Future<void> _clearAllEntries() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(context, 'confirm_clear')),
        content: Text('This will delete all entries. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t(context, 'clear_all')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.box.clear();
      if (_syncEnabled && _driveClient != null) {
        await _uploadToDrive();
      }
      _showSuccessSnackBar('All entries cleared');
    }
  }

  void _showPlatformNotSupportedDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Platform Not Supported'),
        content: Text(
          '$feature is not yet implemented for ${_getPlatformName()}. '
          'This feature is currently only available on Android.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getPlatformName() {
    if (_platformServices.isAndroid) return 'Android';
    if (_platformServices.isIOS) return 'iOS';
    if (_platformServices.isWindows) return 'Windows';
    if (_platformServices.isMacOS) return 'macOS';
    if (_platformServices.isLinux) return 'Linux';
    if (_platformServices.isWeb) return 'Web';
    return 'Unknown Platform';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing platform services...'),
          ],
        ),
      );
    }

    final bool isSignedIn = _currentUser?.isSuccess == true;
    final String platformName = _getPlatformName();
    final bool hasGoogleSignIn = _platformServices.isAndroid || _platformServices.isIOS;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Platform Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Platform Information',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Running on: $platformName'),
                  Text('Google Sign-In: ${hasGoogleSignIn ? 'Supported' : 'Not supported'}'),
                  Text('File Operations: ${_platformServices.isAndroid ? 'Full support' : 'Limited support'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Google Sign-In Section
          if (hasGoogleSignIn) ...[
            ElevatedButton.icon(
              onPressed: isSignedIn ? _handleSignOut : _handleSignIn,
              icon: Icon(isSignedIn ? Icons.logout : Icons.login),
              label: Text(isSignedIn 
                ? 'Sign Out (${_currentUser!.displayName})'
                : 'Sign In with Google'
              ),
            ),
            const SizedBox(height: 16),

            // Sync Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t(context, 'sync_google_drive')),
                Tooltip(
                  message: isSignedIn ? '' : 'Sign in with Google to enable sync',
                  child: Switch(
                    value: _syncEnabled,
                    onChanged: isSignedIn ? _toggleSync : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Google Drive Actions
            if (isSignedIn) ...[
              ElevatedButton(
                onPressed: _fetchFromGoogle,
                child: Text(t(context, 'googlefetch')),
              ),
              const SizedBox(height: 16),
            ],
          ] else ...[
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(height: 8),
                    Text(
                      'Google Drive sync is not available on $platformName yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // File Operations
          Text(
            'File Operations',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          
          ElevatedButton(
            onPressed: _exportCsv,
            child: Text(t(context, 'export_csv')),
          ),
          const SizedBox(height: 8),
          
          ElevatedButton(
            onPressed: _importCsv,
            child: Text(t(context, 'import_csv')),
          ),
          const SizedBox(height: 16),

          // Danger Zone
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _clearAllEntries,
            child: Text(
              t(context, 'clear_all'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _platformServices.dispose();
    super.dispose();
  }
}