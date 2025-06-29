import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:seeyoo_app/screens/auth_screen.dart';
import 'package:seeyoo_app/screens/main_screen.dart';
import 'package:seeyoo_app/services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _blurAnimation;
  bool _showBlur = true; // Flag für Blur-Steuerung

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Bei 0 ist der schwarze Layer sichtbar (Bild nicht sichtbar)
    // Bei 1 ist der schwarze Layer transparent (Bild voll sichtbar)
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
    
    // Blur-Animation: von stärker verschwommen (25.0) zu scharf (0.0)
    _blurAnimation = Tween<double>(begin: 25.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut, // Schnelleres Scharf-Werden
      ),
    );

    // Starte den Fade-In Effekt
    _controller.forward().then((_) {
      // Nach dem Fade-In 3 Sekunden warten, dann Fade-Out und Navigation
      Timer(const Duration(milliseconds: 3000), _navigateToHome);
    });
  }


  void _navigateToHome() async {
    if (!mounted) return;
    
    // Prüfen, ob bereits ein gültiger Token vorhanden ist
    final StorageService storageService = StorageService();
    final bool isLoggedIn = await storageService.isLoggedIn();
    
    // Blur-Effekt deaktivieren, bevor wir mit dem Fade-Out beginnen
    setState(() {
      _showBlur = false;
    });
    
    // Nur Fade-Out durchführen
    _controller.reverse().then((_) {
      if (mounted) {
        // Je nach Login-Status zur entsprechenden Seite navigieren
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => isLoggedIn 
              ? const MainScreen() 
              : const AuthScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([_controller, _blurAnimation]),
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Verschwommenes Hintergrundbild (immer sichtbar)
              if (_showBlur)
                ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: _blurAnimation.value,
                    sigmaY: _blurAnimation.value,
                  ),
                  child: Image.asset(
                    'assets/images/start.png',
                    fit: BoxFit.cover,
                  ),
                )
              // Wenn kein Blur mehr, dann normales Bild
              else
                Image.asset(
                  'assets/images/start.png',
                  fit: BoxFit.cover,
                ),
              
              // Schwarze Überlagerung für Fade-Effekte
              // Diese Überlagerung hat die richtige Schichtungsreihenfolge
              Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  color: Colors.black,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
