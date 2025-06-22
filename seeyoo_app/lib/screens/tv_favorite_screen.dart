import 'package:flutter/material.dart';
import 'package:seeyoo_app/widgets/background_image.dart';

class TvFavoriteScreen extends StatelessWidget {
  const TvFavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BackgroundImage(
      imagePath: 'assets/images/HG2.png',
      child: Center(
        child: Text(
          'Deine TV Favoriten erscheinen hier',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
