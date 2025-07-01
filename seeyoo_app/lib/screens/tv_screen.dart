import 'package:flutter/material.dart';

class TvScreen extends StatefulWidget {
  const TvScreen({super.key});

  @override
  State<TvScreen> createState() => _TvScreenState();
}

class _TvScreenState extends State<TvScreen> {
  int _selectedTabIndex = 0;
  int _selectedChannelIndex = 0; // Index des ausgewählten Kanals
  List<bool> _favoriteChannels = []; // Liste zur Verfolgung der Favoriten
  final List<String> _tabTitles = ['Programm', 'Mediathek', 'Kategorien', 'Favoriten'];
  final List<IconData> _tabIcons = [
    Icons.list_alt, // Programm
    Icons.video_library, // Mediathek
    Icons.grid_view, // Kategorien
    Icons.star_border // Favoriten - wird dynamisch aktualisiert
  ];
  
  // Gibt das passende Stern-Icon zurück (gefüllt oder leer)
  IconData _getFavoriteIcon() {
    // Wenn ein Kanal ausgewählt ist und dieser als Favorit markiert ist, zeige gefüllten Stern
    if (_selectedChannelIndex >= 0 && 
        _selectedChannelIndex < _favoriteChannels.length && 
        _favoriteChannels[_selectedChannelIndex]) {
      return Icons.star;
    }
    return Icons.star_border;
  }

  // Beispieldaten für TV-Kanäle - werden später durch API-Daten ersetzt
  final List<Map<String, dynamic>> _channels = [
    {
      'logo': 'https://via.placeholder.com/50',
      'name': 'ProSieben',
      'currentShow': '2 Broke Girls',
      'time': '13:24',
      'nextShow': 'Two and a Half Men',
      'isLive': true,
    },
    {
      'logo': 'https://via.placeholder.com/50',
      'name': 'COMEDY',
      'currentShow': 'Futurama',
      'time': '13:20',
      'nextShow': 'Family Guy',
      'isLive': true,
    },
    {
      'logo': 'https://via.placeholder.com/50',
      'name': 'RTL',
      'currentShow': 'Punkt 12',
      'time': '14:00',
      'nextShow': 'Der Blaulicht Report',
      'isLive': true,
    },
    {
      'logo': 'https://via.placeholder.com/50',
      'name': 'RTL II',
      'currentShow': 'Die Geissens',
      'time': '13:01',
      'nextShow': 'Family Stories',
      'isLive': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialisiere die Favoriten-Liste mit false für jeden Kanal
    _favoriteChannels = List.generate(_channels.length, (index) => false);
  }

  // Funktion zum Umschalten des Favoriten-Status des ausgewählten Kanals
  void _toggleFavorite() {
    if (_selectedChannelIndex >= 0 && _selectedChannelIndex < _channels.length) {
      setState(() {
        _favoriteChannels[_selectedChannelIndex] = !_favoriteChannels[_selectedChannelIndex];
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Bildschirmdimensionen abrufen, um die UI responsiv zu gestalten
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    // Größenanpassung für Tesla-Bildschirme im Querformat
    final playerHeight = isLandscape ? screenHeight * 0.4 : screenHeight * 0.3;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Video-Player-Bereich
          Container(
            height: playerHeight,
            width: double.infinity,
            color: Colors.black54,
            child: Stack(
              children: [
                // Video-Player-Platzhalter
                Center(
                  child: Image.network(
                    'https://via.placeholder.com/800x450',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.error,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
                // Hier werden später Video-Steuerelemente hinzugefügt.
              ],
            ),
          ),
          
          // Navigationsleiste
          Container(
            height: 90, // Erhöhte Höhe um Überlauf zu vermeiden
            color: const Color(0xFF1B1E22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                _tabTitles.length,
                (index) => GestureDetector(
                  onTap: () {
                    setState(() {
                      // Wenn Favoriten-Tab gewählt und vorher ein anderer Tab aktiv war
                      if (index == 3 && _selectedTabIndex != 3) {
                        _toggleFavorite();
                      }
                      // Wenn Favoriten-Tab bereits aktiv war, deaktiviere Favorit
                      else if (index == 3 && _selectedTabIndex == 3) {
                        _toggleFavorite();
                      }
                      _selectedTabIndex = index;
                    });
                  },
                  child: Container(
                    width: screenWidth / _tabTitles.length,
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Symbol in einem rechteckigen Container
                        Container(
                          width: 70,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B4248), // Feste Farbe für alle Rechtecke
                            border: Border.all(
                              color: Colors.grey[700]!,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Icon(
                              // Für Favoriten-Tab das dynamische Icon verwenden
                              index == 3 ? _getFavoriteIcon() : _tabIcons[index],
                              color: _selectedTabIndex == index ? Colors.white : Colors.grey, // Ausgewähltes Symbol weiß, andere grau
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tabTitles[index],
                          style: TextStyle(
                            color: _selectedTabIndex == index ? Colors.white : Colors.grey,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Kanalliste
          Expanded(
            child: ListView.builder(
              itemCount: _channels.length,
              itemBuilder: (context, index) {
                final channel = _channels[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedChannelIndex = index;
                    });
                  },
                  child: Stack(
                    children: [
                      Container(
                      height: 80,
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: index == _selectedChannelIndex ? const Color(0xFF3B4248) : const Color(0xFF1B1E22),
                      ),
                      child: Row(
                    children: [
                      // Kanallogo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 64,
                          height: 64,
                          color: Colors.white,
                          child: Image.network(
                            channel['logo'],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.tv,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Kanalinformationen
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                if (channel['isLive'])
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE53A56),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'JETZT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    channel['currentShow'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  channel['time'],
                                  style: const TextStyle(
                                    color: Color(0xFFE53A56),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    channel['nextShow'],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                      ),
                      // Favoriten-Stern, wenn der Kanal als Favorit markiert ist
                      if (_favoriteChannels[index])
                        Positioned(
                          right: 16,
                          top: 28, // Vertikal mittig positioniert (80px Höhe/2 - Iconsize/2)
                          child: Icon(
                            Icons.star,
                            color: const Color(0xFFE53A56),
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
