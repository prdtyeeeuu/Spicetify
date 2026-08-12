import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spicetify_v3/models/playlist_model.dart';
import 'package:spicetify_v3/models/song_model.dart';
import 'package:spicetify_v3/services/song_service.dart';

class PlaylistService extends ChangeNotifier {
  static final PlaylistService _instance = PlaylistService._internal();
  factory PlaylistService() => _instance;
  PlaylistService._internal();

  List<PlaylistModel> _playlists = [];
  List<PlaylistModel> _sortedPlaylists = [];

  List<PlaylistModel> get playlists => List.unmodifiable(_sortedPlaylists);

  PlaylistSortField _sortField = PlaylistSortField.name;
  bool _sortAscending = true;

  PlaylistSortField get sortField => _sortField;
  bool get sortAscending => _sortAscending;

  Future<void> init() async {
    await _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = prefs.getStringList('playlists') ?? [];
    _playlists = playlistsJson
        .map((jsonStr) {
          try {
            final map = jsonDecode(jsonStr) as Map<String, dynamic>;
            return PlaylistModel.fromJson(map);
          } catch (_) {
            return null;
          }
        })
        .whereType<PlaylistModel>()
        .toList();
    _applySort();
    notifyListeners();
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = _playlists.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('playlists', playlistsJson);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<PlaylistModel> createPlaylist({
    required String name,
    String description = '',
    String? imagePath,
    String? imageBase64,
  }) async {
    final playlist = PlaylistModel(
      id: _generateId(),
      name: name,
      description: description,
      // A cover is stored as custom only when the user actually picked one
      // (from the gallery). Otherwise the automatic cover system is used.
      imagePath: imagePath,
      imageBase64: imageBase64,
      hasCustomCover: imagePath != null || imageBase64 != null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _playlists.insert(0, playlist);
    _applySort();
    await _savePlaylists();
    notifyListeners();
    return playlist;
  }

  Future<void> updatePlaylist({
    required String playlistId,
    String? name,
    String? description,
    String? imagePath,
    String? imageBase64,
    bool clearImage = false,
  }) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index < 0) return;

    final playlist = _playlists[index];
    if (name != null) playlist.name = name;
    if (description != null) playlist.description = description;
    if (clearImage) {
      playlist.imagePath = null;
      playlist.imageBase64 = null;
      playlist.hasCustomCover = false;
    } else if (imagePath != null || imageBase64 != null) {
      playlist.imagePath = imagePath;
      playlist.imageBase64 = imageBase64;
      playlist.hasCustomCover = true;
    }
    playlist.updatedAt = DateTime.now();

    _playlists[index] = playlist;
    _applySort();
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    _applySort();
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> addSongsToPlaylist(String playlistId, List<String> songIds) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index < 0) return;

    final playlist = _playlists[index];
    for (final songId in songIds) {
      if (!playlist.songIds.contains(songId)) {
        playlist.songIds.add(songId);
      }
    }
    playlist.updatedAt = DateTime.now();
    _playlists[index] = playlist;
    _applySort();
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index < 0) return;

    final playlist = _playlists[index];
    playlist.songIds.remove(songId);
    playlist.updatedAt = DateTime.now();
    _playlists[index] = playlist;
    _applySort();
    await _savePlaylists();
    notifyListeners();
  }

  PlaylistModel? getPlaylistById(String playlistId) {
    try {
      return _playlists.firstWhere((p) => p.id == playlistId);
    } catch (_) {
      return null;
    }
  }

  /// Returns true if [songId] is already in the playlist with [playlistId].
  bool isSongInPlaylist(String playlistId, String songId) {
    final playlist = getPlaylistById(playlistId);
    return playlist != null && playlist.songIds.contains(songId);
  }

  List<SongModel> getSongsForPlaylist(String playlistId) {
    final playlist = getPlaylistById(playlistId);
    if (playlist == null) return [];
    return playlist.songIds
        .map((id) => SongService().getSongById(id))
        .whereType<SongModel>()
        .toList();
  }

  Duration calculateTotalDuration(String playlistId) {
    final songs = getSongsForPlaylist(playlistId);
    if (songs.isEmpty) return Duration.zero;
    return songs.fold<Duration>(Duration.zero, (sum, song) => sum + song.duration);
  }

  /// Removes [songId] from every playlist that contains it.
  Future<void> removeSongFromAllPlaylists(String songId) async {
    var changed = false;
    for (final playlist in _playlists) {
      if (playlist.songIds.contains(songId)) {
        playlist.songIds.remove(songId);
        playlist.updatedAt = DateTime.now();
        changed = true;
      }
    }
    if (!changed) return;
    _applySort();
    await _savePlaylists();
    notifyListeners();
  }

  void setSortBy(PlaylistSortField field, bool ascending) {
    _sortField = field;
    _sortAscending = ascending;
    _applySort();
    notifyListeners();
  }

  void _applySort() {
    _sortedPlaylists = List.from(_playlists);
    switch (_sortField) {
      case PlaylistSortField.name:
        _sortedPlaylists.sort((a, b) => a.name.compareTo(b.name));
        break;
      case PlaylistSortField.createdAt:
        _sortedPlaylists.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case PlaylistSortField.songCount:
        _sortedPlaylists.sort((a, b) => a.songCount.compareTo(b.songCount));
        break;
    }
    if (!_sortAscending) {
      _sortedPlaylists = _sortedPlaylists.reversed.toList();
    }
  }
}

enum PlaylistSortField { name, createdAt, songCount }