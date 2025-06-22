import 'package:flutter/material.dart';
import 'package:seeyoo_app/widgets/background_image.dart';

class RadioScreen extends StatelessWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BackgroundImage(
      imagePath: 'assets/images/HG2.png',
      child: Center(
        child: Text(
          'Radiosender werden hier angezeigt',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
