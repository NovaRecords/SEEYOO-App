import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seeyoo_app/screens/main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // Handle form submission
      if (!isLogin && _passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwörter stimmen nicht überein')),
        );
        return;
      }
      // Navigate to MainScreen after successful login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
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
                      // Login/Register Button
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4, // 40% of screen width
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA1273B), // #A1273B
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
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
