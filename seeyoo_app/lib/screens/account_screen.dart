import 'package:flutter/material.dart';
import 'package:seeyoo_app/services/storage_service.dart';
import 'package:seeyoo_app/screens/auth_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final StorageService _storageService = StorageService();
  bool _isLoading = false;

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Alle Auth-Daten löschen
      await _storageService.clearAuthData();
      
      // Zur Login-Seite navigieren und Navigationsverlauf löschen
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false, // Entfernt alle Routen im Stack
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Ausloggen: $e')),
      );
    } finally {
      // Falls der Screen noch gemounted ist (obwohl wir eigentlich schon navigiert haben)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Dein Konto wird hier angezeigt',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 50),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA1273B), // #A1273B (rot wie Login-Button)
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.0,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Ausloggen',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
