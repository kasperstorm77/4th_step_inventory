// --------------------------------------------------------------------------
// Desktop Drive Client - Windows/macOS/Linux
// --------------------------------------------------------------------------
// 
// PLATFORM SUPPORT: Desktop platforms (Windows/macOS/Linux)
// This client works with any authenticated HTTP client from desktop OAuth.
// 
// Usage: Only import and use when PlatformHelper.isDesktop returns true.
// --------------------------------------------------------------------------

import 'dart:async';
import 'package:googleapis/drive/v3.dart' as gApi;
import 'package:http/http.dart' as http;

// Drive Constants (same as mobile)
const fileName = 'aa4step_inventory_data.json';
const fileMime = 'application/json';
const String driveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';

/// Desktop Google Drive client
/// Works with authenticated HTTP client from desktop_webview_auth
class DesktopDriveClient {
  late gApi.DriveApi _driveApi;

  DesktopDriveClient._create(this._driveApi);

  /// Create a Drive client from an authenticated HTTP client
  /// The client comes from desktop_webview_auth (desktop platforms)
  static DesktopDriveClient createFromAuthClient(http.Client authClient) {
    final driveApi = gApi.DriveApi(authClient);
    return DesktopDriveClient._create(driveApi);
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
      downloadOptions: gApi.DownloadOptions.fullMedia,
    ) as gApi.Media?;
    
    if (media != null) {
      final bytes = await media.stream.expand((chunk) => chunk).toList();
      return String.fromCharCodes(bytes);
    }
    return null;
  }

  Future<String?> _createOrUpdateFile({required String content}) async {
    final currentFileId = await _getFileId();

    final bytes = content.codeUnits;
    final media = gApi.Media(Stream.fromIterable([bytes]), bytes.length);

    final fileMetadata = gApi.File()
      ..name = fileName
      ..mimeType = fileMime;

    if (currentFileId != null) {
      try {
        final updated = await _driveApi.files.update(
          fileMetadata,
          currentFileId,
          uploadMedia: media,
        );
        print("Updated file in AppDataFolder: ${updated.id}");
        return updated.id;
      } catch (e) {
        print('Update failed, will attempt create fallback: $e');
      }
    }

    try {
      // Explicitly place file in appDataFolder
      fileMetadata.parents = ['appDataFolder'];
      final created = await _driveApi.files.create(fileMetadata, uploadMedia: media);
      print("Created file in AppDataFolder: ${created.id}");
      return created.id;
    } catch (e) {
      print('Create in AppDataFolder failed: $e');
      rethrow;
    }
  }

  Future<void> _deleteFileOnGoogleDrive(String fileId) async {
    await _driveApi.files.delete(fileId);
  }

  /// Upload JSON content to Google Drive
  Future<void> uploadFile(String fileContent) async {
    try {
      await _createOrUpdateFile(content: fileContent);
    } catch (e) {
      print("GoogleDrive uploadFile error: $e");
      rethrow;
    }
  }

  /// Download JSON content from Google Drive
  Future<String?> downloadFile() async {
    try {
      final fileId = await _getFileId();
      if (fileId != null) return await _downloadFileContent(fileId);
      print("File not found in AppDataFolder");
      return null;
    } catch (e) {
      print("GoogleDrive downloadFile error: $e");
      rethrow;
    }
  }

  /// Delete file from Google Drive
  Future<void> deleteFile() async {
    try {
      final fileId = await _getFileId();
      if (fileId != null) {
        await _deleteFileOnGoogleDrive(fileId);
        print("Deleted file from AppDataFolder");
      }
    } catch (e) {
      print("GoogleDrive deleteFile error: $e");
      rethrow;
    }
  }
}
