import 'package:flutter/material.dart';
import 'package:seeyoo_app/models/user.dart';
import 'package:seeyoo_app/services/api_service.dart';
import 'package:seeyoo_app/services/storage_service.dart';
import 'package:seeyoo_app/screens/auth_screen.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  late FocusNode _focusNode;
  bool _isLoading = false;
  User? _user;
  bool _isLoadingUserInfo = true;
  
  // Geräteinformationen
  String _platform = '';
  String _systemVersion = '';
  String _model = '';
  String _currentMacAddress = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _loadUserInfo();
    _loadDeviceInfo();
  }
  
  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Wenn die Seite den Fokus bekommt, aktualisiere die Benutzerdaten
      _loadUserInfo();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App wurde wieder in den Vordergrund gebracht
      _loadUserInfo();
    }
  }
  
  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    print('### _loadUserInfo: Start loading user info');
    setState(() {
      _isLoadingUserInfo = true;
    });

    try {
      // Benutzer-ID aus dem Speicher abrufen, um zu überprüfen, ob sie verfügbar ist
      final userId = await _storageService.getUserId();
      print('### _loadUserInfo: Retrieved user ID: $userId');
      
      // Immer aktuelle Daten vom Server holen
      print('### _loadUserInfo: Calling getUserInfo()');
      _user = await _apiService.getUserInfo();
      print('### _loadUserInfo: getUserInfo returned: ${_user != null ? 'User data received' : 'NULL - No user data'}');
      
      // Aktualisierte Daten im lokalen Speicher speichern
      if (_user != null) {
        await _storageService.saveUser(_user!);
        print('### _loadUserInfo: User data saved to storage');
      } else {
        print('### _loadUserInfo: No user data to save');
      }
    } catch (e, stackTrace) {
      print('### _loadUserInfo: Exception during loading: $e');
      print('### _loadUserInfo: Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden der Benutzerdaten: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUserInfo = false;
        });
        print('### _loadUserInfo: Loading complete, isLoading set to false');
      }
    }
  }

  Future<void> _loadDeviceInfo() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        setState(() {
          _platform = 'Android';
          _systemVersion = 'Android ${androidInfo.version.release}';
          _model = '${androidInfo.brand} ${androidInfo.model}';
        });
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        setState(() {
          _platform = 'iOS';
          _systemVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
          _model = iosInfo.model ?? 'Unbekannt';
        });
      } else {
        setState(() {
          _platform = 'Unbekannt';
          _systemVersion = 'Unbekannt';
          _model = 'Unbekannt';
        });
      }
    } catch (e) {
      print('Fehler beim Laden der Geräteinformationen: $e');
      setState(() {
        _platform = 'Fehler';
        _systemVersion = 'Fehler';
        _model = 'Fehler';
      });
    }
  }

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
    return Focus(
      focusNode: _focusNode,
      child: Scaffold(
        backgroundColor: const Color(0xFF1B1E22),
        body: _isLoadingUserInfo
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFA1273B)))
            : _user == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Benutzerdaten konnten nicht geladen werden',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Button zum erneuten Laden der Benutzerdaten
                    ElevatedButton.icon(
                      onPressed: _loadUserInfo,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Erneut versuchen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA1273B), // SEEYOO Brand-Farbe
                        minimumSize: const Size(200, 48), // Touch-optimiert
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Login Button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const AuthScreen()),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Anmelden'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA1273B), // Rot (Markenfarbe)
                        minimumSize: const Size(200, 48), // Touch-optimiert
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Logout-Button - immer sichtbar
                    ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'Abmelden',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                        minimumSize: const Size(200, 48), // Touch-optimiert
                      ),
                    ),
                  ],
                )  
              : _buildUserProfile(),
      ),
    );
  }

  Widget _buildUserProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profilkopf mit Benutzerinformationen
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF3B4248),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Benutzer-Avatar mit Initialen
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFA1273B),
                    child: Text(
                      _user?.fname?.isNotEmpty == true
                          ? _user!.fname![0].toUpperCase()
                          : 'S',
                      style: const TextStyle(color: Colors.white, fontSize: 40),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Vollständiger Benutzername (Vorname + Nachname)
                  Text(
                    _getFullName(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status (aktiv/inaktiv)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _user?.status == 1 ? Colors.green[800] : Colors.red[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _user?.status == 1 ? 'Account aktiv' : 'Account deaktiviert',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Detailinformationen
          const Center(
            child: Text(
              'Kontoinformationen',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(color: Color(0xFF3B4248)),
          _buildInfoItem('E-Mail:', _formatEmail(_user?.email ?? 'Nicht angegeben')),
          _buildInfoItem('vMAC:', _user?.mac ?? 'Nicht angegeben'),
          _buildInfoItem('Tarif:', _user?.tariffPlan ?? 'Standard'),
          if (_user?.endDate != null)
            _buildInfoItem('Aktiv bis:', _formatDate(_user?.endDate)),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Geräteinformationen',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(color: Color(0xFF3B4248)),
          _buildInfoItem('OS Version:', _systemVersion.isNotEmpty ? _systemVersion : 'Lade...'),
          _buildInfoItem('Gerät:', _model.isNotEmpty ? _model : 'Lade...'),
          const SizedBox(height: 20),
          // Ausloggen-Button
          Center(
            child: SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA1273B),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20), // Zusätzlicher Abstand am unteren Rand
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Color(0xFF8D9296), fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // E-Mail nach 20 Zeichen umbrechen für bessere Darstellung
  String _formatEmail(String email) {
    if (email.length <= 20) {
      return email;
    }
    
    // Suche nach einem guten Umbruchpunkt (@ oder .)
    int breakPoint = 20;
    
    // Versuche bei @ zu brechen wenn es in der Nähe ist
    int atIndex = email.indexOf('@');
    if (atIndex > 0 && atIndex <= 25) {
      breakPoint = atIndex;
    }
    
    return email.substring(0, breakPoint) + '\n' + email.substring(breakPoint);
  }

  // Einfach den vollständigen Namen aus dem Portal-fname-Feld zurückgeben
  String _getFullName() {
    // Das Portal liefert bereits den vollständigen Namen im fname-Feld
    return _user?.fname ?? 'SEEYOO Nutzer';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Nicht angegeben';
    
    String result = dateStr;
    
    // Prüfen auf russische Tagesangaben wie "329 дней"
    final RegExp daysPattern = RegExp(r'(\d+)\s*дней');
    final match = daysPattern.firstMatch(dateStr);
    if (match != null) {
      final days = match.group(1);
      // Ersetze nur den russischen Teil, behalte den Rest bei
      result = dateStr.replaceAll(match.group(0)!, '$days Tage');
    }
    
    try {
      // Versuche ein Datum aus dem String zu parsen
      final RegExp datePattern = RegExp(r'\d{4}-\d{2}-\d{2}');
      final dateMatch = datePattern.firstMatch(dateStr);
      if (dateMatch != null) {
        final dateString = dateMatch.group(0)!;
        final date = DateTime.parse(dateString);
        final formattedDate = DateFormat('dd.MM.yyyy').format(date);
        result = result.replaceAll(dateString, formattedDate);
      }
      return result;
    } catch (e) {
      return result;
    }
  }


}
