import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:seeyoo_app/screens/account_screen.dart';
import 'package:seeyoo_app/screens/home_screen.dart';
import 'package:seeyoo_app/screens/movies_series_screen.dart';
import 'package:seeyoo_app/screens/music_screen.dart';
import 'package:seeyoo_app/screens/radio_screen.dart';
import 'package:seeyoo_app/screens/settings_screen.dart';
import 'package:seeyoo_app/screens/tv_favorite_screen.dart';
import 'package:seeyoo_app/screens/tv_screen.dart';
import 'package:seeyoo_app/services/storage_service.dart';
import 'package:seeyoo_app/services/appbar_visibility_service.dart';
import 'package:seeyoo_app/services/orientation_notifier.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // Service für die AppBar-Sichtbarkeit
  final AppBarVisibilityService _appBarVisibilityService = AppBarVisibilityService();
  final OrientationNotifier _orientationNotifier = OrientationNotifier();
  final StorageService _storageService = StorageService();
  
  // Flag für die Orientierung
  bool _isCurrentlyLandscape = false;
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Controller speziell für den Bounce-Effekt
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  bool _useBounceClosure = false;
  final double _menuWidth = 0.75; // Menü nimmt 75% der Breite ein, wenn geöffnet

  final List<Widget> _screens = [
    const TvScreen(),
    const TvFavoriteScreen(),
    const MoviesSeriesScreen(),
    const MusicScreen(),
    const RadioScreen(),
    const SettingsScreen(),
    const AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Systemstatusleiste anzeigen lassen (transparent)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent status bar
      statusBarIconBrightness: Brightness.light, // Status bar icons' color
    ));
    
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual, 
      overlays: [SystemUiOverlay.top] // Nur obere Statusleiste anzeigen
    );
    
    // Listener für den OrientationNotifier hinzufügen
    _orientationNotifier.addListener(_onOrientationChanged);
    
    // Haupt-Animation Controller für das Slide-Menü
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    // Standard-Animation für das Öffnen und normale Schließen des Menüs
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Spezieller Controller für den Bounce-Effekt
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Längere Dauer für einen deutlicheren Effekt
    );
    
    // Bounce-Animation definieren
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_bounceController);
    
    // Listener für den Bounce-Controller, um das Menü vollständig zu schließen
    _bounceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Bounce-Animation ist abgeschlossen, setze Flags zurück
        setState(() {
          _useBounceClosure = false;
          
          // Stelle sicher, dass der Hauptbildschirm vollständig geschlossen ist
          _animationController.value = 0.0;
        });
      }
    });
    
    // Listener für den Status der Animation hinzufügen, um die Statusleiste zu steuern
    _animationController.addStatusListener((status) {
      // Plattformspezifische Behandlung für die Statusleiste
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        // iOS: Originales Verhalten (Statusleiste beim Menü ausblenden)
        if (status == AnimationStatus.forward || status == AnimationStatus.completed) {
          // Menü wird geöffnet oder ist geöffnet -> Statusleiste ausblenden
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
        } else if (status == AnimationStatus.reverse || status == AnimationStatus.dismissed) {
          // Menü wird geschlossen oder ist geschlossen -> Statusleiste anzeigen
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual, 
            overlays: [SystemUiOverlay.top]
          );
        }
      } else {
        // Android: Statusleiste immer sichtbar lassen
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual, 
          overlays: [SystemUiOverlay.top]
        );
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Prüfe auf TV-Favoriten-Start-Einstellung
      final settings = await _storageService.getUserSettings();
      final startWithFavorites = settings?['start_with_favorites'] ?? false;
      
      // Prüfe die anfängliche Route
      final route = ModalRoute.of(context)?.settings.name;
      if (route != null) {
        setState(() {
          _selectedIndex = _getScreenIndex(route);
        });
      } else if (startWithFavorites) {
        // Wenn die Einstellung aktiviert ist, starte mit TV-Favoriten (Index 1)
        setState(() {
          _selectedIndex = 1; // Index 1 entspricht TvFavoriteScreen
        });
      } else {
        // Standardmäßig zur Hauptseite (TV-Screen) navigieren
        setState(() {
          _selectedIndex = 0;
        });
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Aktualisiere den ausgewählten Index, wenn sich die Route ändert
    final route = ModalRoute.of(context)?.settings.name;
    if (route != null) {
      final newIndex = _getScreenIndex(route);
      if (newIndex != _selectedIndex) {
        setState(() {
          _selectedIndex = newIndex;
        });
      }
    }
  }
  
  // Reagiert auf Änderungen der Orientierung
  void _onOrientationChanged() {
    setState(() {
      _isCurrentlyLandscape = _orientationNotifier.isLandscape;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bounceController.dispose();
    // OrientationNotifier-Listener entfernen
    _orientationNotifier.removeListener(_onOrientationChanged);
    super.dispose();
  }

  // Hilfsfunktion zum Bestimmen des Screen-Index anhand des Routen-Namens
  int _getScreenIndex(String routeName) {
    if (routeName == '/tv') return 0;
    if (routeName == '/tv-favorites') return 1;
    if (routeName == '/movies-series') return 2;
    if (routeName == '/music') return 3;
    if (routeName == '/radio') return 4;
    if (routeName == '/settings') return 5;
    if (routeName == '/account') return 6;
    return 0; // Standard: TV-Screen
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Schließe das Menü nach der Auswahl
    _closeMenu(fromMenuItem: true);
  }

  void _toggleMenu() {
    if (_animationController.isDismissed) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _closeMenu({bool fromMenuItem = false}) {
    if (_animationController.status == AnimationStatus.completed) {
      if (fromMenuItem) {
        // Nur wenn das Menü durch Klick auf einen Menüpunkt geschlossen wird
        // verwenden wir die spezielle Bounce-Animation
        
        // Setze Flag für Bounce-Animation
        setState(() {
          _useBounceClosure = true;
        });
        
        // Setze den Controller zurück und starte die Animation
        _bounceController.reset();
        _bounceController.forward();
      } else {
        // Reguläres Schließen (z.B. durch Klick auf den Hauptinhalt)
        _animationController.reverse();
      }
    }
  }

  Widget _buildMenu() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF282C30), // Dunkelgrauer Hintergrund für das Menü
      padding: const EdgeInsets.only(top: 80), // Abstand nach oben
      child: Column(
        children: [
          // Benutzerprofil / Avatar (optional)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                // Avatar-Bild (optional)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE53A56), width: 2),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/avatar.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Benutzername
                const Text(
                  "Benutzer",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                // E-Mail oder andere Benutzerdetails
                const Text(
                  "benutzer@example.com",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Trennlinie
          const Divider(
            height: 1,
            thickness: 1,
            indent: 20,
            endIndent: 20,
            color: Color(0xFF3B4248),
          ),
          const SizedBox(height: 20),
          // Menüpunkte
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.tv,
                  title: 'Live-TV',
                  index: 0,
                  isSelected: _selectedIndex == 0,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.star,
                  title: 'TV-Favoriten',
                  index: 1,
                  isSelected: _selectedIndex == 1,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.movie,
                  title: 'Filme & Serien',
                  index: 2,
                  isSelected: _selectedIndex == 2,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.music_note,
                  title: 'Musik',
                  index: 3,
                  isSelected: _selectedIndex == 3,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.radio,
                  title: 'Online Radio',
                  index: 4,
                  isSelected: _selectedIndex == 4,
                ),
                const SizedBox(height: 20),
                // Zweite Trennlinie für Einstellungen und Konto
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                  color: Color(0xFF3B4248),
                ),
                const SizedBox(height: 20),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings,
                  title: 'Einstellungen',
                  index: 5,
                  isSelected: _selectedIndex == 5,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.account_circle,
                  title: 'Mein Konto',
                  index: 6,
                  isSelected: _selectedIndex == 6,
                ),
              ],
            ),
          ),
          // Version oder Copyright-Info am unteren Rand (optional)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Version 1.0.0",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
    required bool isSelected,
  }) {
    // Gemeinsame Stilelemente
    final Color indicatorColor = const Color(0xFFE53A56); // Rot für den linken Streifen bei ausgewählten Items
    final Color selectedBgColor = const Color(0xFF3B4248); // Grauer Hintergrund für ausgewählte Items
    
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? indicatorColor : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 24),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Wenn das Menü geöffnet ist, schließe es zuerst
        if (_animationController.status == AnimationStatus.completed) {
          _animationController.reverse();
          return false;
        }
        // Verhindere das Navigieren zurück zum SplashScreen
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0; // Zurück zum ersten Tab
          });
          return false; // Verhindere das Standardverhalten
        }
        return true; // Erlaube die Standard-Navigation (App schließen)
      },
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/HG2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // 1. Menü im Hintergrund (immer da)
            _buildMenu(),
            
            // 2. Hauptbildschirm, der zur Seite animiert wird
            AnimatedBuilder(
              // Animation auf Basis des aktiven Controllers auswählen
              animation: _useBounceClosure ? _bounceController : _animationController,
              builder: (context, child) {
                // Berechne die aktuelle Offset-Position
                double offsetX;
                
                if (_useBounceClosure) {
                  // Wenn die Bounce-Animation aktiv ist
                  offsetX = _bounceAnimation.value;
                } else {
                  // Standard-Animation für normale Bewegungen
                  offsetX = _animation.value;
                }
                
                return GestureDetector(
                  // Erkennung von Swipe-Gesten
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 0) {
                      // Swipe nach rechts - Menü öffnen
                      _animationController.forward();
                    } else if (details.primaryVelocity! < 0) {
                      // Swipe nach links - Menü schließen
                      _animationController.reverse();
                    }
                  },
                  child: Transform.translate(
                    offset: Offset(
                      MediaQuery.of(context).size.width * _menuWidth * offsetX,
                      0,
                    ),
                    child: Material(
                      elevation: 8.0,
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(-2, 0),
                            ),
                          ],
                        ),
                        child: Scaffold(
                          backgroundColor: const Color(0xFF1B1E22), // Undurchsichtiger Hintergrund
                          extendBodyBehindAppBar: false, // Verhindert, dass der Body hinter den AppBar reicht
                          appBar: !_isCurrentlyLandscape ? AppBar(
                            backgroundColor: const Color(0xFF1B1E22), // Feste Farbe statt transparent
                            elevation: 0,
                            scrolledUnderElevation: 0, // Deaktiviert Elevation-Änderung beim Scrollen
                            shadowColor: Colors.transparent, // Keine Schatten
                            leading: IconButton(
                              icon: AnimatedIcon(
                                icon: AnimatedIcons.menu_close,
                                progress: _animation,
                                color: Colors.white,
                                size: 30.0,
                              ),
                              onPressed: _toggleMenu,
                            ),
                            title: Text(
                              _getAppBarTitle(_selectedIndex),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            centerTitle: true,
                          ) : PreferredSize(
                            preferredSize: const Size.fromHeight(0),
                            child: Container(),
                          ),
                          body: GestureDetector(
                            onTap: _closeMenu,  // Schließt Menü bei Tippen auf den Hauptinhalt
                            child: _screens[_selectedIndex],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Live-TV';
      case 1:
        return 'TV-Favoriten';
      case 2:
        return 'Filme & Serien';
      case 3:
        return 'Musik';
      case 4:
        return 'Online Radio';
      case 5:
        return 'Einstellungen';
      case 6:
        return 'Mein Konto';
      default:
        return 'SEEYOO';
    }
  }
}
