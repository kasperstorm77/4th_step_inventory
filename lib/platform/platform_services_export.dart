// --------------------------------------------------------------------------
// Platform Services - Main Export
// --------------------------------------------------------------------------

// Main interfaces and factory
export 'platform_services.dart';
export 'platform_factory.dart';

// Platform-specific implementations
export 'android_platform_services.dart';
export 'ios_platform_services.dart';
export 'windows_platform_services.dart';

// --------------------------------------------------------------------------
// Usage Examples:
//
// 1. Basic usage (automatic platform detection):
//    ```dart
//    import 'package:aa_4step_inventory/platform/platform_services.dart';
//    
//    final platform = PlatformFactory.instance;
//    await platform.initialize();
//    
//    // Google Sign-In
//    final result = await platform.signInWithGoogle();
//    if (result?.isSuccess == true) {
//      print('Signed in as: ${result!.displayName}');
//    }
//    
//    // File operations
//    final entries = await platform.importCsvFile();
//    await platform.exportCsvFile(entries ?? []);
//    ```
//
// 2. Platform-specific usage:
//    ```dart
//    if (platform.isAndroid) {
//      // Android-specific functionality
//    } else if (platform.isWindows) {
//      // Windows-specific fallback
//    }
//    ```
//
// 3. Testing with specific platform:
//    ```dart
//    PlatformFactory.reset();
//    final androidPlatform = AndroidPlatformServices.instance;
//    await androidPlatform.initialize();
//    ```
// --------------------------------------------------------------------------