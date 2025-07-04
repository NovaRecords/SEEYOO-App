import 'package:flutter/material.dart';
import 'package:seeyoo_app/models/epg_program.dart';
import 'package:seeyoo_app/models/tv_channel.dart';
import 'package:seeyoo_app/models/tv_genre.dart';
import 'package:seeyoo_app/services/api_service.dart';

class TvScreen extends StatefulWidget {
  const TvScreen({super.key});

  @override
  State<TvScreen> createState() => _TvScreenState();
}

class _TvScreenState extends State<TvScreen> {
  int _selectedTabIndex = -1; // -1 bedeutet kein Tab ist ausgewählt
  int _selectedChannelIndex = 0; // Index des ausgewählten Kanals
  final List<String> _tabTitles = ['Programm', 'Mediathek', 'Kategorien', 'Favoriten'];
  final List<IconData> _tabIcons = [
    Icons.list_alt, // Programm
    Icons.video_library, // Mediathek
    Icons.grid_view, // Kategorien
    Icons.star_border // Favoriten - wird dynamisch aktualisiert
  ];
  
  final ApiService _apiService = ApiService();
  List<TvChannel> _channels = [];
  List<TvChannel> _favoriteChannels = [];
  List<EpgProgram> _currentEpgData = [];
  List<TvGenre> _genres = [];
  String? _selectedGenreId; // null bedeutet alle Kategorien
  List<TvChannel> _filteredChannels = [];
  bool _isLoading = true;
  bool _isLoadingEpg = false;
  bool _isLoadingGenres = false;
  String? _currentStreamUrl;
  String? _errorMessage;
  bool _showEpgView = false;
  bool _showGenresView = false;
  bool _showMediaLibraryMessage = false;
  
  // Gibt das passende Stern-Icon zurück (gefüllt oder leer)
  IconData _getFavoriteIcon() {
    if (_selectedChannelIndex >= 0 && _selectedChannelIndex < _channels.length) {
      // Prüfe, ob der ausgewählte Kanal in der Favoritenliste ist
      final selectedChannel = _channels[_selectedChannelIndex];
      return selectedChannel.favorite ? Icons.star : Icons.star_border;
    }
    return Icons.star_border;
  }

  @override
  void initState() {
    super.initState();
    _loadChannels();
    _loadGenres();
  }

  // Lädt TV-Kategorien/Genres aus der API
  Future<void> _loadGenres() async {
    setState(() {
      _isLoadingGenres = true;
    });
    
    try {
      final genres = await _apiService.getTvGenres();
      setState(() {
        _genres = genres;
        _isLoadingGenres = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGenres = false;
        _errorMessage = 'Fehler beim Laden der Kategorien: $e';
      });
    }
  }

  // Filtert Kanäle nach ausgewähltem Genre
  void _filterChannelsByGenre(String? genreId) {
    setState(() {
      _selectedGenreId = genreId;
      
      if (genreId == null || genreId == 'all') {
        _filteredChannels = List.from(_channels);
      } else {
        _filteredChannels = _channels
            .where((channel) => channel.genreId == genreId)
            .toList();
      }
    });
  }
  
  // Lädt TV-Kanäle aus der API
  Future<void> _loadChannels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Lade Kanäle vom API
      final channels = await _apiService.getTvChannels();
      final favoriteChannels = await _apiService.getFavoriteTvChannels();
      
      setState(() {
        _channels = channels;
        _favoriteChannels = favoriteChannels;
        _filteredChannels = List.from(channels); // Initialisiere gefilterte Liste mit allen Kanälen
        _isLoading = false;
      });
      
      // Wähle den ersten Kanal aus, wenn vorhanden
      if (_channels.isNotEmpty) {
        _selectChannel(0);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler beim Laden der Kanäle: $e';
      });
    }
  }

  // Wähle einen Kanal aus und lade den Stream
  void _selectChannel(int index) async {
    if (index >= 0 && index < _channels.length) {
      setState(() {
        _selectedChannelIndex = index;
        _currentStreamUrl = null; // Zurücksetzen, während wir laden
        _currentEpgData = []; // EPG-Daten zurücksetzen
        _showEpgView = false; // EPG-Ansicht ausblenden
      });
      
      // Lade den Stream-Link für diesen Kanal
      final channel = _channels[index];
      
      // Wenn die URL bereits im Kanal-Objekt vorhanden ist, verwende diese
      // Ansonsten hole sie über die API
      if (channel.url != null && channel.url!.isNotEmpty) {
        setState(() {
          _currentStreamUrl = channel.url!;
        });
      } else {
        try {
          final streamUrl = await _apiService.getTvChannelLink(channel.id);
          if (streamUrl != null) {
            setState(() {
              _currentStreamUrl = streamUrl;
            });
          } else {
            setState(() {
              _errorMessage = 'Kanal-Stream nicht verfügbar';
            });
          }
        } catch (e) {
          setState(() {
            _errorMessage = 'Fehler beim Laden des Kanal-Streams: $e';
          });
        }
      }
    }
  }

  // Funktion zum Umschalten des Favoriten-Status des ausgewählten Kanals
  void _toggleFavorite() async {
    if (_selectedChannelIndex >= 0 && _selectedChannelIndex < _channels.length) {
      final channel = _channels[_selectedChannelIndex];
      bool success;
      
      if (channel.favorite) {
        // Entferne von Favoriten
        success = await _apiService.removeChannelFromFavorites(channel.id);
      } else {
        // Füge zu Favoriten hinzu
        success = await _apiService.addChannelToFavorites(channel.id);
      }
      
      if (success) {
        // Aktualisiere lokalen Status
        setState(() {
          // Erstelle eine neue Liste mit allen Kanälen
          List<TvChannel> updatedChannels = List.from(_channels);
          // Aktualisiere den Favoriten-Status des ausgewählten Kanals
          updatedChannels[_selectedChannelIndex] = TvChannel(
            id: channel.id,
            name: channel.name,
            genreId: channel.genreId,
            number: channel.number,
            url: channel.url,
            archive: channel.archive,
            archiveRange: channel.archiveRange,
            pvr: channel.pvr,
            censored: channel.censored,
            favorite: !channel.favorite,
            logo: channel.logo,
            monitoringStatus: channel.monitoringStatus,
            currentShow: channel.currentShow,
            currentShowTime: channel.currentShowTime,
            nextShow: channel.nextShow,
            isLive: channel.isLive,
          );
          
          _channels = updatedChannels;
          
          // Aktualisiere Favoriten-Liste, wenn nötig
          if (_selectedTabIndex == 3) { // Favoriten-Tab
            _loadFavoriteChannels();
          }
        });
      }
    }
  }
  
  // Lädt nur die Favoriten-Kanäle
  Future<void> _loadFavoriteChannels() async {
    try {
      final favoriteChannels = await _apiService.getFavoriteTvChannels();
      setState(() {
        _favoriteChannels = favoriteChannels;
      });
    } catch (e) {
      // Fehlerbehandlung
      setState(() {
        _errorMessage = 'Fehler beim Laden der Favoriten: $e';
      });
    }
  }
  
  // Lädt EPG-Daten für den aktuell ausgewählten Kanal
  Future<void> _loadEpgData() async {
    if (_selectedChannelIndex < 0 || _selectedChannelIndex >= _channels.length) {
      return;
    }
    
    final channelId = _channels[_selectedChannelIndex].id;
    
    setState(() {
      _isLoadingEpg = true;
      _errorMessage = null;
    });
    
    try {
      // Nächste 20 Sendungen abrufen
      final epgData = await _apiService.getEpgForChannel(channelId, next: 20);
      
      // Nur aktuelle und zukünftige Sendungen behalten, keine Archiv-Sendungen
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final filteredEpgData = epgData
          .where((program) => program.end > now && !program.inArchive) // Sendungen, die noch nicht beendet und nicht im Archiv sind
          .toList();
      
      // Sendungen sortieren, damit aktuelle Sendung an erster Stelle steht
      filteredEpgData.sort((a, b) {
        // Prüfen, ob eine der Sendungen aktuell läuft
        final aIsRunning = a.isCurrentlyRunning;
        final bIsRunning = b.isCurrentlyRunning;
        
        if (aIsRunning && !bIsRunning) {
          return -1; // a kommt zuerst
        } else if (!aIsRunning && bIsRunning) {
          return 1; // b kommt zuerst
        } else {
          // Beide laufen oder beide laufen nicht, nach Startzeit sortieren
          return a.start.compareTo(b.start);
        }
      });
      
      setState(() {
        _currentEpgData = filteredEpgData;
        _isLoadingEpg = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEpg = false;
        _errorMessage = 'Fehler beim Laden des TV-Programms: $e';
      });
    }
  }
  

  
  // Baut die Ansicht für die Kategorien
  Widget _buildGenresView() {
    if (_isLoadingGenres) {
      return Container(
        color: const Color(0xFF1B1E22),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA1273B)),
          ),
        ),
      );
    }
    
    if (_genres.isEmpty) {
      return Container(
        color: const Color(0xFF1B1E22),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.category_outlined, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              Text(
                'Keine Kategorien verfügbar',
                style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      color: const Color(0xFF1B1E22),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _genres.length,
        itemBuilder: (context, index) {
          final genre = _genres[index];
          final isSelected = genre.id == _selectedGenreId || 
                            (genre.id == 'all' && _selectedGenreId == null);
          
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1B1E22),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[900]!,
                  width: 1,
                ),
              ),
            ),
            child: ListTile(
              title: Center(
                child: Text(
                  genre.title,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFA1273B) : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              selected: isSelected,
              onTap: () {
                // Bei Auswahl einer Kategorie die Kanalliste filtern
                _filterChannelsByGenre(genre.id == 'all' ? null : genre.id);
                
                // Tab auf "Kanalliste" wechseln, aber Genre-Filterung beibehalten
                setState(() {
                  _selectedTabIndex = -1; // Zurück zur normalen Kanalliste
                  _showGenresView = false;
                });
              },
            ),
          );
        },
      ),
    );
  }
  
  // Baut die Ansicht für die Mediathek-Meldung
  Widget _buildMediaLibraryMessage() {
    return Container(
      color: const Color(0xFF1B1E22),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'Mediathek-Funktion',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Diese Funktion befindet sich noch in der Entwicklung\nund wird mit dem nächsten Release verfügbar sein.',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  // Baut die EPG-Ansicht
  Widget _buildEpgView() {
    if (_isLoadingEpg) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA1273B)),
        ),
      );
    }
    
    if (_currentEpgData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'Programminfo wird demnächst verfügbar',
              style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Die elektronischen Programminformationen (EPG) werden in Kürze aktiviert.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }
    
    // Zeigt die EPG-Daten in einer Liste an
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        // EPG-Liste
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _currentEpgData.length,
            itemBuilder: (context, index) {
              final program = _currentEpgData[index];
              final isNowPlaying = program.isCurrentlyRunning;
              
              return Container(
                decoration: BoxDecoration(
                  color: isNowPlaying ? const Color(0xFF3B4248) : const Color(0xFF1B1E22),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[900]!,
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Zeitspanne
                    SizedBox(
                      width: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program.startTimeFormatted,
                            style: TextStyle(
                              color: isNowPlaying ? Colors.white : Colors.grey,
                              fontSize: 16,
                              fontWeight: isNowPlaying ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          Text(
                            '${program.durationMinutes} min',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Programminhalt
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // "JETZT"-Label über dem Programmtitel anzeigen
                          if (isNowPlaying)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: const BoxDecoration(
                                color: Color(0xFFA1273B),
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                              ),
                              child: const Text(
                                'JETZT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          // Programmtitel
                          Text(
                            program.name,
                            style: TextStyle(
                              color: isNowPlaying ? Colors.white : Colors.grey[300],
                              fontSize: 16,
                              fontWeight: isNowPlaying ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (program.inArchive) ...[  
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[800],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ARCHIV',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  // Baut die Kanal-Liste abhängig von den übergebenen Kanälen
  Widget _buildChannelList(List<TvChannel> channels) {
    if (channels.isEmpty) {
      return const Center(
        child: Text(
          'Keine Kanäle verfügbar',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    
    // Erstelle die Liste der Kanäle
    return ListView.builder(
      itemCount: channels.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final channel = channels[index];
        final isSelected = _selectedTabIndex != 3 ?
            channels[index].id == _channels[_selectedChannelIndex].id :
            index == _selectedChannelIndex;
        
        return GestureDetector(
          onTap: () {
            // Index im aktuellen channels-Array finden
            if (_selectedTabIndex == 3) { // Favoriten-Tab
              _selectChannel(index);
            } else {
              // Finde den Index des Kanals in der Hauptliste
              final mainIndex = _channels.indexWhere((c) => c.id == channel.id);
              if (mainIndex != -1) {
                _selectChannel(mainIndex);
              }
            }
          },
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3B4248) : const Color(0xFF1B1E22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Kanal-Logo/Icon
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[800],
                        child: channel.logo != null && channel.logo!.isNotEmpty
                          ? Image.network(
                              channel.logo!.startsWith('http') 
                                ? channel.logo! 
                                : 'http://app.seeyoo.tv${channel.logo!}',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.tv,
                                color: Colors.white54,
                                size: 30,
                              ),
                            )
                          : const Icon(
                              Icons.tv,
                              color: Colors.white54,
                              size: 30,
                            ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Kanalinformationen
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            channel.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (channel.currentShow != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  if (channel.isLive)
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
                                      channel.currentShow!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Favoriten-Stern, wenn der Kanal als Favorit markiert ist
              if (channel.favorite)
                Positioned(
                  right: 16,
                  top: 28, // Vertikal mittig positioniert
                  child: const Icon(
                    Icons.star,
                    color: Color(0xFFE53A56),
                    size: 24,
                  ),
                ),
            ],
          ),
        );
      },
    );
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
                if (_currentStreamUrl != null)
                  Center(
                    child: Text(
                      'Stream URL: $_currentStreamUrl',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (_isLoading)
                  const Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA1273B)),
                  ))
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.tv_off, color: Colors.white54, size: 50),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage ?? 'Kein Kanal ausgewählt',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                // Später wird hier der Video-Player hinzugefügt.
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
                      // Wenn Programm-Tab gewählt
                      if (index == 0) {
                        _loadEpgData();
                        _showEpgView = true;
                        _showGenresView = false;
                        _showMediaLibraryMessage = false;
                      }
                      // Wenn Mediathek-Tab gewählt
                      else if (index == 1) {
                        _showEpgView = false;
                        _showGenresView = false;
                        _showMediaLibraryMessage = true;
                      }
                      // Wenn Kategorien-Tab gewählt
                      else if (index == 2) {
                        _showEpgView = false;
                        _showGenresView = true;
                        _showMediaLibraryMessage = false;
                      }
                      // Wenn ein anderer Tab gewählt wird, alle Ansichten ausblenden
                      else {
                        _showEpgView = false;
                        _showGenresView = false;
                        _showMediaLibraryMessage = false;
                      }
                      
                      // Wenn Favoriten-Tab gewählt und vorher ein anderer Tab aktiv war
                      if (index == 3 && _selectedTabIndex != 3) {
                        _toggleFavorite();
                      }
                      // Wenn Favoriten-Tab bereits aktiv war, deaktiviere Favorit
                      else if (index == 3 && _selectedTabIndex == 3) {
                        _toggleFavorite();
                      }
                      // Wenn der Tab bereits ausgewählt ist, deaktiviere ihn
                      _selectedTabIndex = _selectedTabIndex == index ? -1 : index;
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
          
          // Kanalauswahl oder EPG-Daten (Scrollbare Seitenleiste)
          Expanded(
            child: Container(
              color: Colors.black,
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA1273B)),
                  ))
                : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)))
                  : _showMediaLibraryMessage && _selectedTabIndex == 1 // Mediathek-Meldung
                    ? _buildMediaLibraryMessage()
                    : _showEpgView && _selectedTabIndex == 0 // EPG-Ansicht für Programm-Tab
                      ? _buildEpgView()
                      : _showGenresView && _selectedTabIndex == 2 // Kategorien-Ansicht
                        ? _buildGenresView()
                        : _selectedTabIndex == 3 // Favoriten-Tab
                          ? _buildChannelList(_favoriteChannels)
                          : _buildChannelList(_filteredChannels) // Zeige alle Kanäle, wenn kein oder ein anderer Tab ausgewählt ist
            ),
          ),
        ],
      ),
    );
  }
}
