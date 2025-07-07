import 'package:flutter/material.dart';
import 'package:seeyoo_app/models/tv_channel.dart';
import 'package:seeyoo_app/services/api_service.dart';
import 'package:seeyoo_app/services/storage_service.dart';
import 'package:seeyoo_app/widgets/channel_item.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  List<TvChannel> _favoriteChannels = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }
  
  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final channels = await _apiService.getFavoriteTvChannels();
      setState(() {
        _favoriteChannels = channels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Favoriten: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromFavorites(TvChannel channel) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _apiService.removeChannelFromFavorites(channel.id);
      
      if (success) {
        setState(() {
          _favoriteChannels.removeWhere((c) => c.id == channel.id);
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${channel.name} wurde aus den Favoriten entfernt')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Entfernen aus den Favoriten')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1E22),
      appBar: AppBar(
        title: const Text('Favoriten'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavorites,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFA1273B)),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadFavorites,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B4248),
                foregroundColor: Colors.white,
              ),
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }
    
    if (_favoriteChannels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_border,
              color: Color(0xFF8D9296),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Keine Favoriten vorhanden',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Markiere Sender als Favoriten, um sie hier zu sehen',
              style: TextStyle(color: Color(0xFF8D9296), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _favoriteChannels.length,
      itemBuilder: (context, index) {
        final channel = _favoriteChannels[index];
        return Dismissible(
          key: Key('favorite_${channel.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          onDismissed: (_) => _removeFromFavorites(channel),
          child: ChannelItem(
            channel: channel,
            isSelected: false,
            onTap: () {
              // Navigiere zum Kanal
              Navigator.pop(context, channel);
            },
          ),
        );
      },
    );
  }
}
