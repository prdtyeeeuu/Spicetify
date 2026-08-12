import 'dart:convert';
import 'dart:typed_data';
import 'package:spicetify_v3/constants.dart';

class PlaylistModel {
  final String id;
  String name;
  String description;
  String? imagePath; // Local file path (Android) or asset path
  String? imageBase64; // Base64-encoded image bytes (Web)
  bool hasCustomCover; // True when the user picked a custom cover
  List<String> songIds;
  final DateTime createdAt;
  DateTime updatedAt;

  PlaylistModel({
    required this.id,
    required this.name,
    this.description = '',
    this.imagePath,
    this.imageBase64,
    this.hasCustomCover = false,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : songIds = songIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Path of the user-chosen custom cover, or `null` when no custom cover
  /// was picked (the automatic cover system is then used).
  String? get customCoverPath => hasCustomCover ? imagePath : null;

  /// Get the raw image bytes decoded from [imageBase64].
  Uint8List? get imageBytes {
    if (imageBase64 == null || imageBase64!.isEmpty) return null;
    try {
      return base64Decode(imageBase64!);
    } catch (_) {
      return null;
    }
  }

  PlaylistModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    String? imageBase64,
    bool? hasCustomCover,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      imageBase64: imageBase64 ?? this.imageBase64,
      hasCustomCover: hasCustomCover ?? this.hasCustomCover,
      songIds: songIds ?? List.from(this.songIds),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'imageBase64': imageBase64,
      'hasCustomCover': hasCustomCover,
      'songIds': songIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    // Migrate playlists saved before the automatic cover system: the baked-in
    // default cover was not a real custom cover, so clear it so the automatic
    // cover rules take over.
    var imagePath = json['imagePath'] as String?;
    if (imagePath == kDefaultPlaylistCover) {
      imagePath = null;
    }
    final imageBase64 = json['imageBase64'] as String?;

    // Legacy playlists have no hasCustomCover flag; any stored cover that is
    // not the default is considered a user-chosen custom cover.
    final hasCustomCover = json['hasCustomCover'] as bool? ??
        ((imageBase64 != null && imageBase64.isNotEmpty) ||
            (imagePath != null && imagePath.isNotEmpty));

    return PlaylistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      imagePath: imagePath,
      imageBase64: imageBase64,
      hasCustomCover: hasCustomCover,
      songIds: (json['songIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  int get songCount => songIds.length;

  Duration get totalDuration => Duration.zero;
}