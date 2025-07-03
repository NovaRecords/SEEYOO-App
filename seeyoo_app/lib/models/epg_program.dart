import 'package:intl/intl.dart';

class EpgProgram {
  final int id;
  final int start; // Unix-Timestamp in Sekunden
  final int end;   // Unix-Timestamp in Sekunden
  final String name;
  final bool inArchive;
  final bool downloadable;

  EpgProgram({
    required this.id,
    required this.start,
    required this.end,
    required this.name,
    this.inArchive = false,
    this.downloadable = false,
  });

  // Formatiert die Startzeit als Uhrzeit (HH:MM)
  String get startTimeFormatted {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(start * 1000);
    return DateFormat('HH:mm').format(dateTime);
  }

  // Formatiert die Endzeit als Uhrzeit (HH:MM)
  String get endTimeFormatted {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(end * 1000);
    return DateFormat('HH:mm').format(dateTime);
  }

  // Gibt die Dauer in Minuten zurück
  int get durationMinutes {
    return (end - start) ~/ 60;
  }

  // Gibt zurück, ob das Programm aktuell läuft
  bool get isCurrentlyRunning {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= start && now < end;
  }

  // Gibt zurück, ob das Programm in der Zukunft liegt
  bool get isUpcoming {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now < start;
  }

  factory EpgProgram.fromJson(Map<String, dynamic> json) {
    // Konvertierung von String zu int für numerische Felder
    int parseIntValue(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    return EpgProgram(
      id: parseIntValue(json['id']),
      start: parseIntValue(json['start']),
      end: parseIntValue(json['end']),
      name: json['name'] ?? '',
      inArchive: json['in_archive'] == 1 || json['in_archive'] == '1',
      downloadable: json['downloadable'] == 1 || json['downloadable'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start': start,
      'end': end,
      'name': name,
      'in_archive': inArchive ? 1 : 0,
      'downloadable': downloadable ? 1 : 0,
    };
  }
}
