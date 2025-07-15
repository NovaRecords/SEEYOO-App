import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Ein globaler Service, der den VideoPlayerController über Rebuilds und Rotationen hinweg hält
class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();
  
  // Spieler für den TV-Favoriten-Bildschirm
  VideoPlayerController? _favoriteScreenController;
  String? _favoriteScreenUrl;
  bool _isFavoriteInitializing = false;
  
  // Gibt den aktuellen Controller zurück oder initialisiert einen neuen, wenn die URL sich geändert hat
  Future<VideoPlayerController?> getFavoriteScreenController(String? url) async {
    // Wenn keine URL angegeben, geben wir den aktuellen Controller zurück (oder null)
    if (url == null || url.isEmpty) {
      return _favoriteScreenController;
    }
    
    // Wenn die URL gleich ist und der Controller bereits existiert, geben wir den bestehenden zurück
    if (url == _favoriteScreenUrl && _favoriteScreenController != null) {
      return _favoriteScreenController;
    }
    
    // Wenn gerade eine Initialisierung läuft, warte kurz und versuche es erneut
    if (_isFavoriteInitializing) {
      await Future.delayed(const Duration(milliseconds: 100));
      return getFavoriteScreenController(url);
    }
    
    // Neue URL, initialisiere neuen Controller
    _isFavoriteInitializing = true;
    
    try {
      // Alten Controller freigeben
      if (_favoriteScreenController != null) {
        await _favoriteScreenController!.dispose();
        _favoriteScreenController = null;
      }
      
      // URL speichern
      _favoriteScreenUrl = url;
      
      // Http-Header für die Stream-Anfrage
      final Map<String, String> httpHeaders = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*',
        'Origin': 'http://app.seeyoo.tv',
        'Referer': 'http://app.seeyoo.tv/'
      };
      
      // Neuen Controller erstellen mit erweiterten Optionen
      _favoriteScreenController = VideoPlayerController.networkUrl(
        Uri.parse(url),
        formatHint: VideoFormat.hls,  // Explizit HLS-Format angeben
        httpHeaders: httpHeaders,     // Custom Headers
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,       // Andere Audio-Quellen stummschalten
          allowBackgroundPlayback: false, // Kein Hintergrund-Playback
        )
      );
      
      // Player initialisieren und abspielen
      await _favoriteScreenController!.initialize();
      _favoriteScreenController!.play();
      
      // Wiederholung aktivieren
      _favoriteScreenController!.setLooping(true);
      
      return _favoriteScreenController;
    } catch (e) {
      print('PlayerService: Fehler beim Initialisieren des Players: $e');
      return null;
    } finally {
      _isFavoriteInitializing = false;
    }
  }
  
  // Gibt an, ob der Controller für den Favoriten-Bildschirm initialisiert ist
  bool isFavoriteControllerInitialized() {
    return _favoriteScreenController?.value.isInitialized ?? false;
  }
  
  // Ressourcen freigeben
  void dispose() {
    if (_favoriteScreenController != null) {
      _favoriteScreenController!.dispose();
      _favoriteScreenController = null;
    }
  }
}
