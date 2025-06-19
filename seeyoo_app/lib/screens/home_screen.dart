import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEEYOO App'),
      ),
      body: const Center(
        child: Text(
          'Willkommen bei SEEYOO',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
