import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Dein Konto wird hier angezeigt',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
  }
}
