// OAuth imports removed - implementation not supported by billing API yet
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:seeyoo_app/services/api_service.dart';
import 'package:seeyoo_app/services/storage_service.dart';
import 'package:seeyoo_app/models/user.dart';

class OAuthService {
  // OAuth instances removed - implementation not supported by billing API yet
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  /// Google OAuth Anmeldung/Registrierung (Platzhalter)
  Future<OAuthResult> signInWithGoogle() async {
    print('OAuth: Google Sign-In requested but not implemented');
    
    return OAuthResult(
      success: false,
      errorMessage: 'Google Anmeldung ist noch nicht verfügbar. Bitte verwenden Sie die manuelle Registrierung.',
    );
  }

  // OAuth helper methods removed - not needed without OAuth implementation

  /// Facebook OAuth Anmeldung/Registrierung (Platzhalter)
  Future<OAuthResult> signInWithFacebook() async {
    print('OAuth: Facebook Sign-In requested but not implemented');
    
    return OAuthResult(
      success: false,
      errorMessage: 'Facebook Anmeldung ist noch nicht verfügbar. Bitte verwenden Sie die manuelle Registrierung.',
    );
  }

  // OAuth implementation removed - not supported by billing API yet

  // OAuth sign-out methods removed - not needed without OAuth implementation
}

/// Ergebnis einer OAuth-Operation
class OAuthResult {
  final bool success;
  final String? errorMessage;
  
  OAuthResult({
    required this.success,
    this.errorMessage,
  });
}
