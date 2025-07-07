import 'package:flutter/material.dart';
import 'package:seeyoo_app/models/user.dart';
import 'package:seeyoo_app/services/api_service.dart';
import 'package:seeyoo_app/services/storage_service.dart';
import 'package:seeyoo_app/screens/auth_screen.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _loadUserInfo();
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
    setState(() {
      _isLoadingUserInfo = true;
    });

    try {
      // Immer aktuelle Daten vom Server holen
      _user = await _apiService.getUserInfo();
      
      // Aktualisierte Daten im lokalen Speicher speichern
      if (_user != null) {
        await _storageService.saveUser(_user!);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden der Benutzerdaten: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUserInfo = false;
        });
      }
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
                ? const Center(
                    child: Text(
                      'Benutzerdaten konnten nicht geladen werden',
                      style: TextStyle(color: Colors.white),
                    ),
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
                  // Vollständiger Benutzername
                  Text(
                    _user?.fname ?? 'SEEYOO Nutzer',
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
                      _user?.status == 1 ? 'Aktiv' : 'Inaktiv',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Detailinformationen
          const Center(
            child: Text(
              'Kontoinformationen',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(color: Color(0xFF3B4248)),
          _buildInfoItem('E-Mail', _user?.email ?? 'Nicht angegeben'),
          _buildInfoItem('Telefon', _user?.phone ?? 'Nicht angegeben'),
          _buildInfoItem('Tarif', _user?.tariffPlan ?? 'Standard'),
          if (_user?.endDate != null)
            _buildInfoItem('Ablaufdatum', _formatDate(_user?.endDate)),
          if (_user?.accountBalance != null)
            _buildInfoItem('Kontostand', '${_user?.accountBalance} €'),
          const SizedBox(height: 24),
          // Technische Informationen
          const Center(
            child: Text(
              'Technische Informationen',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(color: Color(0xFF3B4248)),
          _buildInfoItem('User ID', _user?.id.toString() ?? '-'),
          _buildInfoItem('MAC-Adresse', _user?.mac ?? '-'),
          const SizedBox(height: 40),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 40), // Zusätzlicher Abstand am unteren Rand
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
              style: const TextStyle(color: Color(0xFF8D9296)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
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

  // Logo-Funktionalität entfernt, da nicht mehr benötigt
}
