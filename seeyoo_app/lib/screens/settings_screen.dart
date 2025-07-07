import 'package:flutter/material.dart';
import 'package:seeyoo_app/models/user_settings.dart';
import 'package:seeyoo_app/services/api_service.dart';
import 'package:seeyoo_app/services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  bool _saveInProgress = false;
  Map<String, dynamic>? _settings;
  final TextEditingController _parentPasswordController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  @override
  void dispose() {
    _parentPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Versuche zuerst, die Einstellungen aus dem lokalen Speicher zu laden
      final storedSettings = await _storageService.getUserSettings();
      
      if (storedSettings != null) {
        setState(() {
          _settings = storedSettings;
          if (_settings!.containsKey('parent_password')) {
            _parentPasswordController.text = _settings!['parent_password'] ?? '';
          }
        });
      }
      
      // Unabhängig davon, ob lokale Einstellungen gefunden wurden, aktualisieren von API
      final apiSettings = await _apiService.getUserSettings();
      
      if (apiSettings != null) {
        setState(() {
          _settings = apiSettings;
          if (_settings!.containsKey('parent_password')) {
            _parentPasswordController.text = _settings!['parent_password'] ?? '';
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden der Einstellungen: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;
    
    setState(() {
      _saveInProgress = true;
    });

    try {
      // Aktualisiere die Einstellungen mit den aktuellen Werten
      _settings!['parent_password'] = _parentPasswordController.text;
      
      // Speichern an API und lokal
      final success = await _apiService.updateUserSettings(_settings!);
      
      if (success) {
        await _storageService.saveUserSettings(_settings!);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Einstellungen erfolgreich gespeichert')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Speichern der Einstellungen')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saveInProgress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Einstellungen'),
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFA1273B)))
          : _settings == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Keine Einstellungen verfügbar',
                        style: TextStyle(color: Color(0xFF8D9296), fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B4248),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                )
              : _buildSettingsForm(),
    );
  }

  Widget _buildSettingsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kindersicherung',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Color(0xFF3B4248)),
          const SizedBox(height: 8),
          TextField(
            controller: _parentPasswordController,
            style: const TextStyle(color: Colors.white),
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Kindersicherungs-PIN',
              labelStyle: TextStyle(color: Color(0xFF8D9296)),
              hintText: 'Vierstellige PIN eingeben',
              hintStyle: TextStyle(color: Color(0xFF8D9296)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3B4248)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFA1273B)),
              ),
            ),
            keyboardType: TextInputType.number,
            maxLength: 4,
          ),
          const SizedBox(height: 16),
          const Text(
            'Die PIN wird für den Zugriff auf altersgeschützte Inhalte benötigt.',
            style: TextStyle(color: Color(0xFF8D9296), fontSize: 12),
          ),
          const SizedBox(height: 40),
          Center(
            child: SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _saveInProgress ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA1273B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _saveInProgress
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Text(
                        'Speichern',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
