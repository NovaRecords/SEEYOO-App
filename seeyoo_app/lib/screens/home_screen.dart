import 'package:flutter/material.dart';
import 'package:seeyoo_app/screens/account_screen.dart';
import 'package:seeyoo_app/screens/movies_series_screen.dart';
import 'package:seeyoo_app/screens/music_screen.dart';
import 'package:seeyoo_app/screens/radio_screen.dart';
import 'package:seeyoo_app/screens/settings_screen.dart';
import 'package:seeyoo_app/screens/tv_favorite_screen.dart';
import 'package:seeyoo_app/screens/tv_screen.dart';
import 'package:seeyoo_app/widgets/background_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('SEEYOO'),
        backgroundColor: Colors.black,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SEEYOO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.live_tv,
              title: 'TV',
              screen: const TvScreen(),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.favorite,
              title: 'TV-Favorite',
              screen: const TvFavoriteScreen(),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.movie,
              title: 'Filme & Serien',
              screen: const MoviesSeriesScreen(),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.music_note,
              title: 'Musik',
              screen: const MusicScreen(),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.radio,
              title: 'Online Radio',
              screen: const RadioScreen(),
            ),
            const Divider(color: Colors.grey),
            _buildDrawerItem(
              context: context,
              icon: Icons.settings,
              title: 'Einstellungen',
              screen: const SettingsScreen(),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.person,
              title: 'Mein Konto',
              screen: const AccountScreen(),
            ),
          ],
        ),
      ),
      body: const BackgroundImage(
        imagePath: 'assets/images/HG.png',
        child: Center(
          child: Text(
            'Willkommen bei SEEYOO',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget screen,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }
}
