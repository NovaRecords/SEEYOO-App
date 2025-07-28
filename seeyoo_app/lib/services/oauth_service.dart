import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:seeyoo_app/services/api_service.dart';
import 'package:seeyoo_app/services/storage_service.dart';
import 'package:seeyoo_app/models/user.dart';

class OAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  /// Google OAuth Anmeldung/Registrierung
  Future<OAuthResult> signInWithGoogle() async {
    try {
      print('OAuth: Starting Google Sign-In');
      
      // Google Sign-In durchführen
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('OAuth: Google Sign-In cancelled by user');
        return OAuthResult(
          success: false,
          errorMessage: 'Anmeldung abgebrochen',
        );
      }

      print('OAuth: Google Sign-In successful for ${googleUser.email}');
      
      // Benutzerdaten extrahieren
      final String email = googleUser.email;
      final String firstName = googleUser.displayName?.split(' ').first ?? '';
      final String lastName = googleUser.displayName?.split(' ').skip(1).join(' ') ?? '';
      
      print('OAuth: User data - Email: $email, Name: $firstName $lastName');
      
      // Versuchen, sich mit bestehenden Daten anzumelden
      final loginResult = await _attemptLogin(email);
      if (loginResult.success) {
        print('OAuth: Existing user login successful');
        return loginResult;
      }
      
      // Wenn Login fehlschlägt, neuen Benutzer registrieren
      print('OAuth: User not found, creating new account');
      return await _registerNewUser(
        email: email,
        firstName: firstName,
        lastName: lastName,
        provider: 'google',
      );
      
    } catch (e) {
      print('OAuth: Google Sign-In error: $e');
      return OAuthResult(
        success: false,
        errorMessage: 'Google Anmeldung fehlgeschlagen: $e',
      );
    }
  }

  /// Facebook OAuth Anmeldung/Registrierung
  Future<OAuthResult> signInWithFacebook() async {
    try {
      print('OAuth: Starting Facebook Login');
      
      // Facebook Login durchführen
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      
      if (result.status != LoginStatus.success) {
        print('OAuth: Facebook Login failed: ${result.status}');
        return OAuthResult(
          success: false,
          errorMessage: 'Facebook Anmeldung fehlgeschlagen',
        );
      }

      // Benutzerdaten von Facebook abrufen
      final userData = await FacebookAuth.instance.getUserData(
        fields: "email,name,first_name,last_name",
      );
      
      final String email = userData['email'] ?? '';
      final String firstName = userData['first_name'] ?? '';
      final String lastName = userData['last_name'] ?? '';
      
      if (email.isEmpty) {
        print('OAuth: Facebook did not provide email');
        return OAuthResult(
          success: false,
          errorMessage: 'E-Mail-Adresse von Facebook nicht verfügbar',
        );
      }
      
      print('OAuth: Facebook data - Email: $email, Name: $firstName $lastName');
      
      // Versuchen, sich mit bestehenden Daten anzumelden
      final loginResult = await _attemptLogin(email);
      if (loginResult.success) {
        print('OAuth: Existing user login successful');
        return loginResult;
      }
      
      // Wenn Login fehlschlägt, neuen Benutzer registrieren
      print('OAuth: User not found, creating new account');
      return await _registerNewUser(
        email: email,
        firstName: firstName,
        lastName: lastName,
        provider: 'facebook',
      );
      
    } catch (e) {
      print('OAuth: Facebook Login error: $e');
      return OAuthResult(
        success: false,
        errorMessage: 'Facebook Anmeldung fehlgeschlagen: $e',
      );
    }
  }

  /// Versucht Anmeldung mit bestehender E-Mail
  Future<OAuthResult> _attemptLogin(String email) async {
    try {
      // Gespeichertes Passwort für OAuth-User abrufen
      final storedPassword = await _storageService.getOAuthPassword(email);
      
      if (storedPassword != null) {
        print('OAuth: Found stored password for $email, attempting login');
        
        final authResponse = await _apiService.authenticate(email, storedPassword);
        
        if (authResponse.isSuccess) {
          print('OAuth: Login successful with stored password');
          
          // Benutzer-E-Mail speichern
          await _storageService.setUserEmail(email);
          
          // Grundlegende Benutzerdaten erstellen
          final username = email.split('@').first;
          final user = User(
            id: authResponse.userId ?? 0,
            email: email,
            fname: username,
            status: 1,
            phone: '',
            tariffPlan: 'Standard',
            endDate: DateTime.now().add(const Duration(days: 30)).toString(),
            accountBalance: null,
            account: null,
            mac: "Mobile-App",
          );
          
          await _storageService.saveUser(user);
          
          if (authResponse.userId != null) {
            await _storageService.setBillingUserId(authResponse.userId!);
          }
          
          return OAuthResult(success: true);
        }
      }
      
      print('OAuth: No stored password found or login failed');
      return OAuthResult(success: false, errorMessage: 'Login failed');
      
    } catch (e) {
      print('OAuth: Login attempt error: $e');
      return OAuthResult(success: false, errorMessage: 'Login error: $e');
    }
  }

  /// Registriert neuen OAuth-Benutzer
  Future<OAuthResult> _registerNewUser({
    required String email,
    required String firstName,
    required String lastName,
    required String provider,
  }) async {
    try {
      print('OAuth: Creating new user in Billing API');
      
      // Schritt 1: Benutzer im Billing-System erstellen
      final userData = await _apiService.createUser(
        name: firstName,
        secondName: lastName,
        email: email,
        tariff: 'full-de',
        isTest: false,
      );
      
      if (userData == null) {
        print('OAuth: Failed to create user in billing system');
        return OAuthResult(
          success: false,
          errorMessage: 'Registrierung fehlgeschlagen',
        );
      }
      
      print('OAuth: User created successfully in billing system');
      print('OAuth: System generated password: ${userData['password']}');
      print('OAuth: User ID: ${userData['id']}');
      
      // Schritt 2: Automatisch generiertes Passwort speichern
      final generatedPassword = userData['password'];
      await _storageService.saveOAuthPassword(email, generatedPassword);
      print('OAuth: Stored generated password for future logins');
      
      // Schritt 3: Mit dem generierten Passwort anmelden
      print('OAuth: Attempting login with generated password');
      final authResponse = await _apiService.authenticate(email, generatedPassword);
      
      if (authResponse.isSuccess) {
        print('OAuth: Authentication successful after registration');
        
        // Benutzer-E-Mail speichern
        await _storageService.setUserEmail(email);
        
        // Billing-ID speichern
        final billingId = int.tryParse(userData['id'].toString()) ?? 0;
        if (billingId > 0) {
          await _storageService.setBillingUserId(billingId);
          print('OAuth: Saved billing user ID: $billingId');
        }
        
        // Grundlegende Benutzerdaten erstellen und speichern
        final user = User(
          id: authResponse.userId ?? 0,
          email: email,
          fname: '$firstName $lastName', // Vollständiger Name in fname
          status: 1,
          phone: '',
          tariffPlan: 'full-de',
          endDate: DateTime.now().add(const Duration(days: 30)).toString(),
          accountBalance: null,
          account: billingId,
          mac: "Mobile-App",
        );
        
        await _storageService.saveUser(user);
        print('OAuth: Saved user data');
        
        if (authResponse.userId != null) {
          await _storageService.setBillingUserId(authResponse.userId!);
        }
        
        return OAuthResult(success: true);
      } else {
        print('OAuth: Authentication failed after registration');
        return OAuthResult(
          success: false,
          errorMessage: 'Anmeldung nach Registrierung fehlgeschlagen',
        );
      }
      
    } catch (e) {
      print('OAuth: Registration error: $e');
      return OAuthResult(
        success: false,
        errorMessage: 'Registrierung fehlgeschlagen: $e',
      );
    }
  }

  /// Google Sign-Out
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      print('OAuth: Google Sign-Out successful');
    } catch (e) {
      print('OAuth: Google Sign-Out error: $e');
    }
  }

  /// Facebook Sign-Out
  Future<void> signOutFacebook() async {
    try {
      await FacebookAuth.instance.logOut();
      print('OAuth: Facebook Sign-Out successful');
    } catch (e) {
      print('OAuth: Facebook Sign-Out error: $e');
    }
  }

  /// Alle OAuth-Provider abmelden
  Future<void> signOutAll() async {
    await signOutGoogle();
    await signOutFacebook();
  }
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
