import 'package:flutter/material.dart';

class TvFavoriteScreen extends StatelessWidget {
  const TvFavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Deine TV Favoriten erscheinen hier',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
  }
}
