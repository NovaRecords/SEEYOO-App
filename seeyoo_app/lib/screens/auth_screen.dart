import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seeyoo_app/screens/main_screen.dart';
import 'package:seeyoo_app/services/api_service.dart';
import 'package:seeyoo_app/services/storage_service.dart';

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
  
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
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
            // Nach erfolgreicher Anmeldung die richtige Benutzer-ID in der Billing-API finden
            try {
              // Zuerst versuchen, den Benutzer anhand der E-Mail-Adresse zu finden
              final email = _emailController.text.trim();
              print('Auth: Searching for user with email: $email in Billing API');
              
              final foundUser = await _apiService.findUserByEmail(email);
              
              if (foundUser != null && foundUser['id'] != null) {
                // Benutzer in der Billing-API gefunden, ID separat speichern
                final billingUserId = int.tryParse(foundUser['id'].toString());
                if (billingUserId != null) {
                  print('Auth: Found user in Billing API with ID: $billingUserId');
                  await _storageService.setBillingUserId(billingUserId);
                  print('Auth: Updated billing user ID in storage to: $billingUserId');
                }
              } else {
                // Benutzer nicht gefunden, versuchen einen neuen zu erstellen
                print('Auth: User not found in Billing API, creating a new one...');
                
                final result = await _apiService.createUser(
                  name: email.split('@')[0], // Verwende den Teil vor @ als Namen
                  email: email,
                  tariff: 'full-de',
                  password: _passwordController.text,
                );
                
                if (result != null && result['id'] != null) {
                  // Benutzer wurde erstellt, Billing-API ID separat speichern
                  print('Auth: Created new user with ID: ${result["id"]}');
                  final userId = int.tryParse(result["id"].toString());
                  if (userId != null) {
                    await _storageService.setBillingUserId(userId);
                    print('Auth: Saved billing user ID: $userId');
                    
                    // Hinweis: Das Setzen des Ablaufdatums ist über die API nicht möglich
                    // Das Ablaufdatum muss auf Server-Seite gesetzt werden
                  }
                }
              }
            } catch (e) {
              print('Auth: Error checking/creating user: $e');
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
          // Implementierung der Registrierung
          setState(() {
            _isLoading = true;
          });
          
          try {
            // 1. Zuerst den Benutzer in der Billing-API erstellen
            print('Registration: Creating new user in Billing API');
            final email = _emailController.text.trim();
            final firstName = _firstNameController.text.trim();
            final lastName = _lastNameController.text.trim();
            // Vollständigen Namen aus Vor- und Nachname bilden
            final name = '$firstName $lastName';
            final password = _passwordController.text;
            
            // Benutzer in der Billing-API erstellen
            final result = await _apiService.createUser(
              name: name,
              email: email,
              tariff: 'full-de', // Standard-Tarif
              password: password,
              isTest: false,    // Kein Testbenutzer
            );
            
            if (result != null && result['id'] != null) {
              // Benutzer wurde erstellt
              final userId = int.tryParse(result['id'].toString());
              print('Registration: Created user in Billing API with ID: $userId');
              
              if (userId != null) {
                // Billing-API Benutzer-ID separat speichern
                await _storageService.setBillingUserId(userId);
                
                // Hinweis: Das Setzen des Ablaufdatums ist über die API nicht möglich
                // Das Ablaufdatum muss auf Server-Seite gesetzt werden
                
                // 2. Mit den gleichen Anmeldedaten in der Auth-API authentifizieren
                final authResponse = await _apiService.authenticate(email, password);
                
                if (authResponse.isSuccess) {
                  print('Registration: Authentication successful after registration');
                  
                  // 3. Zum Hauptbildschirm navigieren
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                  return; // Früher zurückkehren, da wir bereits navigiert haben
                } else {
                  // Authentifizierung fehlgeschlagen
                  setState(() {
                    _errorMessage = 'Registrierung erfolgreich, aber automatische Anmeldung fehlgeschlagen. Bitte melden Sie sich manuell an.';
                  });
                }
              }
            } else {
              // Fehler bei der Benutzerregistrierung
              final errorMsg = result != null && result['error'] != null ? result['error'] : 'Unbekannter Fehler';
              setState(() {
                _errorMessage = 'Registrierung fehlgeschlagen: $errorMsg';
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
                  height: 40,  // Reduced from 80 to 40 (50% smaller)
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
                          fontSize: 18,
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
                          fontSize: 18,
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
                ),
                const SizedBox(height: 16),
                _buildSocialButton(
                  'assets/icons/google.svg',
                  'Mit Google anmelden',
                  Colors.grey[700]!,
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
                      if (!isLogin) ...[  // Only show for registration
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hint: 'Passwort bestätigen',
                          icon: Icons.lock_outline,
                          obscureText: true,
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
                                    fontSize: 16,
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

  Widget _buildSocialButton(String iconPath, String text, Color color) {
    return ElevatedButton(
      onPressed: () {
        // TODO: Implement social login
      },
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.montserrat(
        color: Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(
          color: Colors.white54,
          fontSize: 16,
        ),
        prefixIcon: Icon(icon, color: Colors.white54),
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
