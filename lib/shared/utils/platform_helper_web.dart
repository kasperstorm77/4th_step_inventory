// --------------------------------------------------------------------------
// Platform Stub for Web
// --------------------------------------------------------------------------
// This file provides stub classes for web builds where dart:io
// is not available.
// --------------------------------------------------------------------------

import 'dart:typed_data';

/// Stub Platform class for web
class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isWindows => false;
  static bool get isMacOS => false;
  static bool get isLinux => false;
}

/// Stub File class for web
class File {
  File(String path);
  
  Future<void> writeAsBytes(Uint8List bytes) async {
    throw UnsupportedError('File operations not supported on web');
  }
  
  Future<Uint8List> readAsBytes() async {
    throw UnsupportedError('File operations not supported on web');
  }
  
  Future<String> readAsString() async {
    throw UnsupportedError('File operations not supported on web');
  }
}

/// Stub Directory class for web
class Directory {
  Directory(String path);
  
  Future<bool> exists() async {
    throw UnsupportedError('Directory operations not supported on web');
  }
}
