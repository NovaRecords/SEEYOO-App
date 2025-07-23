import 'package:flutter/material.dart';

class RadioScreen extends StatelessWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildDevelopmentMessage();
  }

  Widget _buildDevelopmentMessage() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, -30), // 30px nach oben verschieben
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.radio, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              Text(
                'Radio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Diese Funktion befindet sich\nnoch in der Entwicklung\nund wird mit dem nächsten\nRelease verfügbar sein.',
                style: TextStyle(color: const Color(0xFF8D9296), fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
