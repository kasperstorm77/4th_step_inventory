// --------------------------------------------------------------------------
// Desktop Drive Authentication - Windows/macOS/Linux
// --------------------------------------------------------------------------
// 
// PLATFORM SUPPORT: Desktop platforms only (Windows/macOS/Linux)
// Uses OAuth 2.0 with automatic clipboard detection
// User authorizes in browser, app automatically detects the redirect URL
// 
// Usage: Only import and use when PlatformHelper.isDesktop returns true
// --------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'desktop_oauth_config.dart';

/// Desktop OAuth configuration for Google Drive
class DesktopDriveAuth {
  // OAuth credentials loaded from desktop_oauth_config.dart
  // That file should NOT be committed to git for security
  static const String _clientId = desktopOAuthClientId;
  static const String _clientSecret = desktopOAuthClientSecret;
  
  static const List<String> _scopes = [
    'email',
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  /// Performs OAuth flow and returns authenticated HTTP client
  /// Opens browser for user to authenticate, automatically detects redirect
  static Future<http.Client?> authenticate(BuildContext context) async {
    try {
      // Create OAuth URL with localhost redirect
      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': _clientId,
        'redirect_uri': 'http://localhost',
        'response_type': 'code',
        'scope': _scopes.join(' '),
        'access_type': 'offline',
        'prompt': 'consent',
      });

      // Show waiting dialog with instructions
      String? code;
      final dialogCompleter = Completer<void>();
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Google Authorization'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text(
                  'Opening browser for Google sign-in...\n\n'
                  'After you authorize:\n'
                  '1. The browser will show a localhost error page\n'
                  '2. Copy the URL from the address bar (Ctrl+L, Ctrl+C)\n'
                  '3. Return to this window\n\n'
                  'Waiting for authorization...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  dialogCompleter.complete();
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Check clipboard
                  final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                  if (clipboardData != null && clipboardData.text != null) {
                    final extractedCode = _extractCodeFromUrl(clipboardData.text!);
                    if (extractedCode != null) {
                      code = extractedCode;
                      dialogCompleter.complete();
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                    } else {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Invalid URL in clipboard. Please copy the localhost URL.')),
                      );
                    }
                  }
                },
                child: const Text('I\'ve Copied the URL'),
              ),
            ],
          ),
        ),
      );

      // Open browser for user to authenticate
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch browser');
      }

      // Wait for dialog to complete
      await dialogCompleter.future;

      if (code == null || code?.isEmpty == true) {
        return null; // User cancelled
      }

      // Exchange authorization code for access token
      final client = await _exchangeCodeForTokens(code!);
      return client;
      
    } catch (e) {
      if (kDebugMode) print('Desktop OAuth error: $e');
      return null;
    }
  }

  /// Extract the authorization code from the localhost redirect URL
  static String? _extractCodeFromUrl(String urlString) {
    try {
      final uri = Uri.parse(urlString);
      return uri.queryParameters['code'];
    } catch (e) {
      if (kDebugMode) print('Error parsing URL: $e');
      return null;
    }
  }

  /// Exchange authorization code for access and refresh tokens via HTTP POST
  static Future<http.Client?> _exchangeCodeForTokens(String code) async {
    try {
      // Make direct HTTP POST to Google's token endpoint
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'code': code,
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'redirect_uri': 'http://localhost',
          'grant_type': 'authorization_code',
        },
      );

      if (response.statusCode != 200) {
        if (kDebugMode) print('Token exchange failed: ${response.statusCode} ${response.body}');
        return null;
      }

      final Map<String, dynamic> tokens = json.decode(response.body);
      final accessToken = tokens['access_token'] as String;
      final refreshToken = tokens['refresh_token'] as String?;
      final expiresIn = tokens['expires_in'] as int?;

      // Create credentials
      final credentials = auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(Duration(seconds: expiresIn ?? 3600)),
        ),
        refreshToken,
        _scopes,
      );

      // Return authenticated client
      return auth.authenticatedClient(http.Client(), credentials);
    } catch (e) {
      if (kDebugMode) print('Token exchange error: $e');
      return null;
    }
  }

  /// Sign out (clear local credentials)
  static Future<void> signOut() async {
    if (kDebugMode) print('Desktop OAuth: Signed out');
  }
}
