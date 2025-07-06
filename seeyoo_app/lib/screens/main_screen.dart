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

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Controller speziell für den Bounce-Effekt
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  bool _useBounceClosure = false;
  final double _menuWidth = 0.75; // Menü nimmt 75% der Breite ein, wenn geöffnet

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
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Prüfe die anfängliche Route
      final route = ModalRoute.of(context)?.settings.name;
      if (route != null) {
        setState(() {
          _selectedIndex = _getScreenIndex(route);
        });
      } else {
        // Standardmäßig zur Hauptseite navigieren, wenn keine Route gesetzt ist
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
  @override
  void dispose() {
    _animationController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const TvScreen(),
    const TvFavoriteScreen(),
    const MoviesSeriesScreen(),
    const MusicScreen(),
    const RadioScreen(),
    const SettingsScreen(),
    const AccountScreen(),
  ];
  
  int _getScreenIndex(String routeName) {
    switch (routeName) {
      case '/settings':
        return 5;
      case '/account':
        return 6;
      default:
        return 0;
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
    // Menü definitiv schließen nach Auswahl
    _closeMenu();
  }

  // Umschalten des Menüs
  void _toggleMenu() {
    if (_animationController.isDismissed) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  // Funktion zum Schließen des Menüs
  void _closeMenu({bool fromMenuItem = false}) {
    // Schließe das Menü nur, wenn es geöffnet ist
    if (_animationController.value > 0) {
      if (fromMenuItem) {
        // Menüpunkt wurde ausgewählt - Bounce-Animation verwenden
        _useBounceClosure = true;
        
        // Aktuelle Position des Menüs speichern
        double currentPos = _animationController.value;
        
        // Wir erstellen eine speziell angepasste Bounce-Animation mit einem TweenSequence
        _bounceAnimation = TweenSequence<double>([
          // Phase 1: Von aktueller Position 20% weiter nach rechts (Bounce-Effekt)
          TweenSequenceItem<double>(
            tween: Tween<double>(
              begin: currentPos,
              end: currentPos * 1.1, // 10% Überschwung von der aktuellen Position
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 50.0,
          ),
          // Phase 2: Von der Bounce-Position komplett zurück nach links (geschlossen)
          TweenSequenceItem<double>(
            tween: Tween<double>(
              begin: currentPos * 1.1, // Von der Bounce-Position mit 10% Überschwung
              end: 0.0, // Ganz nach links (geschlossen)
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 50.0,
          ),
        ]).animate(_bounceController);
        
        // Standard-Slide-Animation stoppen
        _animationController.stop();
        
        // Bounce-Controller zurücksetzen und starten
        _bounceController.reset();
        _bounceController.forward();
      } else {
        // Normales Schließen ohne Bounce
        _useBounceClosure = false;
        _animationController.reverse();
      }
    }
  }
  
  Widget _buildMenu() {
    return Material(
      color: Colors.transparent,
      child: Container(
        // Menübreite erhöht um den maximalen Überschwung (20%) zu berücksichtigen
        width: MediaQuery.of(context).size.width * _menuWidth * 1.2,
        color: const Color(0xFF1B1E22),
        child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 110, // Feste Höhe für den Header
            color: const Color(0xFF1B1E22), // Gleiche Farbe wie der Menü-Hintergrund
            padding: const EdgeInsets.only(left: 16.0, top: 65.0), // Verschiebt das Logo nach unten und links
            alignment: Alignment.topLeft, // Positioniert das Logo links oben im Container
            child: Container(
              height: 35, // Höhe des Logos
              child: Image.asset(
                'assets/images/App-Logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.live_tv,
            title: 'Live-TV',
            index: 0,
            isSelected: _selectedIndex == 0,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.star,
            title: 'TV-Favorite',
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
          // Trennlinie entfernt
          _buildDrawerItem(
            context: context,
            icon: Icons.settings,
            title: 'Einstellungen',
            index: 5,
            isSelected: _selectedIndex == 5,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.person,
            title: 'Mein Konto',
            index: 6,
            isSelected: _selectedIndex == 6,
          ),
        ],
      ),
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
    final selectedColor = const Color(0xFFE53A56);
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF3B4248) : null, // Hintergrundfarbe für ausgewählten Menüpunkt
        border: Border(
          left: BorderSide(
            color: isSelected ? selectedColor : Colors.transparent, // Rote Farbe oder transparent
            width: 4.0, // Gleiche Breite bei allen Menüpunkten
          ),
        ),
      ),
      child: ListTile(
        leading: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(0, -1), // 1px nach oben verschieben
              child: Icon(
                icon, 
                color: isSelected ? Colors.white : const Color(0xFF8D9296),
                size: 28.0,
              ),
            ),
          ],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF8D9296),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 18.0, // Größere Schrift für bessere Lesbarkeit
            height: 1.2, // Etwas mehr Zeilenabstand
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0), // Angepasster Rand wegen Border
        minLeadingWidth: 36, // Mehr Platz für die größeren Icons
        minVerticalPadding: 6.0, // Mehr vertikaler Abstand
        onTap: () {
          // Unterscheiden zwischen bereits ausgewähltem und neuem Menüpunkt
          if (_selectedIndex == index) {
            // BEREITS AUSGEWÄHLTER Menüpunkt: Sanft schließen ohne Bounce
            _useBounceClosure = false;  // Wichtig: KEIN Bounce-Effekt verwenden
            
            // Verwende die reguläre _closeMenu-Methode, aber ohne Bounce
            // Dies stellt sicher, dass alle Status korrekt aktualisiert werden
            _closeMenu(fromMenuItem: false);
            
            // Passe die Animationsdauer für sanftere Bewegung an
            _animationController.duration = const Duration(milliseconds: 400);
          } else {
            // NEUER Menüpunkt: Mit Bounce-Effekt schließen
            _closeMenu(fromMenuItem: true);
            
            // Aktualisiere den ausgewählten Index
            setState(() {
              _selectedIndex = index;
            });
            
            // Stelle sicher, dass die Animationsdauer zurückgesetzt wird
            _animationController.duration = const Duration(milliseconds: 250);
          }
        },
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
                          appBar: AppBar(
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
        return 'TV-Favorite';
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
