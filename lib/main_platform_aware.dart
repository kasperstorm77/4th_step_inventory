//main.dart - Platform-Aware Flutter App
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Import existing files for initialization
import 'models/inventory_entry.dart';
import 'services/drive_service.dart';
import 'services/platform_integration_service.dart';
import 'google_drive_client.dart';

// Import modular app
import 'app/app_module.dart';
import 'app/app_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(InventoryEntryAdapter());

  // Open Hive boxes with error handling
  try {
    await Hive.openBox<InventoryEntry>('entries');
  } catch (e) {
    if (kDebugMode) {
      print('Error opening entries box: $e');
    }
    // If there's corrupted data, clear the box and start fresh
    await Hive.deleteBoxFromDisk('entries');
    await Hive.openBox<InventoryEntry>('entries');
    if (kDebugMode) {
      print('Cleared corrupted entries box and created new one');
    }
  }

  // Open settings box for sync preferences
  await Hive.openBox('settings');

  // Initialize platform services
  try {
    await PlatformIntegrationService.instance.initialize();
    if (kDebugMode) {
      print('Platform services initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Platform services initialization failed: $e');
    }
    // Continue without platform services - app should still work with basic functionality
  }

  // Initialize legacy DriveService for backward compatibility
  // This handles the existing Google Sign-In flow for Android
  try {
    await _initializeLegacyDriveService();
  } catch (e) {
    if (kDebugMode) {
      print('Legacy drive service initialization failed: $e');
    }
  }

  runApp(ModularApp(module: AppModule(), child: const AppWidget()));
}

/// Initialize the legacy DriveService for backward compatibility
/// This handles the existing Google Sign-In flow specifically for Android
Future<void> _initializeLegacyDriveService() async {
  // Only attempt Google Sign-In on Android for now
  final platformService = PlatformIntegrationService.instance.platformServices;
  
  if (!platformService.isAndroid) {
    if (kDebugMode) {
      print('Skipping legacy Google Sign-In for non-Android platform');
    }
    return;
  }

  try {
    // Attempt silent sign-in using the legacy method for backward compatibility
    // This ensures existing users on Android continue to work seamlessly
    
    final scopes = <String>[
      'email', 
      'https://www.googleapis.com/auth/drive.appdata'
    ];
    
    final googleSignIn = GoogleSignIn(scopes: scopes);
    final account = await googleSignIn.signInSilently();
    
    if (account != null) {
      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      
      if (accessToken != null) {
        // Create the legacy GoogleDriveClient for Android
        final client = await GoogleDriveClient.create(account, accessToken);
        
        // Set up the legacy DriveService
        DriveService.instance.setClient(client);
        
        // Load sync state from settings
        final settingsBox = Hive.box('settings');
        final enabled = settingsBox.get('syncEnabled', defaultValue: false) ?? false;
        await DriveService.instance.setSyncEnabled(enabled);
        
        if (kDebugMode) {
          print('Legacy Google Sign-In successful for ${account.displayName}');
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Legacy Google Sign-In failed: $e');
    }
  }
}