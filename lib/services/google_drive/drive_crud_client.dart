import 'dart:async';
import 'package:googleapis/drive/v3.dart' as gApi;
import 'package:googleapis_auth/googleapis_auth.dart' as gAuth;
import 'package:http/http.dart' as http;
import 'drive_config.dart';

// --------------------------------------------------------------------------
// Core Google Drive CRUD Client - Reusable
// --------------------------------------------------------------------------

/// Pure Google Drive CRUD operations client
/// No business logic, just raw Drive API operations
class GoogleDriveCrudClient {
  final gApi.DriveApi _driveApi;
  final GoogleDriveConfig _config;

  GoogleDriveCrudClient._(this._driveApi, this._config);

  /// Create a new Google Drive client with authentication
  static Future<GoogleDriveCrudClient> create({
    required String accessToken,
    required GoogleDriveConfig config,
  }) async {
    final authClient = gAuth.authenticatedClient(
      http.Client(),
      gAuth.AccessCredentials(
        gAuth.AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(const Duration(minutes: 59)),
        ),
        null,
        [config.scope],
      ),
    );

    final driveApi = gApi.DriveApi(authClient);
    return GoogleDriveCrudClient._(driveApi, config);
  }

  /// Find file by name in the configured location
  Future<String?> findFile() async {
    final query = "name='${_config.fileName}' and trashed=false";
    final spaces = _config.parentFolder;
    
    final result = await _driveApi.files.list(
      q: query,
      spaces: spaces,
    );
    
    final files = result.files;
    return (files != null && files.isNotEmpty) ? files.first.id : null;
  }

  /// Read file content by ID
  Future<String?> readFile(String fileId) async {
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

  /// Create a new file with content
  Future<String> createFile(String content) async {
    final bytes = content.codeUnits;
    final media = gApi.Media(Stream.fromIterable([bytes]), bytes.length);

    final fileMetadata = gApi.File()
      ..name = _config.fileName
      ..mimeType = _config.mimeType;

    // Set parent folder if specified
    if (_config.parentFolder != null) {
      fileMetadata.parents = [_config.parentFolder!];
    }

    final created = await _driveApi.files.create(fileMetadata, uploadMedia: media);
    return created.id!;
  }

  /// Update existing file with new content
  Future<String> updateFile(String fileId, String content) async {
    final bytes = content.codeUnits;
    final media = gApi.Media(Stream.fromIterable([bytes]), bytes.length);

    final fileMetadata = gApi.File()
      ..name = _config.fileName
      ..mimeType = _config.mimeType;

    final updated = await _driveApi.files.update(
      fileMetadata,
      fileId,
      uploadMedia: media,
    );
    return updated.id!;
  }

  /// Delete file by ID
  Future<void> deleteFile(String fileId) async {
    await _driveApi.files.delete(fileId);
  }

  /// Create or update file (upsert operation)
  Future<String> upsertFile(String content) async {
    final existingFileId = await findFile();
    
    if (existingFileId != null) {
      try {
        return await updateFile(existingFileId, content);
      } catch (e) {
        // If update fails, try to create new file
        return await createFile(content);
      }
    } else {
      return await createFile(content);
    }
  }

  /// Read file content (find and read in one operation)
  Future<String?> readFileContent() async {
    final fileId = await findFile();
    return fileId != null ? await readFile(fileId) : null;
  }

  /// Delete file by name (find and delete in one operation)
  Future<bool> deleteFileByName() async {
    final fileId = await findFile();
    if (fileId != null) {
      await deleteFile(fileId);
      return true;
    }
    return false;
  }

  /// List all files in the configured location
  Future<List<gApi.File>> listFiles({String? query}) async {
    final searchQuery = query ?? "trashed=false";
    final spaces = _config.parentFolder;
    
    final result = await _driveApi.files.list(
      q: searchQuery,
      spaces: spaces,
    );
    
    return result.files ?? [];
  }

  /// Check if file exists
  Future<bool> fileExists() async {
    final fileId = await findFile();
    return fileId != null;
  }

  /// Get file metadata
  Future<gApi.File?> getFileMetadata() async {
    final fileId = await findFile();
    if (fileId != null) {
      return await _driveApi.files.get(fileId) as gApi.File;
    }
    return null;
  }
}