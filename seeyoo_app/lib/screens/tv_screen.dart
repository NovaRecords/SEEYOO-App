import 'package:flutter/material.dart';

class TvScreen extends StatelessWidget {
  const TvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'TV Inhalte werden hier angezeigt',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
  }
}
