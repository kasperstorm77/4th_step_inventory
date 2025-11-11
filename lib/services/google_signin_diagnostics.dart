// --------------------------------------------------------------------------
// Google Sign-In Diagnostic Helper
// --------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInDiagnostics {
  static Future<void> diagnoseGoogleSignIn() async {
    if (kDebugMode) {
      print('=== Google Sign-In Diagnostics ===');
      
      try {
        // Test basic GoogleSignIn initialization
        const scopes = <String>[
          'email',
          'https://www.googleapis.com/auth/drive.appdata',
        ];
        
        final googleSignIn = GoogleSignIn(scopes: scopes);
        print('✓ GoogleSignIn instance created successfully');
        
        // Check if user is already signed in
        final currentUser = await googleSignIn.isSignedIn();
        print('Current sign-in status: $currentUser');
        
        if (currentUser) {
          final account = googleSignIn.currentUser;
          print('Current user: ${account?.displayName} (${account?.email})');
        }
        
        // Test silent sign-in
        print('Attempting silent sign-in...');
        final silentAccount = await googleSignIn.signInSilently();
        if (silentAccount != null) {
          print('✓ Silent sign-in successful: ${silentAccount.displayName}');
          
          // Test authentication token retrieval
          try {
            final auth = await silentAccount.authentication;
            print('✓ Access token retrieved: ${auth.accessToken != null}');
            print('✓ ID token retrieved: ${auth.idToken != null}');
          } catch (e) {
            print('✗ Failed to get authentication tokens: $e');
          }
        } else {
          print('- No silent sign-in available (user needs to sign in manually)');
        }
        
      } catch (e) {
        print('✗ Google Sign-In diagnostics failed: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      
      print('=== End Diagnostics ===');
    }
  }
  
  static Future<void> testInteractiveSignIn() async {
    if (kDebugMode) {
      print('=== Testing Interactive Sign-In ===');
      
      try {
        const scopes = <String>[
          'email',
          'https://www.googleapis.com/auth/drive.appdata',
        ];
        
        final googleSignIn = GoogleSignIn(scopes: scopes);
        
        print('Attempting interactive sign-in...');
        final account = await googleSignIn.signIn();
        
        if (account != null) {
          print('✓ Interactive sign-in successful: ${account.displayName}');
          print('  Email: ${account.email}');
          print('  ID: ${account.id}');
          
          // Test authentication
          try {
            final auth = await account.authentication;
            print('✓ Access token: ${auth.accessToken?.substring(0, 20)}...');
          } catch (e) {
            print('✗ Failed to get tokens: $e');
          }
        } else {
          print('- Interactive sign-in cancelled by user');
        }
        
      } catch (e) {
        print('✗ Interactive sign-in failed: $e');
        print('Error type: ${e.runtimeType}');
        if (e is Exception) {
          print('Exception details: $e');
        }
      }
      
      print('=== End Interactive Test ===');
    }
  }
}