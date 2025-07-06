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
  Map<int, List<EpgProgram>> _epgDataMap = {}; // Speichert EPG-Daten für alle Kanäle
  Map<int, bool> _epgLoadingStatus = {}; // Speichert den Ladestatus für jeden Kanal
  Map<int, bool> _epgRequestAttempted = {}; // Speichert, ob EPG-Daten für einen Kanal bereits angefragt wurden
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
  
  // Lädt EPG-Daten für alle Kanäle auf einmal
  Future<void> _loadAllChannelsEpgData() async {
    // Zeige einen Ladeindikator an
    setState(() {
      _isLoadingEpg = true;
    });
    
    try {
      // Erstellung einer Liste von Futures für alle API-Anfragen
      final List<Future> futures = [];
      
      // Für jeden Kanal EPG-Daten laden
      for (final channel in _channels) {
        // Status auf "wird geladen" setzen
        _epgLoadingStatus[channel.id] = true;
        
        // Ein Future erstellen, das EPG-Daten für diesen Kanal lädt
        final future = _apiService.getEpgForChannel(channel.id, next: 10).then((epgData) {
          // EPG-Daten im Map speichern
          setState(() {
            _epgDataMap[channel.id] = epgData;
            _epgLoadingStatus[channel.id] = false;
          });
        }).catchError((e) {
          setState(() {
            _epgLoadingStatus[channel.id] = false;
          });
          print('Fehler beim Laden der EPG-Daten für Kanal ${channel.id}: $e');
        });
        
        futures.add(future);
      }
      
      // Auf alle API-Anfragen warten
      await Future.wait(futures);
      
      setState(() {
        _isLoadingEpg = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEpg = false;
      });
      print('Fehler beim Laden der EPG-Daten: $e');
    }
  }
  
  // Lädt EPG-Daten für einen bestimmten Kanal
  Future<void> _loadChannelEpgData(TvChannel channel) async {
    // Überprüfen, ob bereits EPG-Daten geladen werden oder vorhanden sind
    if (_epgLoadingStatus[channel.id] == true) {
      return; // Bereits am Laden
    }
    
    setState(() {
      _epgLoadingStatus[channel.id] = true;
      _epgRequestAttempted[channel.id] = true; // Markieren, dass für diesen Kanal EPG-Daten angefragt wurden
    });
    
    try {
      // Für Kanalliste 10 Sendungen laden (aktuelle und nächste Sendungen)
      final epgData = await _apiService.getEpgForChannel(channel.id, next: 10);
      setState(() {
        _epgDataMap[channel.id] = epgData;
        _epgLoadingStatus[channel.id] = false;
      });
    } catch (e) {
      setState(() {
        _epgLoadingStatus[channel.id] = false;
      });
      print('Fehler beim Laden der EPG-Daten für Kanal ${channel.id}: $e');
    }
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
        
        // Lade EPG-Daten für alle Kanäle auf einmal
        await _loadAllChannelsEpgData();
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
  
  // Lädt EPG-Daten für den ausgewählten Kanal
  Future<void> _loadEpgForChannel(int channelId, {int epgCount = 20}) async {
    if (_isLoadingEpg) {
      return; // Bereits am Laden
    }
    
    setState(() {
      _isLoadingEpg = true;
      _currentEpgData = []; // Zurücksetzen der alten Daten
      _errorMessage = null;
    });
    
    try {
      // Überprüfen, ob bereits EPG-Daten geladen sind
      if (_epgDataMap.containsKey(channelId) && _epgDataMap[channelId] != null) {
        final epgData = _epgDataMap[channelId] ?? [];
        // Wenn für die Programmansicht mehr Sendungen benötigt werden und die vorhandenen nicht ausreichen
        if (epgCount > 10 && epgData.length <= 10) {
          // Neue Anfrage mit der höheren Anzahl starten
        } else {
          setState(() {
            _currentEpgData = epgData;
            _isLoadingEpg = false;
          });
          return;
        }
      }
      
      // Sendungen abrufen mit der angegebenen Anzahl
      final epgData = await _apiService.getEpgForChannel(channelId, next: epgCount);
      
      // Nur aktuelle und zukünftige Sendungen behalten, keine Archiv-Sendungen
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final filteredEpgData = epgData
          .where((program) => 
              // Sendungen, die noch nicht beendet sind
              program.end > now && 
              // UND nicht im Archiv sind
              !program.inArchive)
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
      
      // EPG-Daten auch für die Kanalliste speichern
      _epgDataMap[channelId] = filteredEpgData;
      _epgLoadingStatus[channelId] = false;
      
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
  
  // Lädt EPG-Daten für den aktuell ausgewählten Kanal
  Future<void> _loadEpgForSelectedChannel() async {
    if (_selectedChannelIndex < 0 || _selectedChannelIndex >= _channels.length) {
      return;
    }
    
    final channelId = _channels[_selectedChannelIndex].id;
    // Für die Programmansicht immer 20 Sendungen laden
    await _loadEpgForChannel(channelId, epgCount: 20);
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
              const Icon(Icons.category_outlined, color: Color(0xFF8D9296), size: 48),
              const SizedBox(height: 16),
              Text(
                'Keine Kategorien verfügbar',
                style: TextStyle(color: const Color(0xFF8D9296), fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      color: Colors.black,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 30),
        itemCount: _genres.length,
        itemBuilder: (context, index) {
          final genre = _genres[index];
          final isSelected = genre.id == _selectedGenreId || 
                            (genre.id == 'all' && _selectedGenreId == null);
          
          return GestureDetector(
            onTap: () {
              // Bei Auswahl einer Kategorie die Kanalliste filtern
              _filterChannelsByGenre(genre.id == 'all' ? null : genre.id);
              
              // Tab auf "Kanalliste" wechseln, aber Genre-Filterung beibehalten
              setState(() {
                _selectedTabIndex = -1; // Zurück zur normalen Kanalliste
                _showGenresView = false;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B4248) : const Color(0xFF1B1E22),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[850]!,
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: isSelected
                      ? Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFE53A56),
                                width: 2.0,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.only(bottom: 1), // 1px Abstand zwischen Text und Linie
                          child: Text(
                            genre.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : Text(
                          genre.title,
                          style: const TextStyle(
                            color: Color(0xFF8D9296),
                            fontWeight: FontWeight.normal,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Baut die Ansicht für die Mediathek-Meldung
  Widget _buildMediaLibraryMessage() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, -30), // 30px nach oben verschieben
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            const Icon(Icons.video_library, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'Mediathek-Funktion',
              style: TextStyle(
                color: const Color(0xFF8D9296),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Diese Funktion befindet sich\nnoch in der Entwicklung\nund wird mit dem nächsten\nRelease verfügbar sein.',
              style: TextStyle(color: const Color(0xFF8D9296), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            ],
          ),
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
        child: Transform.translate(
          offset: const Offset(0, -30), // 30px nach oben verschieben
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_busy, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              Text(
                'Programminfo zur Zeit\nnicht verfügbar',
                style: TextStyle(color: const Color(0xFF8D9296), fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Die elektronischen Programminformationen (EPG) werden in Kürze aktiviert.',
                textAlign: TextAlign.center,
                style: TextStyle(color: const Color(0xFF8D9296), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    
    // Filtere die Archiv-Sendungen aus
    final filteredEpgData = _currentEpgData.where((program) => !program.inArchive).toList();
    
    // Zeigt die EPG-Daten in einer Liste an
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        // EPG-Liste
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: filteredEpgData.length,
            itemBuilder: (context, index) {
              final program = filteredEpgData[index];
              final isNowPlaying = program.isCurrentlyRunning;
              
              return Container(
                decoration: BoxDecoration(
                  color: isNowPlaying ? const Color(0xFF3B4248) : const Color(0xFF1B1E22),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[850]!,
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
                      width: 82,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              program.startTimeFormatted,
                              style: TextStyle(
                                color: isNowPlaying ? Colors.white : const Color(0xFF8D9296),
                                fontSize: 16,
                                fontWeight: isNowPlaying ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              '${program.durationMinutes} min',
                              style: TextStyle(
                                color: isNowPlaying ? Colors.white : const Color(0xFF8D9296),
                                fontSize: 12,
                              ),
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
                              margin: const EdgeInsets.only(bottom: 4, top: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE53A56),
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                              ),
                              child: const Text(
                                'Läuft gerade',
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
                              color: isNowPlaying ? Colors.white : const Color(0xFF8D9296),
                              fontSize: 16,
                              fontWeight: isNowPlaying ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                          
                          // EPG-Informationen anzeigen
                          Builder(builder: (context) {
                            // Aktuelle EPG-Daten laden, falls vorhanden
                            final epgData = _epgDataMap[channel.id] ?? [];
                            
                            // Wenn keine EPG-Daten vorhanden sind UND noch nicht versucht wurde, sie zu laden
                            if (epgData.isEmpty && _epgLoadingStatus[channel.id] != true && _epgRequestAttempted[channel.id] != true) {
                              // Verwende Future.microtask, um setState() nicht während des Builds aufzurufen
                              Future.microtask(() => _loadChannelEpgData(channel));
                              return Text(
                                'Programminformationen werden geladen...',
                                style: TextStyle(
                                  color: const Color(0xFF8D9296),
                                  fontSize: 12,
                                ),
                              );
                            }
                            
                            // EPG-Daten werden geladen
                            if (_epgLoadingStatus[channel.id] == true && epgData.isEmpty) {
                              return const SizedBox(
                                height: 12,
                                width: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA1273B)),
                                ),
                              );
                            }
                            
                            // Wenn keine EPG-Daten vorhanden sind, aber bereits versucht wurde, sie zu laden
                            if (epgData.isEmpty && _epgRequestAttempted[channel.id] == true) {
                              return Text(
                                'Keine Programminformationen verfügbar',
                                style: TextStyle(
                                  color: const Color(0xFF8D9296),
                                  fontSize: 12,
                                ),
                              );
                            }  
                            
                            // Wenn EPG-Daten vorhanden sind
                            if (epgData.isNotEmpty) {
                              // Finde das aktuell laufende Programm
                              final currentProgram = epgData.firstWhere(
                                (program) => program.isCurrentlyRunning,
                                orElse: () => epgData.first,
                              );
                              
                              // Finde die nächste Sendung (falls verfügbar)
                              EpgProgram? nextProgram;
                              if (epgData.length > 1) {
                                final currentIndex = epgData.indexOf(currentProgram);
                                if (currentIndex < epgData.length - 1) {
                                  nextProgram = epgData[currentIndex + 1];
                                }
                              }
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Aktuelle Sendung mit JETZT-Label
                                  Row(
                                    children: [
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
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          currentProgram.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Nächste Sendung mit Startzeit
                                  if (nextProgram != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        children: [
                                          Text(
                                            nextProgram.startTimeFormatted,
                                            style: TextStyle(
                                              color: const Color(0xFFE53A56),
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              nextProgram.name,
                                              style: TextStyle(
                                                color: const Color(0xFF8D9296),
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            }
                            
                            return Text(
                              'Keine Programminformationen verfügbar',
                              style: TextStyle(
                                color: const Color(0xFF8D9296),
                                fontSize: 12,
                              ),
                            );
                          }),
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
                        _loadEpgForSelectedChannel();
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
                              color: _selectedTabIndex == index ? Colors.white : const Color(0xFF8D9296), // Ausgewähltes Symbol weiß, andere hellgrau
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tabTitles[index],
                          style: TextStyle(
                            color: _selectedTabIndex == index ? Colors.white : const Color(0xFF8D9296),
                            fontWeight: _selectedTabIndex == index ? FontWeight.bold : FontWeight.normal,
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
