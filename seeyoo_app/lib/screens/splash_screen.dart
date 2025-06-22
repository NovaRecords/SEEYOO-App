import 'dart:async';
import 'package:flutter/material.dart';
import 'package:seeyoo_app/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    // Starte den Fade-In Effekt
    _controller.forward().then((_) {
      // Nach dem Fade-In 3 Sekunden warten, dann Fade-Out und Navigation
      Timer(const Duration(milliseconds: 3000), _navigateToHome);
    });
  }


  void _navigateToHome() {
    if (!mounted) return;
    
    _controller.reverse().then((_) {
      if (!mounted) return;
      
      try {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) => const HomeScreen(),
            transitionDuration: Duration.zero,
          ),
        );
      } catch (e) {
        print('Navigation error: $e');
        // Fallback Navigation falls die erste Methode fehlschlägt
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
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
      backgroundColor: Colors.transparent,
      body: Container(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Image.asset(
            'assets/images/start.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
