import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:seeyoo_app/models/epg_program.dart';
import 'package:seeyoo_app/models/tv_channel.dart';
import 'package:seeyoo_app/models/tv_genre.dart';
import 'package:seeyoo_app/services/api_service.dart';
import 'package:seeyoo_app/services/storage_service.dart';
import 'package:seeyoo_app/services/wakelock_service.dart';


class TvScreen extends StatefulWidget {
  const TvScreen({super.key});

  @override
  State<TvScreen> createState() => _TvScreenState();
}

class _TvScreenState extends State<TvScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final StorageService _storageService = StorageService();
  int _selectedTabIndex = -1; // -1 bedeutet kein Tab ist ausgewählt
  int _selectedChannelIndex = 0; // Index des ausgewählten Kanals
  final List<String> _tabTitles = ['Programm', 'Mediathek', 'Kategorien', 'Favoriten'];
  final List<IconData> _tabIcons = [
    Icons.list_alt, // Programm
    Icons.video_library, // Mediathek
    Icons.grid_view, // Kategorien
    Icons.star_border // Favoriten - wird dynamisch aktualisiert
  ];
  
  // ScrollController für die Kategorien-Liste
  final ScrollController _genresScrollController = ScrollController();
  // ScrollController für die Kanalliste
  final ScrollController _channelListController = ScrollController();
  // Speichert die letzte Scroll-Position der Kanalliste
  double _lastChannelListScrollPosition = 0.0;
  // Speichert Scroll-Position speziell für Landscape-Modus
  double _landscapeScrollPosition = 0.0;
  bool _isInLandscapeFullscreen = false;
  // Speichert ursprünglichen Sender-Index beim Landscape-Eintritt
  int _originalChannelIndexForLandscape = -1;
  
  // Animation für Swipe-Visualisierung im Fullscreen
  late AnimationController _swipeAnimationController;
  late Animation<double> _swipeAnimation;
  
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
  bool _isDisposingController = false; // Flag um Controller-Dispose zu verfolgen
  bool _showEpgView = false;
  bool _showGenresView = false;
  bool _showMediaLibraryMessage = false;
  bool _showChannelInfo = false; // Für Landscape-Mode Overlay
  double _savedScrollPosition = 0.0; // Speichert Scroll-Position für Orientierungswechsel
  
  // Für Ping und Media-Info
  Timer? _pingTimer;
  int? _currentChannelId; // Speichert die ID des aktuell angesehenen Kanals
  
  // Timer für Channel-Info Overlay Auto-Hide
  Timer? _channelInfoTimer;
  
  // Timer für verzögertes Anzeigen der Overlay-Info
  Timer? _overlayDelayTimer;
  
  // Animation für Fade-in-Effekt
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  
  // Zeigt an, ob die Overlay-Info bereit ist (nach Verzögerung)
  bool _overlayReady = false;
  
  // Zeitstempel der letzten Overlay-Anzeige (um doppelte Anzeige zu verhindern)
  DateTime? _lastOverlayShow;
  
  // Flag, das anzeigt, ob gerade ein Swipe stattgefunden hat
  bool _recentSwipe = false;
  Timer? _swipeResetTimer;
  
  // Flag, das trackt, ob der Swipe-Hinweis bereits einmal gezeigt wurde
  bool _swipeHintShown = false;
  
  // Video Player
  VideoPlayerController? _videoPlayerController;
  
  // Gibt das passende Stern-Icon zurück (gefüllt oder leer)
  Widget _getFavoriteIcon() {
    if (_selectedChannelIndex >= 0 && _selectedChannelIndex < _channels.length) {
      // Prüfe, ob der ausgewählte Kanal in der Favoritenliste ist
      final selectedChannel = _channels[_selectedChannelIndex];
      
      // Stern-Farbe immer grau
      const iconColor = Color(0xFF8D9296);
      
      // Wenn der Kanal ein Favorit ist, zeige einen gefüllten Stern
      if (selectedChannel.favorite) {
        return const Icon(
          Icons.star,
          color: iconColor,
          size: 26,
        );
      } else {
        return const Icon(
          Icons.star_border,
          color: iconColor,
          size: 26,
        );
      }
    }
    return const Icon(
      Icons.star_border,
      color: Color(0xFF8D9296),
      size: 26,
    );
  }

  @override
  void initState() {
    super.initState();
    
    // App Lifecycle Observer registrieren für Resume-Detection
    WidgetsBinding.instance.addObserver(this);
    
    // Systemstatusleiste anzeigen lassen (transparent)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent status bar
      statusBarIconBrightness: Brightness.light, // Status bar icons' color
    ));
    
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual, 
      overlays: [SystemUiOverlay.top] // Nur obere Statusleiste anzeigen
    );
    
    // TV-Screen darf auch Landscape verwenden
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Animation Controller für Swipe-Visualisierung initialisieren
    _swipeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _swipeAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _swipeAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Animation Controller für Fade-in-Effekt initialisieren
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _loadChannels();
    _loadGenres();
    _loadSavedCategory(); // Lade die gespeicherte Kategorie
    
    // Wakelock aktivieren - Bildschirm darf während TV-Wiedergabe nicht ausgehen
    WakelockService().enableWakelock();
    
    // Sende sofort einen initialen Ping beim Start
    _pingServer();
    
    // Starte den Ping-Timer (alle 120 Sekunden)
    _pingTimer = Timer.periodic(const Duration(seconds: 120), (timer) {
      _pingServer();
    });
  }
  
  // App Lifecycle State Changes überwachen (für iOS Resume-Problem)
  @override
  DateTime? _backgroundTime;
  bool _isResuming = false;

  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    
    print('App Lifecycle State changed to: $state');
    
    // Wenn App aus dem Hintergrund zurückkehrt (resumed)
    if (state == AppLifecycleState.resumed) {
      if (_isResuming) {
        print('Resume already in progress, skipping...');
        return;
      }
      
      print('App resumed from background - checking connection');
      
      // Kurze Verzögerung um Android Auto-Resume abzuwarten
      await Future.delayed(Duration(milliseconds: 500));
      
      // Prüfe ob Player bereits automatisch resumed ist (Android-Verhalten)
      if (_videoPlayerController?.value.isPlaying == true) {
        print('Player already resumed automatically - skipping reconnection');
        _isResuming = false;
        _backgroundTime = null;
        return;
      }
      
      // Berechne wie lange die App im Hintergrund war
      final backgroundDuration = _backgroundTime != null 
          ? DateTime.now().difference(_backgroundTime!)
          : Duration.zero;
      
      print('App was in background for: ${backgroundDuration.inMinutes} minutes (${backgroundDuration.inSeconds} seconds)');
      
      // Da Token in Produktion alle 5 Sekunden ablaufen, immer Full Reconnection
      print('Performing full reconnection (tokens expire every 5 seconds in production)');
      _performFullReconnection(); 
    }
    
    // Wenn App in den Hintergrund geht - nur beim ersten paused Event speichern
    else if (state == AppLifecycleState.paused && _backgroundTime == null) {
      print('App going to background - saving timestamp');
      _backgroundTime = DateTime.now();
    }
    
    // Wenn App wieder aktiv wird, Background-Zeit zurücksetzen
    else if (state == AppLifecycleState.resumed) {
      _backgroundTime = null;
    }
  }
  
  Future<void> _performQuickRestart() async {
    if (_isResuming) return;
    _isResuming = true;
    
    try {
      // Ping senden um Verbindung zu reaktivieren
      await _pingServer();
      
      // Video-Stream neu starten, wenn ein Kanal ausgewählt ist
      if (_currentStreamUrl != null && _currentStreamUrl!.isNotEmpty) {
        print('Quick restart - restarting video stream: $_currentStreamUrl');
        
        // RESUME: Garbage Collector Strategie um Race Conditions zu vermeiden
        await _initializeOrUpdatePlayer(_currentStreamUrl!, disposeOldController: false);
      }
    } catch (e) {
      print('Quick restart failed: $e - performing full reconnection');
      await _performFullReconnection();
    } finally {
      _isResuming = false;
    }
  }
  
  Future<void> _performFullReconnection() async {
    if (_isResuming) return;
    _isResuming = true;
    
    try {
      print('Starting full reconnection process...');
      
      // 1. Server-Verbindung testen und wiederherstellen
      await _pingServer();
      
      // 2. Session validieren/erneuern
      print('Validating session...');
      try {
        await _apiService.pingServer();
      } catch (e) {
        print('Session validation failed: $e');
        // Bei Session-Problemen könnte eine Neuanmeldung nötig sein
      }
      
      // 3. Kanalliste neu laden
      print('Reloading channel list...');
      await _loadChannels();
      
      // 4. Aktuellen Stream wiederherstellen
      if (_currentStreamUrl != null && _currentStreamUrl!.isNotEmpty) {
        print('Full reconnection - restarting video stream: $_currentStreamUrl');
        
        // RESUME: Garbage Collector Strategie um Race Conditions zu vermeiden
        await _initializeOrUpdatePlayer(_currentStreamUrl!, disposeOldController: false);
      }
      
      print('Full reconnection completed successfully');
      
    } catch (e) {
      print('Full reconnection failed: $e');
      
      // Als letzter Ausweg: Fehlermeldung anzeigen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verbindung wiederhergestellt. Bitte Kanal neu wählen falls Probleme auftreten.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      _isResuming = false;
    }
  }
  
  @override
  void dispose() {
    // App Lifecycle Observer entfernen
    WidgetsBinding.instance.removeObserver(this);
    
    // ScrollController freigeben, wenn das Widget entsorgt wird
    _genresScrollController.dispose();
    _channelListController.dispose();
    
    // Timer beenden und Media-Info entfernen
    _pingTimer?.cancel();
    _channelInfoTimer?.cancel();
    _overlayDelayTimer?.cancel();
    _swipeResetTimer?.cancel();
    _apiService.removeMediaInfo(); // Media-Info beim Verlassen des Screens entfernen
    
    // HYBRIDE LÖSUNG: Beim Screen-Wechsel explizit dispose() um Player zu stoppen
    // (Bei Controller-Neuinitialisierung verwenden wir weiterhin Garbage Collector)
    if (_videoPlayerController != null) {
      print('Disposing VideoPlayerController on screen exit...');
      _videoPlayerController!.dispose();
      _videoPlayerController = null;
    }
    
    // Animation Controller freigeben
    _swipeAnimationController.dispose();
    _fadeAnimationController.dispose();
    
    // Orientierung zurücksetzen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Wakelock bleibt global aktiv - wird nicht deaktiviert
    
    super.dispose();
  }

  
  // Lädt EPG-Daten für alle Kanäle auf einmal
  Future<void> _loadAllChannelsEpgData() async {
    if (!mounted) return;
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
          if (mounted) {
            setState(() {
              _epgDataMap[channel.id] = epgData;
              _epgLoadingStatus[channel.id] = false;
            });
          }
        }).catchError((e) {
          if (mounted) {
            setState(() {
              _epgLoadingStatus[channel.id] = false;
            });
          }
          print('Fehler beim Laden der EPG-Daten für Kanal ${channel.id}: $e');
        });
        
        futures.add(future);
      }
      
      // Auf alle API-Anfragen warten
      await Future.wait(futures);
      
      if (!mounted) return;
      setState(() {
        _isLoadingEpg = false;
      });
    } catch (e) {
      if (!mounted) return;
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
          // Hier könnte man eine Fehlermeldung setzen, falls gewünscht
        });
      }
    }
  }
  
  // Lädt die gespeicherte Kategorie-Auswahl
  Future<void> _loadSavedCategory() async {
    final savedGenreId = await _storageService.getSelectedTvGenre();
    
    // Nur fortfahren, wenn ein Genre gespeichert war und das Widget noch gemountet ist
    if (savedGenreId != null && mounted) {
      // Überprüfe, ob die Kanäle bereits geladen sind
      if (_channels.isNotEmpty) {
        // Filtere die Kanäle nach der gespeicherten Genre-ID
        _filterChannelsByGenre(savedGenreId);
      } else {
        // Setze nur die Genre-ID, die tatsächliche Filterung erfolgt später in _loadChannels
        _selectedGenreId = savedGenreId;
      }
    }
  }

  // Filtert Kanäle nach ausgewähltem Genre
  void _filterChannelsByGenre(String? genreId) {
    setState(() {
      _selectedGenreId = genreId;
      
      if (genreId == null) {
        _filteredChannels = List.from(_channels);
      } else {
        _filteredChannels = _channels.where((channel) => 
          channel.genreId == genreId).toList();
      }
      
      // Speichere die ausgewählte Kategorie lokal
      _storageService.saveSelectedTvGenre(genreId);
    });
  }
  
  // Lädt TV-Kanäle aus der API
  Future<void> _loadChannels() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Lade Kanäle vom API
      final channels = await _apiService.getTvChannels();
      final favoriteChannels = await _apiService.getFavoriteTvChannels();
      
      if (!mounted) return;
      setState(() {
        _channels = channels;
        _favoriteChannels = favoriteChannels;
        // Nur alle Kanäle anzeigen, wenn keine Kategorie ausgewählt ist
        if (_selectedGenreId == null || _selectedGenreId == 'all') {
          _filteredChannels = List.from(channels);
        } else {
          // Wende den Kategoriefilter an
          _filteredChannels = channels.where((channel) => channel.genreId == _selectedGenreId).toList();
        }
        _isLoading = false;
      });
      
      // Versuche den zuletzt gesehenen Kanal zu laden, ansonsten den ersten
      if (_channels.isNotEmpty && mounted) {
        await _loadLastWatchedChannel();
        
        // Lade EPG-Daten für alle Kanäle auf einmal
        if (mounted) {
          await _loadAllChannelsEpgData();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler beim Laden der Kanäle: $e';
      });
    }
  }

  // Lädt und selektiert den zuletzt gesehenen Kanal
  Future<void> _loadLastWatchedChannel() async {
    if (!mounted) return;
  
    try {
      // Zuerst versuchen, den lokal gespeicherten TV-Kanal zu laden
      final lastTvChannelId = await _storageService.getLastTvChannel();
      
      // Prüfen, ob das Widget noch mounted ist nach dem asynchronen Aufruf
      if (!mounted) return;
      
      // Prüfen ob der lokal gespeicherte TV-Kanal vorhanden ist
      if (lastTvChannelId != null && _channels.isNotEmpty) {
        // Suche den Kanal mit dieser ID
        final index = _channels.indexWhere((channel) => channel.id == lastTvChannelId);
        
        if (index >= 0 && mounted) {
          // Lokal gespeicherter Kanal gefunden, wähle ihn aus
          print('Wähle lokal gespeicherten TV-Kanal mit ID $lastTvChannelId aus');
          _selectChannel(index);
          return;
        }
      }
      
      // Fallback: Wenn kein lokaler TV-Kanal gefunden wurde, versuche den vom Server
      final lastChannelId = await _apiService.getLastWatchedChannel();
      
      // Erneut prüfen nach einem asynchronen Aufruf
      if (!mounted) return;
      
      if (lastChannelId != null && _channels.isNotEmpty) {
        // Suche den Kanal mit dieser ID
        final index = _channels.indexWhere((channel) => channel.id == lastChannelId);
        
        if (index >= 0 && mounted) {
          // Zuletzt gesehener Kanal gefunden, wähle ihn aus
          print('Wähle zuletzt gesehenen Kanal mit ID $lastChannelId aus');
          _selectChannel(index);
          return;
        }
      }
      
      // Fallback: Wenn kein zuletzt gesehener Kanal gefunden wurde, wähle den ersten
      if (_channels.isNotEmpty && mounted) {
        print('Kein zuletzt gesehener Kanal gefunden, wähle ersten Kanal');
        _selectChannel(0);
      }
    } catch (e) {
      print('Fehler beim Laden des zuletzt gesehenen Kanals: $e');
      // Fallback im Fehlerfall: Ersten Kanal wählen
      if (_channels.isNotEmpty && mounted) {
        _selectChannel(0);
      }
    }
  }

  // Wähle einen Kanal aus und lade den Stream
  void _selectChannel(int index) async {
    if (index >= 0 && index < _channels.length) {
      // Falls ein vorheriger Kanal ausgewählt war, entferne dessen Media-Info
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
        
        // Initialisiere oder aktualisiere den Player
        await _initializeOrUpdatePlayer(channel.url!);
        
        // Aktualisiere Media-Info für den ausgewählten Kanal
        await _apiService.updateMediaInfo(type: 'tv-channel', mediaId: channel.id);
        // Speichere diesen Kanal als zuletzt gesehenen (global auf dem Server)
        await _apiService.saveLastWatchedChannel(channel.id);
        // Speichere diesen Kanal auch lokal als zuletzt gesehenen TV-Kanal
        await _storageService.saveLastTvChannel(channel.id);
        print('Media-Info aktualisiert für Kanal ${channel.id}');
        
        // Show channel info overlay in fullscreen mode when channel starts
        if (MediaQuery.of(context).orientation == Orientation.landscape) {
          _showChannelInfoOverlay();
        }
      } else {
        try {
          final streamUrl = await _apiService.getTvChannelLink(channel.id);
          if (streamUrl != null) {
            setState(() {
              _currentStreamUrl = streamUrl;
            });
            
            // Initialisiere oder aktualisiere den Player
            await _initializeOrUpdatePlayer(streamUrl);
            
            // Aktualisiere Media-Info für den ausgewählten Kanal
            await _apiService.updateMediaInfo(type: 'tv-channel', mediaId: channel.id);
            // Speichere diesen Kanal als zuletzt gesehenen (global auf dem Server)
            await _apiService.saveLastWatchedChannel(channel.id);
            // Speichere diesen Kanal auch lokal als zuletzt gesehenen TV-Kanal
            await _storageService.saveLastTvChannel(channel.id);
            print('Media-Info aktualisiert für Kanal ${channel.id}');
            
            // Show channel info overlay in fullscreen mode when channel starts
            if (MediaQuery.of(context).orientation == Orientation.landscape) {
              _showChannelInfoOverlay();
            }
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
          
          // Aktualisiere die gefilterte Kanalliste basierend auf aktueller Kategorie
          _filterChannelsByGenre(_selectedGenreId);
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
                              fontSize: 20,
                            ),
                          ),
                        )
                      : Text(
                          genre.title,
                          style: const TextStyle(
                            color: Color(0xFF8D9296),
                            fontWeight: FontWeight.normal,
                            fontSize: 20,
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Diese Funktion befindet sich\nnoch in der Entwicklung\nund wird mit dem nächsten\nRelease verfügbar sein.',
              style: TextStyle(color: const Color(0xFF8D9296), fontSize: 16),
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
                style: TextStyle(color: const Color(0xFF8D9296), fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Die elektronischen Programminformationen (EPG) werden in Kürze aktiviert.',
                textAlign: TextAlign.center,
                style: TextStyle(color: const Color(0xFF8D9296), fontSize: 16),
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
                                fontSize: 18,
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
                                fontSize: 14,
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          // Programmtitel
                          Text(
                            program.name,
                            style: TextStyle(
                              color: isNowPlaying ? Colors.white : const Color(0xFF8D9296),
                              fontSize: 18,
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
                          // Kanalname
                          Text(
                            channel.name,
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          
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
                                  fontSize: 14,
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
                                'Keine EPG-Daten verfügbar',
                                style: TextStyle(
                                  color: const Color(0xFF8D9296),
                                  fontSize: 14,
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
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          currentProgram.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }
                            
                            return Text(
                              'Keine Programminformationen verfügbar',
                              style: TextStyle(
                                color: const Color(0xFF8D9296),
                                fontSize: 14,
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
                  top: 12,
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
  
  // Sendet ein Ping zum Server
  Future<void> _pingServer() async {
    // Ping-Anfrage an den Server senden
    await _apiService.pingServer();
    // Debug-Ausgabe
    print('Ping gesendet: ${DateTime.now()}');
  }
  
  // Initialisiert oder aktualisiert den VideoPlayer
  Future<void> _initializeOrUpdatePlayer(String url, {bool disposeOldController = true}) async {
    try {
      if (_videoPlayerController != null) {
        if (disposeOldController) {
          // KANALWECHSEL: Explizites dispose() um alten Player zu stoppen
          print('Disposing old VideoPlayerController for channel switch...');
          await _videoPlayerController!.dispose();
          _videoPlayerController = null;
        } else {
          // RESUME: Garbage Collector Strategie um Race Conditions zu vermeiden
          print('Creating new VideoPlayerController (old controller will be garbage collected)...');
          _videoPlayerController = null;
        }
      }
      
      // Http-Header für die Stream-Anfrage
      final Map<String, String> httpHeaders = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*',
        'Origin': 'http://app.seeyoo.tv',
        'Referer': 'http://app.seeyoo.tv/'
      };
      
      // Korrigierte URL und optimierte Optionen für Android
      final playerUrl = url.trim();
      
      // Neuen Controller erstellen mit erweiterten Optionen
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(playerUrl),
        formatHint: VideoFormat.hls,  // Explizit HLS-Format angeben
        httpHeaders: httpHeaders,     // Custom Headers
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,       // Andere Audio-Quellen stummschalten
          allowBackgroundPlayback: false, // Kein Hintergrund-Playback
        )
      );
      
      // Player initialisieren und abspielen
      await _videoPlayerController!.initialize();
      _videoPlayerController!.play();
      
      // Wiederholung aktivieren
      _videoPlayerController!.setLooping(true);
      
      // UI aktualisieren, damit der neue Player angezeigt wird
      setState(() {
        _errorMessage = null; // Fehler zurücksetzen, falls vorhanden
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden des Kanal-Streams: $e';
        print('VideoPlayer-Fehler: $e'); // Für Debug-Zwecke
      });
    }
  }
  
  // Scrollt zum ausgewählten Kanal in der Liste
  void _scrollToSelectedChannel() {
    // Prüfe, ob der Controller an eine ScrollView angebunden ist
    if (!_channelListController.hasClients) return;
    
    // Bestimme den Index des zu scrollenden Elements je nach aktuellem Tab/Filter
    int channelIndexToShow;
    
    if (_selectedTabIndex == 3) { // Favoriten-Tab
      channelIndexToShow = _selectedChannelIndex;
    } else {
      // Suche den ausgewählten Kanal in der gefilterten Liste
      channelIndexToShow = _filteredChannels.indexWhere((channel) => 
          _channels.isNotEmpty && _selectedChannelIndex < _channels.length &&
          channel.id == _channels[_selectedChannelIndex].id);
    }
    
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
    
    // Ganz einfache Logik für alle Sender
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

  // Spezielle Scroll-Methode für Landscape-zu-Portrait-Wechsel
  // Diese Methode behandelt die letzten 4 Sender korrekt
  void _scrollToSelectedChannelFromLandscape() {
    // Prüfe, ob der Controller an eine ScrollView angebunden ist
    if (!_channelListController.hasClients) return;
    
    // Bestimme den Index des zu scrollenden Elements je nach aktuellem Tab/Filter
    int channelIndexToShow;
    
    if (_selectedTabIndex == 3) { // Favoriten-Tab
      channelIndexToShow = _selectedChannelIndex;
    } else {
      // Suche den ausgewählten Kanal in der gefilterten Liste
      channelIndexToShow = _filteredChannels.indexWhere((channel) => 
          _channels.isNotEmpty && _selectedChannelIndex < _channels.length &&
          channel.id == _channels[_selectedChannelIndex].id);
    }
    
    // Wenn der Kanal nicht in der aktuellen Liste gefunden wurde
    if (channelIndexToShow < 0) return;
    
    // Für kleine Listen kein Scrollen durchführen
    if (_filteredChannels.length <= 7) return;
    
    // Höhe eines Kanaleintrags (inkl. Margin)
    final double itemHeight = 92.0;
    
    // Gesamtanzahl der Sender in der aktuellen Liste
    final int totalChannels = _filteredChannels.length;
    
    // SPEZIELLE LOGIK FÜR LANDSCAPE-ZU-PORTRAIT-WECHSEL:
    // Wenn es einer der letzten 4 Sender ist, scrolle bis zum Ende der Liste
    if (channelIndexToShow >= totalChannels - 4) {
      // Direkt ausführen, da wir bereits im PostFrameCallback der build() sind
      if (_channelListController.hasClients && _channelListController.position.hasContentDimensions) {
        // Verwende den tatsächlichen maxScrollExtent für präzises Scrolling
        double maxOffset = _channelListController.position.maxScrollExtent;
        
        _channelListController.animateTo(
          maxOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        // Fallback: Verwende jumpTo mit berechneter Position
        double fallbackOffset = (totalChannels - 1) * itemHeight;
        _channelListController.jumpTo(fallbackOffset);
      }
      return;
    } 
    
    // Für alle anderen Sender: Normal zum Sender scrollen (erste Position)
    double offset = channelIndexToShow * itemHeight;
    
    // Scrolle zur berechneten Position mit Animation
    _channelListController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
  
  // Helper Methoden für Landscape-Mode
  void _switchToPreviousChannel() {
    final currentIndex = _selectedChannelIndex;
    if (currentIndex > 0) {
      _selectChannel(currentIndex - 1);
    } else {
      _selectChannel(_filteredChannels.length - 1); // Zum letzten Kanal springen
    }
  }
  
  void _switchToNextChannel() {
    final currentIndex = _selectedChannelIndex;
    if (currentIndex < _filteredChannels.length - 1) {
      _selectChannel(currentIndex + 1);
    } else {
      _selectChannel(0); // Zum ersten Kanal springen
    }
  }

  // Gibt die aktuelle Kanalliste zurück (gefiltert oder alle)
  List<TvChannel> _getCurrentChannelList() {
    return _filteredChannels.isNotEmpty ? _filteredChannels : _channels;
  }

  // Gibt den Index des aktuellen Kanals in der gefilterten Liste zurück
  int _getFilteredChannelIndex() {
    if (_selectedChannelIndex < 0 || _selectedChannelIndex >= _channels.length) {
      return 0;
    }
    
    final currentChannel = _channels[_selectedChannelIndex];
    final currentList = _getCurrentChannelList();
    
    final index = currentList.indexWhere((channel) => channel.id == currentChannel.id);
    return index >= 0 ? index : 0;
  }

  void _selectChannelFromDisplayedList(int displayedIndex) async {
    final displayedChannels = _getCurrentChannelList();
    if (displayedIndex < 0 || displayedIndex >= displayedChannels.length) return;
    
    final channel = displayedChannels[displayedIndex];
    
    // Finde den Index dieses Kanals in der vollständigen Liste
    final fullIndex = _channels.indexWhere((fullChannel) => fullChannel.id == channel.id);
    
    if (fullIndex >= 0) {
      // Benutze die normale _selectChannel Methode mit dem vollständigen Index
      _selectChannel(fullIndex);
    } else {
      // Debug: Kanal nicht in vollständiger Liste gefunden
      print('DEBUG: Kanal ${channel.name} (ID: ${channel.id}) nicht in vollständiger Liste gefunden!');
    }
  }

  // Fullscreen-spezifische Navigation - arbeitet mit der aktuellen gefilterten Liste
  void _switchToNextChannelInFullscreen() async {
    // Swipe-Flag setzen
    _recentSwipe = true;
    _swipeResetTimer?.cancel();
    _swipeResetTimer = Timer(const Duration(seconds: 6), () {
      _recentSwipe = false;
    });
    
    // Animation sofort starten, um alten Stream zu überdecken
    _performSwipeAnimation(-1.0);
    
    // Channel-Switch parallel ausführen
    final currentList = _getCurrentChannelList();
    final currentIndex = _getFilteredChannelIndex();
    
    if (currentIndex < currentList.length - 1) {
      _selectChannelFromDisplayedList(currentIndex + 1);
    } else {
      // Zum ersten Kanal springen
      _selectChannelFromDisplayedList(0);
    }
    
    // Show channel info overlay for 3 seconds after channel switch
    _showChannelInfoOverlay(forceShow: true);
  }
  

  void _switchToPreviousChannelInFullscreen() async {
    // Swipe-Flag setzen
    _recentSwipe = true;
    _swipeResetTimer?.cancel();
    _swipeResetTimer = Timer(const Duration(seconds: 6), () {
      _recentSwipe = false;
    });
    
    // Animation sofort starten, um alten Stream zu überdecken
    _performSwipeAnimation(1.0);
    
    // Channel-Switch parallel ausführen
    final currentList = _getCurrentChannelList();
    final currentIndex = _getFilteredChannelIndex();
    
    if (currentIndex > 0) {
      _selectChannelFromDisplayedList(currentIndex - 1);
    } else {
      // Zum letzten Kanal springen
      _selectChannelFromDisplayedList(currentList.length - 1);
    }
    
    // Show channel info overlay for 3 seconds after channel switch
    _showChannelInfoOverlay(forceShow: true);
  }
  
  void _showChannelInfoOverlay({bool forceShow = false}) {
    // Prüfe, ob gerade ein Swipe stattgefunden hat und dies kein forceShow ist
    if (!forceShow && _recentSwipe) {
      return; // Overlay nicht anzeigen, da kürzlich ein Swipe stattgefunden hat
    }
    
    // Zusätzliche Zeitprüfung
    final now = DateTime.now();
    if (!forceShow && _lastOverlayShow != null) {
      final timeSinceLastShow = now.difference(_lastOverlayShow!).inSeconds;
      if (timeSinceLastShow < 5) {
        return; // Overlay nicht anzeigen, da zu kurz nach letzter Anzeige
      }
    }
    
    // Setze Zeitstempel der aktuellen Anzeige
    _lastOverlayShow = now;
    
    // Cancel existing timers if running
    _channelInfoTimer?.cancel();
    _overlayDelayTimer?.cancel();
    
    // Reset animation und overlay state
    _fadeAnimationController.reset();
    setState(() {
      _showChannelInfo = true;
      _overlayReady = false;
    });
    
    // Start delay timer (500ms)
    _overlayDelayTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _overlayReady = true;
        });
        // Start fade-in animation
        _fadeAnimationController.forward();
        
        // Set new timer to hide after 3 seconds (after fade-in)
        _channelInfoTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            _fadeAnimationController.reverse().then((_) {
              if (mounted) {
                setState(() {
                  _showChannelInfo = false;
                  _overlayReady = false;
                  // Swipe-Hinweis als gezeigt markieren nach dem ersten Fade-Out
                  if (!_swipeHintShown) {
                    _swipeHintShown = true;
                  }
                });
              }
            });
          }
        });
      }
    });
  }
  
  // Builds the new TV Channel Strip-style overlay with EPG data
  Widget _buildChannelInfoOverlay() {
    if (_selectedChannelIndex < 0 || _selectedChannelIndex >= _channels.length) {
      return const SizedBox.shrink();
    }
    
    final channel = _channels[_selectedChannelIndex];
    final epgData = _epgDataMap[channel.id] ?? [];
    
    // Find current and next program
    EpgProgram? currentProgram;
    EpgProgram? nextProgram;
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    for (int i = 0; i < epgData.length; i++) {
      final program = epgData[i];
      if (now >= program.start && now < program.end) {
        currentProgram = program;
        // Find next program
        if (i + 1 < epgData.length) {
          nextProgram = epgData[i + 1];
        }
        break;
      }
    }
    
    // If no current program found, try to find the next upcoming one
    if (currentProgram == null && epgData.isNotEmpty) {
      for (final program in epgData) {
        if (now < program.start) {
          nextProgram = program;
          break;
        }
      }
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      padding: const EdgeInsets.only(left: 16, right: 10, top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E22).withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Channel Logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[800],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (channel.logo != null && channel.logo!.isNotEmpty)
                      ? Image.network(
                          channel.logo!.startsWith('http') ? channel.logo! : 'http://app.seeyoo.tv${channel.logo!}',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.tv,
                                color: Colors.white54,
                                size: 30,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.tv,
                            color: Colors.white54,
                            size: 30,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Channel Info and EPG Data
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Channel Name
                    Text(
                      channel.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Current Program
                    if (currentProgram != null) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentProgram.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        'Keine Programminformationen verfügbar',
                        style: TextStyle(
                          color: Color(0xFF8D9296),
                          fontSize: 16,
                        ),
                      ),
                    ],
                    
                    // Next Program (if available)
                    if (nextProgram != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            nextProgram.startTimeFormatted,
                            style: const TextStyle(
                              color: Color(0xFFE53A56),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              nextProgram.name,
                              style: const TextStyle(
                                color: Color(0xFF8D9296),
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }
  
  // Swipe-Animation für Fullscreen-Player - Karussell-Effekt
  Future<void> _performSwipeAnimation(double direction) async {
    // Animation: Aktueller Sender fährt komplett weg, neuer kommt von der anderen Seite
    _swipeAnimation = Tween<double>(
      begin: 0.0,
      end: direction, // -1.0 = links raus, 1.0 = rechts raus
    ).animate(CurvedAnimation(
      parent: _swipeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Animiere komplett durch (alter Sender verschwindet, neuer erscheint)
    await _swipeAnimationController.forward();
    
    // Reset für nächste Animation
    _swipeAnimationController.reset();
  }
  
  // Sender-Logo Widget für Fullscreen und Portrait
  Widget _buildChannelLogo() {
    if (_selectedChannelIndex < 0 || _selectedChannelIndex >= _channels.length) {
      return Container(
        color: Colors.black54,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA1273B)),
          ),
        ),
      );
    }
    
    final channel = _channels[_selectedChannelIndex];
    
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sender-Logo (60x60px)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: channel.logo != null && channel.logo!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        channel.logo!.startsWith('http') 
                          ? channel.logo! 
                          : 'http://app.seeyoo.tv${channel.logo!}',
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.tv,
                              color: Colors.white54,
                              size: 30,
                            ),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.tv,
                        color: Colors.white54,
                        size: 30,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            // Sender-Name
            Container(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                channel.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // Loading-Indikator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA1273B)),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Landscape Fullscreen View - nutzt bestehenden Player
  Widget _buildLandscapeFullscreenView() {
    // System UI komplett verstecken - immersive Vollbild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
    
    return Material(
      color: Colors.black,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 300) {
            // Swipe nach rechts - vorheriger Kanal
            _switchToPreviousChannelInFullscreen();
          } else if (details.primaryVelocity! < -300) {
            // Swipe nach links - nächster Kanal
            _switchToNextChannelInFullscreen();
          }
        },
        onTap: () {
          // Kanal-Info anzeigen beim Tippen
          _showChannelInfoOverlay(forceShow: true);
        },
        onDoubleTap: () {
          // Zu Portrait zurückkehren
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
        },
        child: Stack(
          children: [
            // Video Player mit Swipe-Animation
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: AnimatedBuilder(
                  animation: _swipeAnimation,
                  builder: (context, child) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final currentOffset = _swipeAnimation.value * screenWidth;
                    final nextOffset = currentOffset + screenWidth * (_swipeAnimation.value > 0 ? -1 : 1);
                    
                    return Stack(
                      children: [
                        // Aktueller Sender (fährt weg)
                        Transform.translate(
                          offset: Offset(currentOffset, 0),
                          child: _currentStreamUrl != null && _videoPlayerController != null && 
                                 _videoPlayerController!.value.isInitialized
                              ? VideoPlayer(_videoPlayerController!)
                              : _errorMessage != null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (_selectedChannelIndex >= 0 && _selectedChannelIndex < _channels.length) {
                                              _selectChannel(_selectedChannelIndex);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFA1273B),
                                          ),
                                          child: const Text(
                                            'Erneut versuchen',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    )
                                  : _buildChannelLogo(),
                        ),
                        // Swipe hint bar at top (nur beim ersten Mal anzeigen)
                        if (_showChannelInfo && _overlayReady && !_swipeHintShown)
                          Positioned(
                            top: 20,
                            left: 0,
                            right: 0,
                            child: Transform.translate(
                              offset: Offset(currentOffset, 0),
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: _fadeAnimation,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _fadeAnimation.value,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1B1E22).withOpacity(0.85),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.swipe, color: Colors.white54, size: 16),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Wischen zum Kanalwechsel',
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        // Channel Info Overlay (swipes with content)
                        if (_showChannelInfo && _overlayReady && _selectedChannelIndex >= 0 && _selectedChannelIndex < _channels.length)
                          Positioned(
                            bottom: 12,
                            left: currentOffset,
                            right: -currentOffset,
                            child: AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: _buildChannelInfoOverlay(),
                                );
                              },
                            ),
                          ),
                        // Nächster Sender (fährt rein) - nur während Animation
                        if (_swipeAnimation.value != 0.0)
                          Transform.translate(
                            offset: Offset(nextOffset, 0),
                            child: _buildChannelLogo(), // Zeige Logo des nächsten Senders
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),


          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Sicherstellen, dass Orientierung immer korrekt gesetzt ist (nach Menü-Wechsel)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
    
    // Bildschirmdimensionen abrufen, um die UI responsiv zu gestalten
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    // Bei Landscape-Orientierung wird der Player fullscreen angezeigt
    if (isLandscape && _channels.isNotEmpty) {
      // Scroll-Position und ursprünglichen Sender-Index speichern beim ersten Wechsel ins Landscape
      if (!_isInLandscapeFullscreen && _channelListController.hasClients) {
        _landscapeScrollPosition = _channelListController.offset;
        _originalChannelIndexForLandscape = _selectedChannelIndex;
        _isInLandscapeFullscreen = true;
        
        // Overlay-Info beim Wechsel in Fullscreen-Modus anzeigen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showChannelInfoOverlay();
          }
        });
      }
      return _buildLandscapeFullscreenView();
    } else if (_isInLandscapeFullscreen) {
      // Zurück aus Landscape - intelligente Scroll-Position wiederherstellen
      _isInLandscapeFullscreen = false;
      _swipeHintShown = false; // Swipe-Hinweis wieder zurücksetzen für nächsten Landscape-Wechsel
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_channelListController.hasClients) {
          // Prüfen, ob sich der Sender geändert hat
          if (_selectedChannelIndex != _originalChannelIndexForLandscape) {
            // Sender hat sich geändert - spezielle Landscape-zu-Portrait-Scroll-Logik verwenden
            _scrollToSelectedChannelFromLandscape();
          } else if (_landscapeScrollPosition > 0) {
            // Sender unverändert - ursprüngliche Position wiederherstellen
            _channelListController.jumpTo(_landscapeScrollPosition);
          }
        }
      });
      // System UI wiederherstellen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    }
    
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
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA1273B)),
                  ))
                else
                  // Nur Fehlermeldungen anzeigen, kein Icon oder "Kein Kanal ausgewählt"-Nachricht
                  if (_errorMessage != null)
                    Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                // Video Player oder Sender-Logo
                if (_currentStreamUrl != null && _videoPlayerController != null && _videoPlayerController!.value.isInitialized)
                  Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width,
                        maxHeight: MediaQuery.of(context).size.width * 9 / 16, // Erzwinge 16:9
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 9, // Striktes 16:9-Verhältnis
                        child: VideoPlayer(_videoPlayerController!),
                      ),
                    ),
                  )
                else if (_selectedChannelIndex >= 0 && _selectedChannelIndex < _channels.length)
                  Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width,
                        maxHeight: MediaQuery.of(context).size.width * 9 / 16, // Erzwinge 16:9
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 9, // Striktes 16:9-Verhältnis
                        child: _buildChannelLogo(), // Zeige Sender-Logo anstelle des Loading-Circles
                      ),
                    ),
                  ),
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
                      
                      // Wenn Favoriten-Tab gewählt wird, Favoriten-Status umschalten
                      if (index == 3) {
                        _toggleFavorite();
                      }
                      // Speichere den vorherigen Zustand und Sichtbarkeiten
                      final bool wasEpgView = _showEpgView;
                      final bool wasGenresView = _showGenresView;
                      final bool wasMediaLibraryView = _showMediaLibraryMessage;
                      
                      // Wenn der Tab bereits ausgewählt ist, deaktiviere ihn
                      _selectedTabIndex = _selectedTabIndex == index ? -1 : index;
                      
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
                          child: Stack(
                            children: [
                              Center(
                                child: index == 3 
                                  ? _getFavoriteIcon() // Für Favoriten-Tab das Widget verwenden
                                  : Icon(
                                      _tabIcons[index],
                                      color: index == 3 ? const Color(0xFF8D9296) : (_selectedTabIndex == index ? Colors.white : const Color(0xFF8D9296)),
                                      size: 26,
                                    ),
                              ),
                              // Roter Punkt für Kategorien-Tab, wenn eine Kategorie ausgewählt ist
                              if (index == 2 && _selectedGenreId != null && _selectedGenreId != 'all')
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE53A56), // Rote Farbe für den Punkt
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tabTitles[index],
                          style: TextStyle(
                            color: index == 3 ? const Color(0xFF8D9296) : (_selectedTabIndex == index ? Colors.white : const Color(0xFF8D9296)),
                            fontWeight: _selectedTabIndex == index ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
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
                        : _buildChannelList(_filteredChannels) // Zeige immer die gefilterte Hauptliste, auch wenn Favoriten-Tab aktiv
            ),
          ),
        ],
      ),
    );
  }
}
