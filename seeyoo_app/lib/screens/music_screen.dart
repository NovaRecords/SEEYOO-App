import 'package:flutter/material.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Musik wird hier angezeigt',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
  }
}
