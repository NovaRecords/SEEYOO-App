import 'package:flutter/material.dart';
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

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1B1E22),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 140, // Feste Höhe für den Header
            color: Colors.black,
            padding: const EdgeInsets.only(left: 16.0, top: 80.0), // Verschiebt das Logo nach unten und links
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
            icon: Icons.star,  // Geändert von Icons.favorite zu Icons.star
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
    return ListTile(
      leading: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -1), // 1px nach oben verschieben
            child: Icon(
              icon, 
              color: isSelected ? selectedColor : Colors.white,
              size: 28.0,
            ),
          ),
        ],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? selectedColor : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 18.0, // Größere Schrift für bessere Lesbarkeit
          height: 1.2, // Etwas mehr Zeilenabstand
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0), // Mehr Platz um die Einträge
      minLeadingWidth: 36, // Mehr Platz für die größeren Icons
      minVerticalPadding: 6.0, // Mehr vertikaler Abstand
      tileColor: isSelected ? const Color(0xFF252A2F) : null,
      onTap: () {
        // Schließe das Drawer-Menü
        Navigator.pop(context);
        
        // Aktualisiere den ausgewählten Index
        if (_selectedIndex != index) {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
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
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          drawerScrimColor: Colors.black54, // Leichter Schleier über dem Hintergrund, wenn das Menü geöffnet ist
          drawer: _buildDrawer(),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 30.0),  //größer als Standard (24.0)
                onPressed: () {
                  if (_scaffoldKey.currentState!.isDrawerOpen) {
                    Navigator.pop(context);
                  } else {
                    _scaffoldKey.currentState!.openDrawer();
                  }
                },
              ),
            ),
            title: Text(
              _getAppBarTitle(_selectedIndex),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: _screens[_selectedIndex],
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
