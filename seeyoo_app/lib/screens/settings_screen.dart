import 'package:flutter/material.dart';
import 'package:seeyoo_app/models/user_settings.dart';
import 'package:seeyoo_app/services/api_service.dart';
import 'package:seeyoo_app/services/storage_service.dart';
import 'package:seeyoo_app/screens/tv_favorite_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  bool _saveInProgress = false;
  Map<String, dynamic>? _settings;
  bool _startWithFavorites = false;
  String _mobileQuality = 'Hoch';
  String _wifiQuality = 'Hoch';
  
  // Bitrate-Optionen
  final List<String> _bitrateOptions = ['Automatisch', 'Hoch', 'Klein'];
  
  // App-Version
  String _appVersion = '1.0.0';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }
  
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version}(${packageInfo.buildNumber})';
      });
    } catch (e) {
      print('Fehler beim Laden der App-Version: $e');
    }
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Einstellungen vom Server laden
      _settings = await _apiService.getUserSettings();
      
      // Falls keine Einstellungen vom Server verfügbar sind, lokale Einstellungen laden
      if (_settings == null) {
        _settings = await _storageService.getUserSettings();
      }
      
      // Falls noch immer keine Einstellungen vorhanden sind, Standardwerte verwenden
      if (_settings == null) {
        _settings = {
          'start_with_favorites': false,
          'mobile_quality': 'Hoch',
          'wifi_quality': 'Hoch',
        };
      }
      
      setState(() {
        _startWithFavorites = _settings!['start_with_favorites'] == true || _settings!['start_with_favorites'] == 'true';
        _mobileQuality = _settings!['mobile_quality']?.toString() ?? 'Hoch';
        _wifiQuality = _settings!['wifi_quality']?.toString() ?? 'Hoch';
      });
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

  // Diese Methode speichert nur Bitrate-Einstellungen lokal
  Future<void> _saveBitrateSettings() async {
    if (_settings == null) return;
    
    setState(() {
      _saveInProgress = true;
    });

    try {
      // Lokale Einstellungen mit allen Werten aktualisieren
      Map<String, dynamic> localSettings = Map<String, dynamic>.from(_settings!);
      localSettings['mobile_quality'] = _mobileQuality;
      localSettings['wifi_quality'] = _wifiQuality;
      
      // Nur lokal speichern, keine Server-Anfrage
      await _storageService.saveUserSettings(localSettings);
      
      // Aktualisiere die _settings Map für die lokale Verwendung
      setState(() {
        _settings = localSettings;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern der Bitrate-Einstellungen: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saveInProgress = false;
        });
      }
    }
  }

  // Diese Methode speichert andere Einstellungen wie Passwort an den Server
  Future<void> _saveSettings() async {
    if (_settings == null) return;
    
    setState(() {
      _saveInProgress = true;
    });

    try {
      // Für andere Servereinstellungen außer Kindersicherung und Bitrate
      // Aktuell keine weiteren Server-Einstellungen zu speichern
      
      // Start with favorites Einstellung separat behandeln (nur lokal)
      Map<String, dynamic> localSettings = Map<String, dynamic>.from(_settings!);
      localSettings['start_with_favorites'] = _startWithFavorites;
      
      // Speichern an API (nur Passwort)
      final success = await _apiService.updateUserSettings(_settings!);
      
      if (success) {
        // Speichere die lokalen Einstellungen (ohne Bitrate-Einstellungen zu überschreiben)
        await _storageService.saveUserSettings(localSettings);
        
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
      backgroundColor: const Color(0xFF1B1E22),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BITRATE Sektion
          _buildSectionHeader('BITRATE'),
          _buildBitrateOption('Mobil', _mobileQuality, (value) async {
            setState(() {
              _mobileQuality = value;
            });
            // Automatisch speichern nach Änderung (nur lokal)
            await _saveBitrateSettings();
          }),
          _buildDivider(),
          _buildBitrateOption('W-LAN', _wifiQuality, (value) async {
            setState(() {
              _wifiQuality = value;
            });
            // Automatisch speichern nach Änderung (nur lokal)
            await _saveBitrateSettings();
          }),
          
          // FAVORITEN Sektion
          _buildSectionHeader('FAVORITEN'),
          _buildSwitchOption(
            'App starten mit TV Favoriten', 
            _startWithFavorites, 
            (value) async {
              setState(() {
                _startWithFavorites = value;
              });
              // Nur lokal speichern ohne Server-Update
              if (_settings != null) {
                Map<String, dynamic> localSettings = Map<String, dynamic>.from(_settings!);
                localSettings['start_with_favorites'] = value;
                await _storageService.saveUserSettings(localSettings);
              }
            }
          ),
          
          // INFORMATION Sektion
          _buildSectionHeader('INFORMATION'),
          _buildNavigationOption('Hilfe'),
          _buildDivider(),
          _buildNavigationOption('Datenschutz'),
          _buildDivider(),
          _buildNavigationOption('AGB'),
          _buildVersionInfo(),
          
          // Abstand am Ende
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  // Hilfsmethoden für die UI-Elemente
  Widget _buildSectionHeader(String title) {
    return Container(
      color: const Color(0xFF252A2E),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFF8D9296), fontSize: 14),
      ),
    );
  }
  
  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey[900],
    );
  }
  
  Widget _buildBitrateOption(String title, String currentValue, Function(String) onChanged) {
    return InkWell(
      onTap: () {
        _showBitrateSelector(title, currentValue, onChanged);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Row(
              children: [
                Text(
                  currentValue,
                  style: const TextStyle(color: Color(0xFF8D9296), fontSize: 16),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFF8D9296)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSwitchOption(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green,
            activeTrackColor: Colors.green.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavigationOption(String title) {
    return InkWell(
      onTap: () {
        // Navigation zur entsprechenden Seite
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title Seite wird geöffnet')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF8D9296)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVersionInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Version',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          Text(
            _appVersion,
            style: const TextStyle(color: Color(0xFF8D9296), fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  void _showBitrateSelector(String title, String currentValue, Function(String) onChanged) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF252A2E),
          title: Text(
            'Qualität für $title',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _bitrateOptions.map((option) {
              return ListTile(
                title: Text(
                  option,
                  style: TextStyle(
                    color: option == currentValue ? const Color(0xFFA1273B) : Colors.white,
                    fontWeight: option == currentValue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  onChanged(option);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }


}
