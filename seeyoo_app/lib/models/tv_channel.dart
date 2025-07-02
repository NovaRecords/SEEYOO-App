class TvChannel {
  final int id;
  final String name;
  final String? genreId;
  final int? number;
  final String? url;
  final bool archive;
  final int? archiveRange;
  final bool pvr;
  final bool censored;
  final bool favorite;
  final String? logo;
  final bool monitoringStatus;
  
  // Zusätzliche Felder für die UI
  String? currentShow;
  String? currentShowTime;
  String? nextShow;
  bool isLive;

  TvChannel({
    required this.id,
    required this.name,
    this.genreId,
    this.number,
    this.url,
    this.archive = false,
    this.archiveRange,
    this.pvr = false,
    this.censored = false,
    this.favorite = false,
    this.logo,
    this.monitoringStatus = true,
    this.currentShow,
    this.currentShowTime,
    this.nextShow,
    this.isLive = true,
  });

  factory TvChannel.fromJson(Map<String, dynamic> json) {
    return TvChannel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'],
      genreId: json['genre_id'],
      number: json['number'],
      url: json['url'],
      archive: json['archive'] == 1,
      archiveRange: json['archive_range'],
      pvr: json['pvr'] == 1,
      censored: json['censored'] == 1,
      favorite: json['favorite'] == 1,
      logo: json['logo'],
      monitoringStatus: json['monitoring_status'] == 1,
      isLive: true,  // Standard: Kanal wird als Live markiert
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'genre_id': genreId,
      'number': number,
      'url': url,
      'archive': archive ? 1 : 0,
      'archive_range': archiveRange,
      'pvr': pvr ? 1 : 0,
      'censored': censored ? 1 : 0,
      'favorite': favorite ? 1 : 0,
      'logo': logo,
      'monitoring_status': monitoringStatus ? 1 : 0,
      'currentShow': currentShow,
      'currentShowTime': currentShowTime,
      'nextShow': nextShow,
      'isLive': isLive,
    };
  }
}
