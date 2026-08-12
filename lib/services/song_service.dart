import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spicetify_v3/constants.dart';
import 'package:spicetify_v3/data/songs.dart';
import 'package:spicetify_v3/models/song_model.dart';

/// The single source of truth for the song library.
///
/// Combines the bundled songs ([songList], `isBuiltIn = true`) with the
/// user-added songs (`isBuiltIn = false`) persisted in SharedPreferences.
/// The combined list is always sorted alphabetically (A-Z) by title.
///
/// On non-Web platforms the user's MP3 and cover files are copied into the
/// app documents directory so they survive restarts. On Web the audio bytes
/// are kept in memory (and best-effort persisted when the storage quota
/// allows) while covers are persisted as base64.
class SongService extends ChangeNotifier {
  static final SongService _instance = SongService._internal();
  factory SongService() => _instance;
  SongService._internal();

  static const String _userSongsKey = 'user_songs';
  static const String _audioBytesPrefix = 'user_audio_';

  final List<SongModel> _userSongs = [];
  final Map<String, Uint8List> _audioBytes = {};
  List<SongModel> _songs = [];
  bool _initialized = false;

  List<SongModel> get songs => List.unmodifiable(_songs);

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _loadUserSongs();
  }

  SongModel? getSongById(String id) {
    try {
      return _songs.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Uint8List? audioBytesFor(String songId) => _audioBytes[songId];

  Future<void> _loadUserSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_userSongsKey) ?? [];
      for (final jsonStr in jsonList) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final song = SongModel.fromJson(map);
          if (song.isBuiltIn) continue;
          _userSongs.add(song);
        } catch (_) {}
      }
      if (kIsWeb) {
        for (final key in prefs.getKeys()) {
          if (key.startsWith(_audioBytesPrefix)) {
            final id = key.replaceFirst(_audioBytesPrefix, '');
            final value = prefs.getString(key);
            if (value != null && value.isNotEmpty) {
              try {
                _audioBytes[id] = base64Decode(value);
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}
    _rebuildSongs();
    notifyListeners();
  }

  Future<void> _saveUserSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _userSongs.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList(_userSongsKey, jsonList);
    } catch (_) {}
  }

  Future<void> _persistAudioBytes(String id, Uint8List bytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_audioBytesPrefix + id, base64Encode(bytes));
    } catch (_) {}
  }

  Future<Directory> _ensureDir(String sub) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}$sub');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<Duration> _probeDuration({
    required String audioPath,
    Uint8List? audioBytes,
  }) async {
    try {
      final player = AudioPlayer();
      if (audioPath.isNotEmpty && !kIsWeb) {
        await player.setSource(DeviceFileSource(audioPath));
      } else if (audioBytes != null && audioBytes.isNotEmpty && kIsWeb) {
        await player.setSource(BytesSource(audioBytes));
      } else {
        return Duration.zero;
      }
      final duration = await player.getDuration();
      await player.dispose();
      return duration ?? Duration.zero;
    } catch (_) {
      return Duration.zero;
    }
  }

  Future<SongModel> addSong({
    required String title,
    required String artist,
    String? pickedAudioPath,
    Uint8List? pickedAudioBytes,
    String? pickedCoverPath,
    Uint8List? pickedCoverBytes,
  }) async {
    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';

    String audioPath = '';
    if (!kIsWeb) {
      if (pickedAudioPath != null && pickedAudioPath.isNotEmpty) {
        final dir = await _ensureDir('songs');
        final dest = '${dir.path}${Platform.pathSeparator}$id.mp3';
        final copied = await File(pickedAudioPath).copy(dest);
        audioPath = copied.path;
      }
    } else {
      if (pickedAudioBytes != null && pickedAudioBytes.isNotEmpty) {
        _audioBytes[id] = pickedAudioBytes;
        await _persistAudioBytes(id, pickedAudioBytes);
      }
    }

    String imagePath = kDefaultSongCover;
    String? imageBase64;
    if (kIsWeb) {
      if (pickedCoverBytes != null && pickedCoverBytes.isNotEmpty) {
        imageBase64 = base64Encode(pickedCoverBytes);
        imagePath = '';
      }
    } else {
      if (pickedCoverPath != null && pickedCoverPath.isNotEmpty) {
        final dir = await _ensureDir('covers');
        final dest = '${dir.path}${Platform.pathSeparator}$id.jpg';
        final copied = await File(pickedCoverPath).copy(dest);
        imagePath = copied.path;
      }
    }

    final duration = await _probeDuration(
      audioPath: audioPath,
      audioBytes: pickedAudioBytes,
    );

    final song = SongModel(
      id: id,
      title: title,
      artist: artist,
      audioPath: audioPath,
      imagePath: imagePath,
      imageBase64: imageBase64,
      duration: duration,
      isBuiltIn: false,
    );
    _userSongs.add(song);
    _rebuildSongs();
    await _saveUserSongs();
    notifyListeners();
    return song;
  }

  Future<void> updateSong({
    required String songId,
    required String title,
    required String artist,
    String? pickedCoverPath,
    Uint8List? pickedCoverBytes,
  }) async {
    final index = _userSongs.indexWhere((s) => s.id == songId);
    if (index < 0) return;
    final song = _userSongs[index];
    song.title = title;
    song.artist = artist;

    if (kIsWeb) {
      if (pickedCoverBytes != null && pickedCoverBytes.isNotEmpty) {
        song.imageBase64 = base64Encode(pickedCoverBytes);
        song.imagePath = '';
      }
    } else {
      if (pickedCoverPath != null && pickedCoverPath.isNotEmpty) {
        final dir = await _ensureDir('covers');
        final dest = '${dir.path}${Platform.pathSeparator}$songId.jpg';
        final copied = await File(pickedCoverPath).copy(dest);
        song.imagePath = copied.path;
        song.imageBase64 = null;
      }
    }

    _rebuildSongs();
    await _saveUserSongs();
    notifyListeners();
  }

  Future<void> deleteSong(String songId) async {
    _userSongs.removeWhere((s) => s.id == songId);
    _audioBytes.remove(songId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_audioBytesPrefix + songId);
    } catch (_) {}
    _rebuildSongs();
    await _saveUserSongs();
    notifyListeners();
  }

  void _rebuildSongs() {
    _songs = [...songList, ..._userSongs];
    _sortSongs();
  }

  void _sortSongs() {
    _songs.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
  }
}
