// --------------------------------------------------------------------------
// Android Platform Services Implementation
// --------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/inventory_entry.dart';
import 'platform_services.dart';

/// Android-specific implementation of platform services
class AndroidPlatformServices implements PlatformServices {
  static AndroidPlatformServices? _instance;
  static AndroidPlatformServices get instance {
    _instance ??= AndroidPlatformServices._();
    return _instance!;
  }

  late final GoogleSignIn _googleSignIn;
  final StreamController<GoogleSignInResult?> _authController = StreamController.broadcast();

  AndroidPlatformServices._() {
    const scopes = <String>[
      'email',
      'https://www.googleapis.com/auth/drive.appdata',
    ];
    _googleSignIn = GoogleSignIn(scopes: scopes);
  }

  @override
  Future<void> initialize() async {
    if (kDebugMode) {
      print('AndroidPlatformServices: Initializing...');
    }

    // Listen to Google Sign-In state changes
    _googleSignIn.onCurrentUserChanged.listen((account) {
      if (account != null) {
        _handleSignInSuccess(account);
      } else {
        _authController.add(null);
      }
    });

    // Attempt silent sign-in during initialization
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        await _handleSignInSuccess(account);
      }
    } catch (e) {
      if (kDebugMode) {
        print('AndroidPlatformServices: Silent sign-in failed: $e');
      }
    }
  }

  @override
  Future<bool> initializeGoogleSignIn() async {
    // Already initialized in constructor
    return true;
  }

  @override
  Future<GoogleSignInResult?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        return await _handleSignInSuccess(account);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('AndroidPlatformServices: Interactive sign-in failed: $e');
      }
      return GoogleSignInResult.failure('Sign-in failed: $e');
    }
  }

  @override
  Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
      _authController.add(null);
    } catch (e) {
      if (kDebugMode) {
        print('AndroidPlatformServices: Sign-out failed: $e');
      }
    }
  }

  @override
  Future<GoogleSignInResult?> attemptSilentSignIn() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        return await _handleSignInSuccess(account);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('AndroidPlatformServices: Silent sign-in failed: $e');
      }
      return null;
    }
  }

  @override
  Stream<GoogleSignInResult?> get onAuthStateChanged => _authController.stream;

  Future<GoogleSignInResult> _handleSignInSuccess(GoogleSignInAccount account) async {
    try {
      final auth = await account.authentication;
      final result = GoogleSignInResult.success(
        displayName: account.displayName ?? 'Unknown User',
        email: account.email,
        accessToken: auth.accessToken,
      );
      _authController.add(result);
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('AndroidPlatformServices: Failed to get auth token: $e');
      }
      final result = GoogleSignInResult.failure('Failed to get authentication token');
      _authController.add(result);
      return result;
    }
  }

  @override
  Future<String?> exportCsvFile(List<InventoryEntry> entries) async {
    try {
      // Convert entries to CSV format
      final List<List<String>> rows = [
        ['Resentment', 'Reason', 'Affect', 'Part', 'Defect'], // Header
      ];

      for (final entry in entries) {
        rows.add([
          entry.safeResentment,
          entry.safeReason,
          entry.safeAffect,
          entry.safePart,
          entry.safeDefect,
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);
      final bytes = utf8.encode(csv);

      // Use Flutter File Dialog to save the file
      final params = SaveFileDialogParams(
        data: bytes,
        fileName: 'inventory_export.csv',
        mimeTypesFilter: ['text/csv'],
      );

      final savedPath = await FlutterFileDialog.saveFile(params: params);
      return savedPath;
    } catch (e) {
      if (kDebugMode) {
        print('AndroidPlatformServices: CSV export failed: $e');
      }
      rethrow;
    }
  }

  @override
  Future<List<InventoryEntry>?> importCsvFile() async {
    try {
      // Use FilePicker to select a CSV file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        return null; // User cancelled
      }

      final path = result.files.single.path!;
      final file = File(path);
      final csvString = await file.readAsString();

      // Parse CSV
      final rows = const CsvToListConverter().convert(csvString, eol: '\\n');
      if (rows.length <= 1) {
        return []; // Empty or header-only file
      }

      // Convert to InventoryEntry objects (skip header row)
      final entries = <InventoryEntry>[];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length >= 5) {
          entries.add(InventoryEntry(
            row[0].toString(),
            row[1].toString(),
            row[2].toString(),
            row[3].toString(),
            row[4].toString(),
          ));
        }
      }

      return entries;
    } catch (e) {
      if (kDebugMode) {
        print('AndroidPlatformServices: CSV import failed: $e');
      }
      rethrow;
    }
  }

  @override
  bool get isAndroid => true;

  @override
  bool get isIOS => false;

  @override
  bool get isWindows => false;

  @override
  bool get isMacOS => false;

  @override
  bool get isLinux => false;

  @override
  bool get isWeb => false;

  @override
  Future<void> dispose() async {
    await _authController.close();
  }
}