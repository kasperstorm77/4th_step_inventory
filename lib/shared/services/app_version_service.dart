import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../localizations.dart';
import '../utils/platform_helper.dart';
import 'all_apps_drive_service.dart';

/// Service to handle app version tracking and first-run/update scenarios.
/// 
/// On first install or after update, this service can prompt users to:
/// 1. Sign in to Google Drive
/// 2. Fetch existing data from the cloud (if available)
class AppVersionService {
  static const String _boxName = 'app_version';
  static const String _versionKey = 'last_run_version';
  static const String _buildKey = 'last_run_build';

  static Box? _box;

  /// Initialize the version service box
  static Future<void> initialize() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
    }
  }

  /// Get the last version the app was run with
  static String? getLastRunVersion() {
    return _box?.get(_versionKey) as String?;
  }

  /// Get the last build number the app was run with
  static int? getLastRunBuild() {
    return _box?.get(_buildKey) as int?;
  }

  /// Save the current version as the last run version
  static Future<void> saveCurrentVersion(PackageInfo packageInfo) async {
    await _box?.put(_versionKey, packageInfo.version);
    await _box?.put(_buildKey, int.tryParse(packageInfo.buildNumber) ?? 0);
  }

  /// Check if this is a first install (no previous version recorded)
  static bool isFirstInstall() {
    return getLastRunVersion() == null;
  }

  /// Check if the app was just updated (version or build changed)
  static bool wasJustUpdated(PackageInfo packageInfo) {
    final lastVersion = getLastRunVersion();
    final lastBuild = getLastRunBuild();
    
    if (lastVersion == null) return false; // First install, not update
    
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
    return lastVersion != packageInfo.version || lastBuild != currentBuild;
  }

  /// Show dialog offering to fetch data from Google Drive on first install
  static Future<void> showFirstInstallDialog(BuildContext context) async {
    // Check if already signed in
    final allAppsService = AllAppsDriveService.instance;
    final isAuthenticated = allAppsService.isAuthenticated;
    
    if (isAuthenticated) {
      // Already signed in, just offer to fetch
      await _showFetchDialog(context);
    } else {
      // Not signed in, offer to sign in first
      await _showSignInDialog(context);
    }
  }

  /// Show dialog after app update
  static Future<void> showUpdateDialog(BuildContext context, PackageInfo packageInfo) async {
    // Check if already signed in
    final allAppsService = AllAppsDriveService.instance;
    final isAuthenticated = allAppsService.isAuthenticated;
    
    if (isAuthenticated) {
      // Already signed in, offer to fetch latest
      await _showFetchDialog(context, isUpdate: true);
    }
    // If not signed in after update, don't bother them - they probably don't use Drive sync
  }

  /// Show sign-in dialog
  static Future<void> _showSignInDialog(BuildContext context) async {
    if (!context.mounted) return;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(t(context, 'welcomeToTwelveSteps')),
        content: Text(t(context, 'firstInstallSignInPrompt')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t(context, 'skipForNow')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t(context, 'signInToGoogleDrive')),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      // User wants to sign in - redirect to Data Management tab
      // The app should navigate to settings/data management
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(context, 'goToDataManagementToSignIn')),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Show fetch dialog
  static Future<void> _showFetchDialog(BuildContext context, {bool isUpdate = false}) async {
    if (!context.mounted) return;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isUpdate 
          ? t(context, 'appUpdated')
          : t(context, 'welcomeBack')),
        content: Text(isUpdate
          ? t(context, 'updateFetchPrompt')
          : t(context, 'existingDataFetchPrompt')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t(context, 'skipForNow')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t(context, 'fetchFromDrive')),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await _performFetch(context);
    }
  }

  /// Perform the actual fetch from Google Drive
  static Future<void> _performFetch(BuildContext context) async {
    if (!context.mounted) return;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(t(context, 'fetchingFromDrive')),
          ],
        ),
      ),
    );

    try {
      final allAppsService = AllAppsDriveService.instance;
      
      // Enable sync if not already enabled
      if (!allAppsService.syncEnabled) {
        allAppsService.setSyncEnabled(true);
      }
      
      // Fetch from Drive using AllAppsDriveService (empty string = latest/default file)
      await allAppsService.downloadBackupContent('');
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(context, 'dataFetchedSuccessfully')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t(context, 'fetchFailed')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Check if we should prompt the user for a Google Drive fetch
  /// (called by fourth_step_home.dart on startup)
  static Future<bool> shouldPromptGoogleFetch() async {
    // Skip on desktop for now - Drive sync UI is different
    if (PlatformHelper.isDesktop) return false;
    
    await initialize();
    
    final packageInfo = await PackageInfo.fromPlatform();
    
    // Prompt on first install or after update
    if (isFirstInstall() || wasJustUpdated(packageInfo)) {
      // Check if already signed in
      final allAppsService = AllAppsDriveService.instance;
      final isAuthenticated = allAppsService.isAuthenticated;
      
      // Only prompt if authenticated (otherwise they need to sign in via Data Management first)
      return isAuthenticated;
    }
    
    return false;
  }

  /// Show the Google fetch dialog (called by fourth_step_home.dart)
  static Future<void> showGoogleFetchDialog(BuildContext context) async {
    if (!context.mounted) return;
    
    final packageInfo = await PackageInfo.fromPlatform();
    final isUpdate = wasJustUpdated(packageInfo);
    
    await _showFetchDialog(context, isUpdate: isUpdate);
    
    // Always save the current version after showing dialog
    await saveCurrentVersion(packageInfo);
  }

  /// Main entry point - check version and show appropriate dialogs
  static Future<void> checkVersionAndPrompt(BuildContext context) async {
    // Skip on desktop for now - Drive sync UI is different
    if (PlatformHelper.isDesktop) return;
    
    await initialize();
    
    final packageInfo = await PackageInfo.fromPlatform();
    
    if (isFirstInstall()) {
      // First install - offer to sign in and fetch
      if (context.mounted) {
        await showFirstInstallDialog(context);
      }
    } else if (wasJustUpdated(packageInfo)) {
      // App was updated - offer to fetch latest
      if (context.mounted) {
        await showUpdateDialog(context, packageInfo);
      }
    }
    
    // Always save the current version
    await saveCurrentVersion(packageInfo);
  }
}
