import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seeyoo_app/screens/main_screen.dart';
import 'package:seeyoo_app/services/api_service.dart';
import 'package:seeyoo_app/services/storage_service.dart';
import 'package:seeyoo_app/services/oauth_service.dart';
import 'package:seeyoo_app/models/user.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  
  // Passwort-Sichtbarkeits-State
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final OAuthService _oauthService = OAuthService();
  
  @override
  void initState() {
    super.initState();
    // Statusleiste während des Auth-Screens ausblenden
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    // Bei Verlassen des Auth-Screens wird die Systemleiste für den MainScreen wieder aktiviert
    // MainScreen wird die Systemleiste basierend auf Menü-Status selbst verwalten
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Passwörter-Check bei Registrierung
      if (!isLogin && _passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwörter stimmen nicht überein')),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      try {
        if (isLogin) {
          // Login mit Bearer-Authentifizierung
          final authResponse = await _apiService.authenticate(
            _emailController.text.trim(), 
            _passwordController.text
          );
          
          if (authResponse.isSuccess) {
            // Nach erfolgreicher Authentifizierung die E-Mail-Adresse speichern
            // Diese wird für die Abfragen im Billing-System benötigt
            final email = _emailController.text.trim();
            await _storageService.setUserEmail(email);
            print('Auth: Saved user email: $email');
            
            // einige grundlegende Benutzerdaten
            final username = email.split('@').first;
            final user = User(
              id: authResponse.userId ?? 0,
              email: email,
              fname: username,
              status: 1, // Aktiver Status
              // Andere Felder werden null oder mit Standardwerten belassen 
              phone: '',
              tariffPlan: 'Standard',
              endDate: DateTime.now().add(const Duration(days: 30)).toString(),
              accountBalance: null,
              account: null,
              mac: "Mobile-App", // Verwende Standardwert, da _getDeviceInfo private ist
            );
            
            await _storageService.saveUser(user);
            print('Auth: Saved basic user data from login');
            
            // Die Stalker-Portal ID ist die wichtigste und wird bereits in authResponse gespeichert
            // Wir verwenden diese ID für alle nachfolgenden Abfragen
            
            if (authResponse.userId != null) {
              await _storageService.setBillingUserId(authResponse.userId!);
              print('Auth: Using authenticated user ID: ${authResponse.userId}');
            }
            
            // Navigation zum Hauptbildschirm
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          } else {
            // Fehlerbehandlung bei fehlgeschlagener Authentifizierung
            setState(() {
              _errorMessage = authResponse.errorMessage ?? 'Anmeldung fehlgeschlagen';
            });
          }
        } else {
          // Implementierung der Registrierung nach dem Zwei-Schritte-Prozess
          setState(() {
            _isLoading = true;
          });
          
          try {
            print('Registration: Creating new user in Billing API');
            final email = _emailController.text.trim();
            final firstName = _firstNameController.text.trim();
            final lastName = _lastNameController.text.trim();
            final password = _passwordController.text;
            
            // Schritt 1: Benutzer im Billing-System erstellen
            // Dabei werden nur die minimal notwendigen Parameter gesendet
            final userData = await _apiService.createUser(
              name: firstName,
              secondName: lastName,
              email: email,
              tariff: 'full-de', // Wichtig: Pflichtfeld für erfolgreiche Registrierung
              isTest: false,     // Kein Testbenutzer
            );
            
            if (userData != null) {
              print('Registration: User created successfully in billing system');
              print('Registration: System generated password: ${userData['password']}');
              print('Registration: User ID: ${userData['id']}');
              
              // Schritt 2: Benutzerpasswort mit dem vom Benutzer gewählten Passwort aktualisieren
              final updateSuccess = await _apiService.updateUserInfo(
                email: email,
                password: password,
              );
              
              if (updateSuccess) {
                print('Registration: Password updated successfully');
                
                // Nach erfolgreicher Registrierung und Passwort-Update versuchen wir die Anmeldung
                print('Registration: Attempting login to get Portal user data');
                final authResponse = await _apiService.authenticate(email, password);
                
                if (authResponse.isSuccess) {
                  print('Registration: Authentication successful after registration');
                  
                  // Nach erfolgreicher Authentifizierung die E-Mail-Adresse speichern
                  await _storageService.setUserEmail(email);
                  print('Auth: Saved user email: $email');
                  
                  // Billing-ID aus der Registrierungsantwort als Kontonummer speichern
                  final billingId = int.tryParse(userData['id'].toString()) ?? 0;
                  await _storageService.setBillingUserId(billingId);
                  print('Auth: Saved billing account ID: $billingId');
                  
                  // Benutzerdaten speichern
                  // Vollständigen Namen aus Vor- und Nachname bilden (für das fname Feld)
                  final fullName = '$firstName $lastName';
                  final user = User(
                    id: authResponse.userId ?? 0,  // Portal-ID vom Login-Prozess
                    email: email,
                    fname: fullName,
                    status: 1, // Aktiver Status
                    phone: '',
                    endDate: DateTime.now().add(const Duration(days: 30)).toString(),
                    accountBalance: null,
                    account: billingId,  // Billing-ID als Kontonummer
                    mac: "Mobile-App-iOS",
                  );
                  
                  await _storageService.saveUser(user);
                  print('Registration: Created and saved user with Portal ID: ${authResponse.userId}');
                  
                  // Die Stalker-Portal ID speichern
                  if (authResponse.userId != null) {
                    await _storageService.setUserId(authResponse.userId!);
                    print('Auth: Saved Portal user ID: ${authResponse.userId}');
                  }
                  
                  // Zum Hauptbildschirm navigieren
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                  return;
                } else {
                  // Authentifizierungsfehler nach erfolgreicher Registrierung
                  setState(() {
                    _errorMessage = authResponse.errorMessage ?? 'Anmeldung nach Registrierung fehlgeschlagen';
                  });
                }
              } else {
                // Fehler beim Aktualisieren des Passworts
                setState(() {
                  _errorMessage = 'Passwort konnte nicht aktualisiert werden';
                });
              }
            } else {
              // Fehler bei der Benutzerregistrierung
              setState(() {
                _errorMessage = 'Registrierung fehlgeschlagen. Bitte versuchen Sie es später erneut.';
              });
            }
          } catch (e) {
            print('Registration error: $e');
            setState(() {
              _errorMessage = 'Ein Fehler ist bei der Registrierung aufgetreten: $e';
            });
          } finally {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          }
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Ein Fehler ist aufgetreten: $e';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// Google OAuth Anmeldung/Registrierung
  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final result = await _oauthService.signInWithGoogle();
      
      if (result.success) {
        print('AuthScreen: Google OAuth successful');
        // Navigation zum Hauptbildschirm
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Google Anmeldung fehlgeschlagen';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Anmeldung fehlgeschlagen: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Facebook OAuth Anmeldung/Registrierung
  void _handleFacebookSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final result = await _oauthService.signInWithFacebook();
      
      if (result.success) {
        print('AuthScreen: Facebook OAuth successful');
        // Navigation zum Hauptbildschirm
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Facebook Anmeldung fehlgeschlagen';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Facebook Anmeldung fehlgeschlagen: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/HG.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // App Logo
                Image.asset(
                  'assets/images/App-Logo.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 60),
                // Auth Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: !isLogin
                          ? () => setState(() => isLogin = true)
                          : null,
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: isLogin ? Colors.white : Colors.white54,
                          fontSize: 20,
                          fontWeight: isLogin ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      height: 20,
                      width: 1,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: isLogin
                          ? () => setState(() => isLogin = false)
                          : null,
                      child: Text(
                        'Registrieren',
                        style: TextStyle(
                          color: !isLogin ? Colors.white : Colors.white54,
                          fontSize: 20,
                          fontWeight: !isLogin ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Social Login Buttons
                _buildSocialButton(
                  'assets/icons/facebook.svg',
                  'Mit Facebook anmelden',
                  Colors.grey[700]!,
                  _handleFacebookSignIn,
                ),
                const SizedBox(height: 16),
                _buildSocialButton(
                  'assets/icons/google.svg',
                  'Mit Google anmelden',
                  Colors.grey[700]!,
                  _handleGoogleSignIn,
                ),
                const SizedBox(height: 24),
                // Divider with "oder"
                Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        color: Colors.white54,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'oder',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(
                        color: Colors.white54,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Email & Password Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Felder für Vor- und Nachname nur bei Registrierung anzeigen
                      if (!isLogin) ...[  
                        _buildTextField(
                          controller: _firstNameController,
                          hint: 'Vorname',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Bitte geben Sie Ihren Vornamen ein';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _lastNameController,
                          hint: 'Nachname',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Bitte geben Sie Ihren Nachnamen ein';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildTextField(
                        controller: _emailController,
                        hint: 'E-Mail-Adresse',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bitte geben Sie eine E-Mail-Adresse ein';
                          }
                          if (!value.contains('@')) {
                            return 'Bitte geben Sie eine gültige E-Mail-Adresse ein';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        hint: 'Passwort',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        isPasswordVisible: _isPasswordVisible,
                        onTogglePasswordVisibility: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bitte geben Sie ein Passwort ein';
                          }
                          if (value.length < 6) {
                            return 'Das Passwort muss mindestens 6 Zeichen lang sein';
                          }
                          return null;
                        },
                      ),
                      if (!isLogin) ...[ 
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hint: 'Passwort bestätigen',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          isPasswordVisible: _isConfirmPasswordVisible,
                          onTogglePasswordVisibility: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Bitte bestätigen Sie Ihr Passwort';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 32),
                      // Error Message (falls vorhanden)
                      if (_errorMessage != null && _errorMessage!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                      // Login/Register Button
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4, // 40% of screen width
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA1273B), // #A1273B
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : Text(
                                  isLogin ? 'Login' : 'Registrieren',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String iconPath, String text, Color color, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color, // Grau für Social Buttons
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool? isPasswordVisible,
    VoidCallback? onTogglePasswordVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText && (isPasswordVisible == null || !isPasswordVisible),
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.montserrat(
        color: Colors.white,
        fontSize: 18,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(
          color: Colors.white54,
          fontSize: 18,
        ),
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixIcon: obscureText && onTogglePasswordVisibility != null
            ? IconButton(
                icon: Icon(
                  (isPasswordVisible ?? false) ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white54,
                ),
                onPressed: onTogglePasswordVisibility,
              )
            : null,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        errorStyle: const TextStyle(color: Colors.red),
      ),
      cursorColor: Colors.white,
    );
  }
}
