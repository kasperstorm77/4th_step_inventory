// --------------------------------------------------------------------------
// Legacy Drive Service - Platform-Aware Export
// --------------------------------------------------------------------------
// Exports platform-specific implementation:
// - Mobile (Android/iOS): Full Drive sync implementation
// - Web: Stub implementation (Drive sync not supported yet)
// - Desktop: Uses mobile implementation (with desktop auth)
// --------------------------------------------------------------------------

export 'legacy_drive_service_impl.dart'
    if (dart.library.html) 'legacy_drive_service_web.dart';
