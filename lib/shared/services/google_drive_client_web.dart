// --------------------------------------------------------------------------
// GoogleDriveClient - Web Implementation
// --------------------------------------------------------------------------
// 
// PLATFORM SUPPORT: Web only
// Uses OAuth2 token-based authentication for Google Drive API
// --------------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive_api;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

// Drive Constants (same as mobile)
const fileName = 'aa4step_inventory_data.json';
const fileMime = 'application/json';
const String driveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';

/// Web implementation - uses OAuth2 token
class GoogleDriveClient {
  final drive_api.DriveApi _driveApi;

  GoogleDriveClient._create(this._driveApi);

  /// Create client with access token
  static Future<GoogleDriveClient> create(
    dynamic googleAccount, // nullable for web
    String accessToken,
  ) async {
    final authClient = auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken('Bearer', accessToken,
            DateTime.now().toUtc().add(const Duration(minutes: 59))),
        null,
        [driveAppDataScope],
      ),
    );

    final driveApi = drive_api.DriveApi(authClient);
    return GoogleDriveClient._create(driveApi);
  }

  Future<String?> _getFileId() async {
    final result = await _driveApi.files.list(
      q: "name='$fileName' and trashed=false",
      spaces: 'appDataFolder',
    );
    final files = result.files;
    if (files != null && files.isNotEmpty) return files.first.id;
    return null;
  }

  Future<String?> _downloadFileContent(String fileId) async {
    final media = await _driveApi.files.get(
      fileId,
      downloadOptions: drive_api.DownloadOptions.fullMedia,
    ) as drive_api.Media?;
    
    if (media != null) {
      final bytes = await media.stream.expand((chunk) => chunk).toList();
      return String.fromCharCodes(bytes);
    }
    return null;
  }

  Future<String?> _createOrUpdateFile({required String content}) async {
    final currentFileId = await _getFileId();

    final bytes = content.codeUnits;
    final media = drive_api.Media(Stream.fromIterable([bytes]), bytes.length);

    final fileMetadata = drive_api.File()
      ..name = fileName
      ..mimeType = fileMime;

    if (currentFileId != null) {
      try {
        final updated = await _driveApi.files.update(
          fileMetadata,
          currentFileId,
          uploadMedia: media,
        );
        if (kDebugMode) print("Updated file in AppDataFolder: ${updated.id}");
        return updated.id;
      } catch (e) {
        if (kDebugMode) print('Update failed, will attempt create fallback: $e');
      }
    }

    try {
      fileMetadata.parents = ['appDataFolder'];
      final created = await _driveApi.files.create(fileMetadata, uploadMedia: media);
      if (kDebugMode) print("Created file in AppDataFolder: ${created.id}");
      return created.id;
    } catch (e) {
      if (kDebugMode) print('Create failed: $e');
      return null;
    }
  }

  /// Upload file to Drive
  Future<void> uploadFile(String fileContent) async {
    try {
      await _createOrUpdateFile(content: fileContent);
    } catch (e) {
      if (kDebugMode) print('GoogleDriveClient (web): Upload failed: $e');
      rethrow;
    }
  }

  /// Download file from Drive
  Future<String?> downloadFile() async {
    try {
      final fileId = await _getFileId();
      if (fileId == null) return null;
      return await _downloadFileContent(fileId);
    } catch (e) {
      if (kDebugMode) print('GoogleDriveClient (web): Download failed: $e');
      rethrow;
    }
  }

  /// Delete file from Drive
  Future<void> deleteFile() async {
    try {
      final fileId = await _getFileId();
      if (fileId != null) {
        await _driveApi.files.delete(fileId);
        if (kDebugMode) print('GoogleDriveClient (web): Deleted file $fileId');
      }
    } catch (e) {
      if (kDebugMode) print('GoogleDriveClient (web): Delete failed: $e');
      rethrow;
    }
  }
}
