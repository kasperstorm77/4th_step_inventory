import 'package:google_sign_in/google_sign_in.dart';
import 'drive_config.dart';
import 'drive_crud_client.dart';

// --------------------------------------------------------------------------
// Google Authentication Service - Reusable
// --------------------------------------------------------------------------

/// Handles Google Sign-In authentication for Drive access
class GoogleAuthService {
  final GoogleSignIn _googleSignIn;
  final GoogleDriveConfig _config;
  
  GoogleSignInAccount? _currentUser;
  String? _accessToken;

  GoogleAuthService({required GoogleDriveConfig config})
      : _config = config,
        _googleSignIn = GoogleSignIn(scopes: [config.scope]);

  /// Current authenticated user
  GoogleSignInAccount? get currentUser => _currentUser;
  
  /// Current access token
  String? get accessToken => _accessToken;
  
  /// Check if user is signed in
  bool get isSignedIn => _currentUser != null && _accessToken != null;

  /// Stream of authentication state changes
  Stream<GoogleSignInAccount?> get onAuthStateChanged => 
      _googleSignIn.onCurrentUserChanged;

  /// Initialize and attempt silent sign-in
  Future<bool> initializeAuth() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        await _updateAuthState(account);
        return true;
      }
    } catch (e) {
      print('Silent sign-in failed: $e');
    }
    return false;
  }

  /// Interactive sign-in
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await _updateAuthState(account);
        return true;
      }
    } catch (e) {
      print('Interactive sign-in failed: $e');
    }
    return false;
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _accessToken = null;
  }

  /// Create authenticated Drive client
  Future<GoogleDriveCrudClient?> createDriveClient() async {
    if (!isSignedIn) return null;
    
    return GoogleDriveCrudClient.create(
      accessToken: _accessToken!,
      config: _config,
    );
  }

  /// Refresh access token if needed
  Future<bool> refreshTokenIfNeeded() async {
    if (_currentUser == null) return false;
    
    try {
      final auth = await _currentUser!.authentication;
      if (auth.accessToken != null) {
        _accessToken = auth.accessToken;
        return true;
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }
    return false;
  }

  /// Update internal auth state
  Future<void> _updateAuthState(GoogleSignInAccount account) async {
    _currentUser = account;
    
    final auth = await account.authentication;
    _accessToken = auth.accessToken;
    
    if (_accessToken == null) {
      throw Exception('Failed to get access token');
    }
  }

  /// Listen to auth state changes
  void listenToAuthChanges(void Function(GoogleSignInAccount?) callback) {
    _googleSignIn.onCurrentUserChanged.listen((account) async {
      if (account != null) {
        await _updateAuthState(account);
      } else {
        _currentUser = null;
        _accessToken = null;
      }
      callback(account);
    });
  }
}