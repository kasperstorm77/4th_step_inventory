// --------------------------------------------------------------------------
// Google Sign-In Wrapper - Platform Conditional Export
// --------------------------------------------------------------------------
// 
// PLATFORM SUPPORT: Mobile (Android/iOS) and Web
// This file conditionally exports the correct implementation based on platform
// --------------------------------------------------------------------------

export 'google_sign_in_wrapper_impl.dart'
    if (dart.library.html) 'google_sign_in_wrapper_web.dart';
