import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async'; // Für Timer hinzugefügt
import 'package:seeyoo_app/models/epg_program.dart';
import 'package:seeyoo_app/models/tv_channel.dart';
import 'package:seeyoo_app/models/tv_genre.dart';
import 'package:seeyoo_app/services/api_service.dart';
import 'package:seeyoo_app/services/storage_service.dart';

class TvFavoriteScreen extends StatefulWidget {
  const TvFavoriteScreen({super.key});

  @override
  State<TvFavoriteScreen> createState() => _TvFavoriteScreenState();
}

class _TvFavoriteScreenState extends State<TvFavoriteScreen> {
  int _selectedTabIndex = -1; // -1 bedeutet kein Tab ist ausgewählt
  int _selectedChannelIndex = 0; // Index des ausgewählten Kanals
  final List<String> _tabTitles = ['Programm', 'Mediathek', 'Kategorien', 'Bearbeiten'];
  final List<IconData> _tabIcons = [
    Icons.list_alt, // Programm
    Icons.video_library, // Mediathek
    Icons.grid_view, // Kategorien
    Icons.sync // Bearbeiten-Icon mit zwei halbkreisförmigen Pfeilen
  ];
  
  // ScrollController für die Kategorien-Liste
  final ScrollController _genresScrollController = ScrollController();
  // ScrollController für die Kanalliste
  final ScrollController _channelListController = ScrollController();
  // Speichert die letzte Scroll-Position der Kanalliste
  double _lastChannelListScrollPosition = 0.0;
  
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
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
  bool _isInReorderMode = false; // Status für den Bearbeiten-Modus
  
  // Timer für regelmäßige Server-Pings
  Timer? _pingTimer;
  
  // ID des aktuell ausgewählten Kanals (für Media-Info)
  int? _currentChannelId;
  
  // Gibt das Kategorien-Icon mit einem roten Indikator zurück, wenn eine spezifische Kategorie ausgewählt ist
  Widget _getCategoryIconWithIndicator() {
    final bool isCategorySelected = _selectedGenreId != null && _selectedGenreId != 'all';
    final iconColor = _selectedTabIndex == 2 ? Colors.white : const Color(0xFF8D9296);
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          _tabIcons[2],  // Kategorien-Icon
          color: _isInReorderMode ? const Color(0xFF8D9296).withOpacity(0.5) : iconColor,
          size: 26,
        ),
        if (isCategorySelected) // Zeige roten Punkt nur an, wenn eine Kategorie ausgewählt ist
          Positioned(
            top: -5, // 1px nach oben verschoben
            right: -15, // 1px nach rechts verschoben
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFE53A56),  // Rote Farbe für den Indikator
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  // Gibt das Bearbeiten-Icon zurück mit optionalem roten Punkt
  Widget _getReorderIcon() {
    return Stack(
      clipBehavior: Clip.none, // Verhindert Abschneiden von Kindelementen außerhalb des Stacks
      children: [
        Icon(
          Icons.sync,
          color: _selectedTabIndex == 3 ? Colors.white : const Color(0xFF8D9296),
          size: 26,
        ),
        if (_isInReorderMode)
          Positioned(
            top: -5,
            right: -15,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFE53A56), // Rot für den Punkt
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
  
  // Schaltet den Bearbeiten-Modus ein oder aus
  void _toggleReorderMode() {
    setState(() {
      // Vorherigen Zustand speichern
      final bool wasInReorderMode = _isInReorderMode;
      
      _isInReorderMode = !_isInReorderMode;
      // Wenn wir in den Bearbeiten-Modus wechseln, deaktivieren wir alle anderen Ansichten
      if (_isInReorderMode) {
        _showEpgView = false;
        _showGenresView = false;
        _showMediaLibraryMessage = false;
      } else if (wasInReorderMode) {
        // Wenn wir aus dem Bearbeiten-Modus zurückkehren, zum ausgewählten Kanal scrollen
        // mit einem verzögerten Aufruf, damit der Bildschirm zuerst gerendert wird
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSelectedChannel();
        });
      }
    });
  }

  // Diese Methode wird unten vollständig implementiert

  @override
  void initState() {
    super.initState();
    // Favoriten mit sortierter Reihenfolge laden
    _loadFavoriteChannels();
    _loadGenres();
    _loadSavedCategory(); // Lade die gespeicherte Kategorie
    
    // Sende sofort einen initialen Ping beim Start
    _pingServer();
    
    // Starte den Ping-Timer (alle 120 Sekunden)
    _pingTimer = Timer.periodic(const Duration(seconds: 120), (timer) {
      _pingServer();
    });
  }
  
  // Wird aufgerufen, wenn der Screen in den Vordergrund kommt
  bool _firstLoad = true;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Überspringe beim ersten Laden, da initState() bereits _loadFavoriteChannels() aufruft
    if (!_firstLoad) {
      // Favoriten jedes Mal neu laden, wenn der Screen angezeigt wird
      _loadFavoriteChannels();
    }
    _firstLoad = false;
  }
  
  @override
  void dispose() {
    // ScrollController freigeben, wenn das Widget entsorgt wird
    _genresScrollController.dispose();
    _channelListController.dispose();
    
    // Timer beenden und Media-Info entfernen
    _pingTimer?.cancel();
    if (_currentChannelId != null) {
      _apiService.removeMediaInfo();
    }
    
    super.dispose();
  }
  
  // Sendet einen Ping an den Server
  Future<void> _pingServer() async {
    try {
      await _apiService.pingServer();
    } catch (e) {
      print('Fehler beim Senden des Pings: $e');
    }
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
    if (!mounted) return;
    
    setState(() {
      _isLoadingGenres = true;
    });
    
    try {
      final genres = await _apiService.getTvGenres();
      if (mounted) {
        setState(() {
          _genres = genres;
          _isLoadingGenres = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGenres = false;
          // Optional: Fehlermeldung setzen
        });
      }
    }
  }
  
  // Lädt die gespeicherte Kategorie-Auswahl
  Future<void> _loadSavedCategory() async {
    final savedGenreId = await _storageService.getSelectedFavoriteTvGenre();
    
    // Nur fortfahren, wenn ein Genre gespeichert war und das Widget noch gemountet ist
    if (savedGenreId != null && mounted) {
      // Überprüfe, ob die Favoriten bereits geladen sind
      if (_favoriteChannels.isNotEmpty) {
        // Filtere die Kanäle nach der gespeicherten Genre-ID
        _filterChannelsByGenre(savedGenreId);
      } else {
        // Setze nur die Genre-ID, die tatsächliche Filterung erfolgt später in _loadFavoriteChannels
        _selectedGenreId = savedGenreId;
      }
    }
  }

  // Filtert Kanäle nach ausgewähltem Genre
  void _filterChannelsByGenre(String? genreId) {
    setState(() {
      _selectedGenreId = genreId;
      if (genreId == null) {
        // Zeige alle Favoriten
        _filteredChannels = List.from(_favoriteChannels);
      } else {
        // Filtere nur Favoriten nach Genre
        _filteredChannels = _favoriteChannels.where((channel) => 
          channel.genreId == genreId).toList();
      }
      
      // Speichere die ausgewählte Kategorie lokal
      _storageService.saveSelectedFavoriteTvGenre(genreId);
    });
  }
  
  // Aktualisiert die Favoritenliste vom Server
  Future<void> _refreshFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Lade Favoriten neu vom API
      await _loadFavoriteChannels();
      
      // Anzeige der aktualisierten Favoriten
      setState(() {
        _selectedTabIndex = 0; // Wechsle zurück zur Kanal-Ansicht
        _filteredChannels = List.from(_favoriteChannels);
      });
      
      // Zeige eine kurze Bestätigungsnachricht an
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Favoriten erfolgreich aktualisiert'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler beim Aktualisieren der Favoriten: ' + e.toString();
      });
    }
  }

  // Lädt sowohl alle Kanäle als auch Favoriten
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
        // Nur Favoriten in der gefilterten Liste anzeigen
        _filteredChannels = List.from(favoriteChannels); 
        _isLoading = false;
      });
      
      // Wähle den ersten Kanal aus, wenn vorhanden
      if (_favoriteChannels.isNotEmpty) {
        // Finde den Index des ersten Favoriten-Kanals in der Gesamtliste
        final mainIndex = _channels.indexWhere((c) => c.id == _favoriteChannels[0].id);
        if (mainIndex != -1) {
          _selectChannel(mainIndex);
        }
        
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

  // Aktualisiert die Reihenfolge der Favoriten auf dem Server und lokal
  Future<void> _updateFavoriteOrder() async {
    try {
      // Extrahiere IDs aller Favoriten-Kanäle in der aktuellen Reihenfolge
      final List<int> channelIds = _favoriteChannels.map((channel) => channel.id).toList();
      
      // Sende die aktualisierte Reihenfolge an den Server
      final success = await _apiService.updateFavoritesOrder(channelIds);
      
      // Speichere die Reihenfolge auch lokal (unabhängig vom Servererfolg)
      await _storageService.saveFavoritesOrder(channelIds);
      
      if (success) {
        print('Favoriten-Reihenfolge erfolgreich gespeichert');
      } else {
        print('Fehler beim Speichern der Favoriten-Reihenfolge auf dem Server');
        // Trotzdem behalten wir die lokale Reihenfolge bei
      }
    } catch (e) {
      print('Fehler beim Aktualisieren der Favoriten-Reihenfolge: $e');
    }
  }

  // Wähle einen Kanal aus und lade den Stream
  void _selectChannel(int index) async {
    if (index >= 0 && index < _channels.length) {
      // Wenn bereits ein Kanal ausgewählt war, entferne die Media-Info
      if (_currentChannelId != null) {
        await _apiService.removeMediaInfo();
      }
      
      setState(() {
        _selectedChannelIndex = index;
        _currentStreamUrl = null; // Zurücksetzen, während wir laden
        _currentEpgData = []; // EPG-Daten zurücksetzen
        _showEpgView = false; // EPG-Ansicht ausblenden
      });
      
      // Lade den Stream-Link für diesen Kanal
      final channel = _channels[index];
      
      // Aktualisiere _currentChannelId
      _currentChannelId = channel.id;
      
      // Scroll-Verhalten nur für größere Listen aktivieren
      if (_filteredChannels.length > 7) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToSelectedChannel();
        });
      }
      
      // Wenn die URL bereits im Kanal-Objekt vorhanden ist, verwende diese
      // Ansonsten hole sie über die API
      if (channel.url != null && channel.url!.isNotEmpty) {
        setState(() {
          _currentStreamUrl = channel.url!;
        });
        
        // Aktualisiere Media-Info für den ausgewählten Kanal
        await _apiService.updateMediaInfo(type: 'tv-channel', mediaId: channel.id);
        // Speichere diesen Kanal als zuletzt gesehenen (global auf dem Server)
        await _apiService.saveLastWatchedChannel(channel.id);
        // Speichere diesen Kanal auch lokal als zuletzt gesehenen Favoriten-Kanal
        await _storageService.saveLastFavoriteChannel(channel.id);
        print('Media-Info aktualisiert für Kanal ${channel.id}');
      } else {
        try {
          final streamUrl = await _apiService.getTvChannelLink(channel.id);
          if (streamUrl != null) {
            setState(() {
              _currentStreamUrl = streamUrl;
            });
            
            // Aktualisiere Media-Info für den ausgewählten Kanal
            await _apiService.updateMediaInfo(type: 'tv-channel', mediaId: channel.id);
            // Speichere diesen Kanal als zuletzt gesehenen (global auf dem Server)
            await _apiService.saveLastWatchedChannel(channel.id);
            // Speichere diesen Kanal auch lokal als zuletzt gesehenen Favoriten-Kanal
            await _storageService.saveLastFavoriteChannel(channel.id);
            print('Media-Info aktualisiert für Kanal ${channel.id}');
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Favoriten vom Server laden
      final favoriteChannels = await _apiService.getFavoriteTvChannels();
      final allChannels = await _apiService.getTvChannels(); // Alle Kanäle für vollständige Informationen
      
      // Lokal gespeicherte Reihenfolge abrufen
      final savedOrder = await _storageService.getFavoritesOrder();
      
      // Wenn wir eine gespeicherte Reihenfolge haben, sortieren wir die Favoriten entsprechend
      if (savedOrder != null && savedOrder.isNotEmpty) {
        // Erstelle eine Map für schnellen Zugriff auf Kanäle nach ID
        final Map<int, TvChannel> channelsMap = {};
        for (final channel in favoriteChannels) {
          channelsMap[channel.id] = channel;
        }
        
        // Neue sortierte Liste erstellen
        List<TvChannel> sortedFavorites = [];
        
        // Für jede ID in der gespeicherten Reihenfolge den entsprechenden Kanal hinzufügen
        for (final id in savedOrder) {
          if (channelsMap.containsKey(id)) {
            sortedFavorites.add(channelsMap[id]!);
            // Entfernen, um zu verfolgen, welche Kanäle bereits hinzugefügt wurden
            channelsMap.remove(id);
          }
        }
        
        // Füge alle übrigen Kanäle hinzu (falls neue Favoriten hinzugekommen sind)
        sortedFavorites.addAll(channelsMap.values);
        
        // Ersetze die ursprüngliche Liste durch die sortierte
        setState(() {
          _favoriteChannels = sortedFavorites;
          _channels = allChannels;
          _filteredChannels = sortedFavorites;
          _isLoading = false;
        });
      } else {
        // Keine gespeicherte Reihenfolge vorhanden, verwende die vom Server gelieferte
        setState(() {
          _favoriteChannels = favoriteChannels;
          _channels = allChannels;
          _filteredChannels = favoriteChannels;
          _isLoading = false;
        });
      }
      
      // Versuche den zuletzt gesehenen Kanal zu laden, ansonsten den ersten Favoriten
      if (_favoriteChannels.isNotEmpty) {
        await _loadLastWatchedChannel();
        
        // Lade EPG-Daten für alle Favoriten-Kanäle
        await _loadAllChannelsEpgData();
      }
    } catch (e) {
      // Fehlerbehandlung
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler beim Laden der Favoriten: $e';
      });
    }
  }
  
  // Lädt den zuletzt gesehenen Kanal
  Future<void> _loadLastWatchedChannel() async {
    try {
      // Zuerst versuchen, den lokal gespeicherten Favoriten-Kanal zu laden
      final lastFavoriteChannelId = await _storageService.getLastFavoriteChannel();
      
      // Prüfen ob der lokal gespeicherte Favoriten-Kanal vorhanden ist
      if (lastFavoriteChannelId != null && _channels.isNotEmpty) {
        // Prüfe, ob der Kanal in den Favoriten ist
        final favoriteIndex = _favoriteChannels.indexWhere((channel) => channel.id == lastFavoriteChannelId);
        
        if (favoriteIndex >= 0) {
          // Lokal gespeicherter Kanal ist ein Favorit, finde seinen Index in der Hauptliste
          final mainIndex = _channels.indexWhere((channel) => channel.id == lastFavoriteChannelId);
          
          if (mainIndex >= 0) {
            // Lokal gespeicherter Kanal gefunden, wähle ihn aus
            print('Wähle lokal gespeicherten Favoriten-Kanal mit ID $lastFavoriteChannelId aus');
            _selectChannel(mainIndex);
            return;
          }
        }
      }
      
      // Fallback: Wenn kein lokaler Favoriten-Kanal gefunden wurde, versuche den vom Server
      final lastChannelId = await _apiService.getLastWatchedChannel();
      
      if (lastChannelId != null && _channels.isNotEmpty) {
        // Prüfe zuerst, ob der zuletzt gesehene Kanal in den Favoriten ist
        final favoriteIndex = _favoriteChannels.indexWhere((channel) => channel.id == lastChannelId);
        
        if (favoriteIndex >= 0) {
          // Zuletzt gesehener Kanal ist ein Favorit, finde seinen Index in der Hauptliste
          final mainIndex = _channels.indexWhere((channel) => channel.id == lastChannelId);
          
          if (mainIndex >= 0) {
            // Zuletzt gesehener Kanal gefunden, wähle ihn aus
            print('Wähle zuletzt gesehenen Kanal mit ID $lastChannelId aus');
            _selectChannel(mainIndex);
            return;
          }
        } else {
          print('Zuletzt gesehener Kanal mit ID $lastChannelId ist kein Favorit');
        }
      }
      
      // Fallback: Wenn kein zuletzt gesehener Kanal gefunden wurde oder er kein Favorit ist,
      // wähle den ersten Favoriten
      if (_favoriteChannels.isNotEmpty) {
        // Finde den Index des ersten Favoriten-Kanals in der Hauptliste
        final mainIndex = _channels.indexWhere((c) => c.id == _favoriteChannels[0].id);
        if (mainIndex != -1) {
          print('Wähle ersten Favoriten als Fallback');
          _selectChannel(mainIndex);
        }
      }
    } catch (e) {
      print('Fehler beim Laden des zuletzt gesehenen Kanals: $e');
      // Fallback im Fehlerfall: Ersten Favoriten wählen
      if (_favoriteChannels.isNotEmpty) {
        // Finde den Index des ersten Favoriten-Kanals in der Hauptliste
        final mainIndex = _channels.indexWhere((c) => c.id == _favoriteChannels[0].id);
        if (mainIndex != -1) {
          _selectChannel(mainIndex);
        }
      }
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
    
    // Verzögertes Scrollen zur ausgewählten Kategorie, wenn die Liste gebaut wird
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedGenreId != null) {
        // Finde den Index der ausgewählten Kategorie
        final selectedIndex = _genres.indexWhere((genre) => 
            genre.id == _selectedGenreId || 
            (genre.id == 'all' && _selectedGenreId == null));
        
        if (selectedIndex != -1) {
          // Berechne die Gesamthöhe der Liste und des sichtbaren Bereichs
          final itemHeight = 70.0; // Geschätzte Höhe jedes Eintrags (anpassen nach Bedarf)
          final totalHeight = _genres.length * itemHeight;
          final viewportHeight = _genresScrollController.position.viewportDimension;
          
          // Berechne die maximale Scroll-Position
          final maxScroll = _genresScrollController.position.maxScrollExtent;
          
          // Berechne die Zielposition für das ausgewählte Element
          // Stellt sicher, dass bei Elementen am Ende nicht über das Ende hinaus gescrollt wird
          final targetPosition = (selectedIndex * itemHeight)
              .clamp(0.0, maxScroll);
              
          // Scrolle zur berechneten Position
          _genresScrollController.animateTo(
            targetPosition,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
    
    return Container(
      color: Colors.black,
      child: ListView.builder(
        controller: _genresScrollController,
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
                
                // Automatisch den ersten Sender aus der gefilterten Liste auswählen
                if (_filteredChannels.isNotEmpty) {
                  // Den ersten Sender der gefilterten Liste in der Gesamtliste finden
                  int originalIndex = _channels.indexWhere((channel) => 
                    channel.id == _filteredChannels[0].id);
                  
                  if (originalIndex >= 0) {
                    _selectedChannelIndex = originalIndex;
                    _selectChannel(originalIndex);
                  }
                }
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
    
    // Im Bearbeiten-Modus verwenden wir ReorderableListView mit der bestehenden Ansicht
    if (_isInReorderMode) {
      return ReorderableListView.builder(
        buildDefaultDragHandles: false, // Wir erstellen eigene Drag-Handles
        // Anpassen des Aussehens während des Ziehens
        proxyDecorator: (Widget child, int index, Animation<double> animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              // Während des Ziehens dunkelgrauen Hintergrund statt weißen Rahmen verwenden
              return Material(
                elevation: 0.0, // Keine Schatten
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B4248), // Dunkelgrauer Hintergrund wie bei Auswahl
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: child,
                ),
              );
            },
            child: child,
          );
        },
        onReorder: (oldIndex, newIndex) {
          // Anpassung für den Fall, dass nach unten verschoben wird
          if (newIndex > oldIndex) newIndex--;
          
          setState(() {
            // Kanal aus der alten Position entfernen und an der neuen einfügen
            final channel = _favoriteChannels.removeAt(oldIndex);
            _favoriteChannels.insert(newIndex, channel);
            
            // Gefilterte Kanäle aktualisieren
            _filteredChannels = List.from(_favoriteChannels);
            
            // API-Aufruf, um die neue Reihenfolge zu speichern
            _updateFavoriteOrder(); 
          });
        },
        itemCount: channels.length,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemBuilder: (context, index) {
          final channel = channels[index];
          // Im Bearbeiten-Modus keine Sender als ausgewählt markieren
          final isSelected = _isInReorderMode ? false : (_selectedTabIndex != 3 ?
              channels[index].id == _channels[_selectedChannelIndex].id :
              index == _selectedChannelIndex);
          
          // Im Bearbeiten-Modus verwenden wir die bestehenden Items mit Drag-Handle
          return Container(
            key: ValueKey(channel.id),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B4248) : const Color(0xFF1B1E22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Drag-Handle (dreifach-Strich), nur dieser Bereich kann zum Ziehen verwendet werden
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(
                    Icons.drag_handle,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                  
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
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.live_tv, size: 30, color: Colors.white54));
                          },
                        )
                      : const Icon(Icons.live_tv, size: 30, color: Colors.white54),
                  ),
                ),
                  
                // Kanal-Informationen
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kanalname
                        Text(
                          channel.name,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Aktuelle Sendung
                        if (channel.currentShow != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              // JETZT-Label
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
                              const SizedBox(height: 4),
                              Text(
                                channel.currentShow!,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (channel.currentShowTime != null)
                                Text(
                                  channel.currentShowTime!,
                                  style: const TextStyle(color: Color(0xFF8D9296)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                // Löschsymbol für Favoriten im Bearbeitungsmodus
                GestureDetector(
                  onTap: () {
                    // Kanal aus Favoriten entfernen
                    setState(() {
                      // Kanal aus den Favoriten entfernen
                      _favoriteChannels.removeAt(index);
                      
                      // Gefilterte Liste aktualisieren
                      _filteredChannels = List.from(_favoriteChannels);
                      
                      // Favoriten in der API aktualisieren
                      _updateFavoriteOrder();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFFE53A56),
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
    
    // Normale Liste für den Standard-Modus
    return ListView.builder(
      controller: _channelListController,
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
                          : const Icon(Icons.tv, size: 30, color: Colors.white54),
                      ),
                    ),
                    
                    // Kanal-Informationen
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kanalname
                            Text(
                              channel.name,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                            // EPG-Daten wenn vorhanden
                            Builder(builder: (context) {
                              // EPG-Daten für diesen Kanal holen
                              final epgData = _epgDataMap[channel.id] ?? [];
                              
                              // Wenn keine EPG-Daten und kein Loading-Status, lade Daten
                              if (epgData.isEmpty && _epgLoadingStatus[channel.id] != true && _epgRequestAttempted[channel.id] != true) {
                                // Asynchron Daten laden
                                Future.microtask(() => _loadChannelEpgData(channel));
                                return Text(
                                  'Lade Programmdaten...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                );
                              }
                              
                              // Wenn gerade geladen wird
                              if (_epgLoadingStatus[channel.id] == true && epgData.isEmpty) {
                                return const Text(
                                  'Lade Programmdaten...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                );
                              }
                              
                              // Wenn keine Daten nach Ladeversuch
                              if (epgData.isEmpty && _epgRequestAttempted[channel.id] == true) {
                                return Text(
                                  'Keine EPG-Daten verfügbar',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                );
                              }
                              
                              // Wenn EPG-Daten vorhanden
                              if (epgData.isNotEmpty) {
                                // Finde aktuelle und nächste Sendung
                                final currentProgram = epgData[0]; // Aktuelle Sendung ist die erste
                                EpgProgram? nextProgram;
                                
                                // Wenn mehr als eine Sendung vorhanden ist
                                if (epgData.length > 1) {
                                  final currentIndex = 0; // Aktuelle Sendung ist immer Index 0
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
                                    // Nächste Sendung wurde entfernt, um die Einträge kompakter zu machen
                                  ],
                                );
                              }
                              
                              // Fallback wenn irgendwas schiefging
                              return Text(
                                'Keine Daten',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Scrollt zum ausgewählten Kanal in der Liste
  void _scrollToSelectedChannel() {
    // Prüfe, ob der Controller an eine ScrollView angebunden ist
    if (!_channelListController.hasClients) return;
    
    // In dieser Ansicht arbeiten wir immer mit Favoriten, daher entsprechend anpassen
    int channelIndexToShow;
    
    // Suche den ausgewählten Kanal in der gefilterten Liste
    // In der Favoriten-Ansicht ist das etwas anders als in der normalen TV-Ansicht
    channelIndexToShow = _filteredChannels.indexWhere((channel) => 
        _channels.isNotEmpty && _selectedChannelIndex < _channels.length &&
        channel.id == _channels[_selectedChannelIndex].id);
    
    // Wenn der Kanal nicht in der aktuellen Liste gefunden wurde
    if (channelIndexToShow < 0) return;
    
    // Für kleine Listen kein Scrollen durchführen
    if (_filteredChannels.length <= 7) return;
    
    // Höhe eines Kanaleintrags (inkl. Margin)
    final double itemHeight = 92.0;
    
    // Gesamtanzahl der Sender in der aktuellen Liste
    final int totalChannels = _filteredChannels.length;
    
    // Berechne die sichtbare Höhe des Containers (ungefähr)
    final double viewportHeight = MediaQuery.of(context).size.height - 300; // Abzug von Header, Tabs etc.
    
    // Anzahl der sichtbaren Sender im Viewport
    final int visibleItemCount = (viewportHeight / itemHeight).floor();
    
    // Spezielle Scroll-Logik für Favoriten
    // Die letzten 4 Sender werden nicht automatisch gescrollt
    if (channelIndexToShow >= totalChannels - 4) {
      // Nichts tun - aktuelle Position beibehalten
      return;
    } 
    
    // Für alle anderen Sender: Normal zum Sender scrollen
    double offset = channelIndexToShow * itemHeight;
    
    // Scrolle zur berechneten Position mit Animation
    _channelListController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
  
  // Diese Methode wurde entfernt, da wir die ursprüngliche Tab-Logik im build-Methode verwenden

  @override
  Widget build(BuildContext context) {
    // Bildschirmdimensionen abrufen, um die UI responsiv zu gestalten
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    // Größenanpassung für Tesla-Bildschirme im Querformat
    // Im Bearbeiten-Modus wird der Player ausgeblendet
    final playerHeight = _isInReorderMode ? 0.0 : (isLandscape ? screenHeight * 0.4 : screenHeight * 0.3);
    
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
                    // Im Bearbeiten-Modus sind alle Tabs außer dem Bearbeiten-Tab blockiert
                    if (_isInReorderMode && index != 3) {
                      // Keine Aktion für andere Tabs im Bearbeiten-Modus
                      return;
                    }
                    
                    setState(() {
                      // Aktuelle Scroll-Position speichern, bevor ein Tab gewechselt wird
                      if (_channelListController.hasClients && !_showEpgView && !_showGenresView) {
                        _lastChannelListScrollPosition = _channelListController.offset;
                      }
                      
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
                      
                      // Wenn Bearbeiten-Tab (letzte Tab) gewählt wurde
                      if (index == 3) {
                        // Bearbeiten-Modus umschalten
                        _toggleReorderMode();
                      }
                      // Speichere den vorherigen Zustand und Sichtbarkeiten
                      final bool wasEpgView = _showEpgView;
                      final bool wasGenresView = _showGenresView;
                      
                      // Wenn der Tab bereits ausgewählt ist, deaktiviere ihn
                      _selectedTabIndex = _selectedTabIndex == index ? -1 : index;
                      
                      // Speichere den vorherigen MediaLibrary-Status
                      final bool wasMediaLibraryView = _showMediaLibraryMessage;
                      
                      // Spezielle Behandlung, wenn von einem Tab zurück zur Kanalliste
                      if (_selectedTabIndex == -1 && (wasEpgView || wasGenresView || wasMediaLibraryView)) {
                        // Explizit setzen, damit neu gerendert wird
                        _showEpgView = false;
                        _showGenresView = false;
                        _showMediaLibraryMessage = false;
                        
                        // Nach dem Rendern zur gespeicherten Position scrollen
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_channelListController.hasClients && _lastChannelListScrollPosition > 0) {
                            // Die gespeicherte Position wiederherstellen
                            _channelListController.jumpTo(_lastChannelListScrollPosition);
                          }
                        });
                      }
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
                            child: index == 3 
                              ? _getReorderIcon() // Für Bearbeiten-Tab das spezielle Widget mit Dot verwenden
                              : index == 2
                                ? _getCategoryIconWithIndicator() // Für Kategorien-Tab mit rotem Punkt
                                : Icon(
                                    _tabIcons[index],
                                    // Tab-Farbe: Wenn im Bearbeiten-Modus und nicht der Bearbeiten-Tab, dann Grau mit geringerer Deckkraft
                                    color: _isInReorderMode && index != 3 
                                      ? const Color(0xFF8D9296).withOpacity(0.5) 
                                      : (_selectedTabIndex == index ? Colors.white : const Color(0xFF8D9296)),
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
