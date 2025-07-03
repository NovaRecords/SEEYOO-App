import 'package:flutter/material.dart';

/// Modell für TV-Genres/Kategorien
class TvGenre {
  final String id;
  final String title;
  final String? alias;
  
  const TvGenre({
    required this.id, 
    required this.title,
    this.alias,
  });
  
  factory TvGenre.fromJson(Map<String, dynamic> json) {
    return TvGenre(
      id: json['id'].toString(),
      title: json['title'] ?? 'Unbekannte Kategorie',
      alias: json['alias'],
    );
  }
  
  @override
  String toString() => title;
}
