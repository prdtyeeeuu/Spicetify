import 'dart:typed_data';

class SongModel {
  final String id;
  String title;
  String artist;
  final String audioPath;
  String imagePath;
  String? imageBase64;
  final Duration duration;

  /// `true` for songs bundled with the app (assets),
  /// `false` for songs added by the user.
  final bool isBuiltIn;
  bool favorite;

  /// Transient audio bytes for user-added songs (Web playback).
  Uint8List? audioBytes;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioPath,
    required this.imagePath,
    required this.duration,
    this.imageBase64,
    this.isBuiltIn = true,
    this.favorite = false,
    this.audioBytes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'audioPath': audioPath,
      'imagePath': imagePath,
      'imageBase64': imageBase64,
      'durationInSeconds': duration.inSeconds,
      'isBuiltIn': isBuiltIn,
      'favorite': favorite,
    };
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      audioPath: json['audioPath'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      imageBase64: json['imageBase64'] as String?,
      duration: Duration(seconds: json['durationInSeconds'] as int? ?? 0),
      isBuiltIn: json['isBuiltIn'] as bool? ?? true,
      favorite: json['favorite'] as bool? ?? false,
    );
  }

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? audioPath,
    String? imagePath,
    String? imageBase64,
    Duration? duration,
    bool? isBuiltIn,
    bool? favorite,
    Uint8List? audioBytes,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      audioPath: audioPath ?? this.audioPath,
      imagePath: imagePath ?? this.imagePath,
      imageBase64: imageBase64 ?? this.imageBase64,
      duration: duration ?? this.duration,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      favorite: favorite ?? this.favorite,
      audioBytes: audioBytes ?? this.audioBytes,
    );
  }
}
