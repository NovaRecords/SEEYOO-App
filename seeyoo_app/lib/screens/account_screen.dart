import 'package:flutter/material.dart';
import 'package:seeyoo_app/widgets/background_image.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BackgroundImage(
      imagePath: 'assets/images/HG2.png',
      child: Center(
        child: Text(
          'Kontoinformationen werden hier angezeigt',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
