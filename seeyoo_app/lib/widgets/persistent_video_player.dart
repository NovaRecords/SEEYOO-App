import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Ein Widget, das den VideoPlayer kapselt und seinen Zustand auch bei Layoutänderungen beibehält
class PersistentVideoPlayer extends StatefulWidget {
  final String? streamUrl;
  final double aspectRatio;

  const PersistentVideoPlayer({
    Key? key,
    required this.streamUrl,
    this.aspectRatio = 16 / 9,
  }) : super(key: key);

  @override
  State<PersistentVideoPlayer> createState() => _PersistentVideoPlayerState();
}

class _PersistentVideoPlayerState extends State<PersistentVideoPlayer> with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _videoPlayerController;
  String? _currentStreamUrl;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(PersistentVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nur neu initialisieren, wenn sich die Stream-URL tatsächlich geändert hat
    if (widget.streamUrl != oldWidget.streamUrl) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    if (widget.streamUrl == null || widget.streamUrl!.isEmpty) {
      return;
    }

    // Wenn die URL gleich ist, nichts tun
    if (_currentStreamUrl == widget.streamUrl && _videoPlayerController != null) {
      return;
    }

    _currentStreamUrl = widget.streamUrl;

    if (_videoPlayerController != null) {
      await _videoPlayerController!.dispose();
      _videoPlayerController = null;
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }

    try {
      // Http-Header für die Stream-Anfrage
      final Map<String, String> httpHeaders = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*',
        'Origin': 'http://app.seeyoo.tv',
        'Referer': 'http://app.seeyoo.tv/'
      };
      
      // Neuen Controller erstellen mit erweiterten Optionen
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.streamUrl!),
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
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('VideoPlayer-Fehler: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_videoPlayerController != null) {
      _videoPlayerController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_videoPlayerController == null || !_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA1273B)),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: VideoPlayer(_videoPlayerController!),
    );
  }

  @override
  bool get wantKeepAlive => true; // Wichtig: Widget auch bei Inaktivität im Speicher halten
}
