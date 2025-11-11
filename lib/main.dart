//main.dart - Flutter Modular Integration
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Import existing files for initialization
import 'models/inventory_entry.dart';
import 'services/drive_service.dart';

import 'google_drive_client.dart';

// Import modular app
import 'app/app_module.dart';
import 'app/app_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(InventoryEntryAdapter());

  try {
    await Hive.openBox<InventoryEntry>('entries');
  } catch (e) {
    print('Error opening entries box: $e');
    // If there's corrupted data, clear the box and start fresh
    await Hive.deleteBoxFromDisk('entries');
    await Hive.openBox<InventoryEntry>('entries');
    print('Cleared corrupted entries box and created new one');
  }

  // Open a separate settings box for sync preferences
  await Hive.openBox('settings');

  // Attempt silent sign-in and initialize Drive client early so CRUD
  // operations can sync without the user opening Settings.
  try {
    final scopes = <String>['email', 'https://www.googleapis.com/auth/drive.appdata'];
    final googleSignIn = GoogleSignIn(scopes: scopes);
    final account = await googleSignIn.signInSilently();
    if (account != null) {
      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      if (accessToken != null) {
        final client = await GoogleDriveClient.create(account, accessToken);
        DriveService.instance.setClient(client);
        // set sync flag from settings box
        final settingsBox = Hive.box('settings');
        final enabled = settingsBox.get('syncEnabled', defaultValue: false) ?? false;
        await DriveService.instance.setSyncEnabled(enabled);
      }
    }
  } catch (e) {
    print('Silent drive init failed: $e');
  }

  runApp(ModularApp(module: AppModule(), child: const AppWidget()));
}
