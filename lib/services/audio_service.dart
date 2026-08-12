import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spicetify_v3/data/songs.dart';
import 'package:spicetify_v3/models/song_model.dart';
import 'package:spicetify_v3/services/playlist_service.dart';
import 'package:spicetify_v3/services/song_service.dart';

class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();

  List<SongModel> _playlist = List.from(songList);
  SongModel? _currentSong;
  bool _isPlaying = false;
  bool _isShuffled = false;
  bool _isRepeating = false;
  LoopMode _repeatMode = LoopMode.off;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 0.7;
  double _playbackSpeed = 1.0;
  List<SongModel> _recentlyPlayed = [];
  final List<SongModel> _queue = [];
  int _sleepTimerMinutes = 0;
  Timer? _sleepTimer;
  List<int> _shuffleIndices = [];
  int _currentIndex = 0;

  // Getters
  List<SongModel> get playlist => _playlist;
  SongModel? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isShuffled => _isShuffled;
  bool get isRepeating => _isRepeating;
  LoopMode get repeatMode => _repeatMode;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  double get playbackSpeed => _playbackSpeed;
  List<SongModel> get recentlyPlayed => _recentlyPlayed;
  List<SongModel> get queue => List.unmodifiable(_queue);
  int get sleepTimerMinutes => _sleepTimerMinutes;
  int get currentIndex => _currentIndex;

  Future<void> _init() async {
    _player.onPositionChanged.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.onDurationChanged.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _player.onPlayerComplete.listen((_) {
      _onSongComplete();
    });

    await SongService().init();
    _syncPlaylistFromLibrary();
    await _loadFavorites();
    await _loadRecentlyPlayed();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorite_ids') ?? [];
    for (var song in SongService().songs) {
      song.favorite = favoriteIds.contains(song.id);
    }
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = SongService().songs
        .where((s) => s.favorite)
        .map((s) => s.id)
        .toList();
    await prefs.setStringList('favorite_ids', favoriteIds);
  }

  Future<void> _loadRecentlyPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final recentlyPlayedJson = prefs.getStringList('recently_played') ?? [];
    _recentlyPlayed = recentlyPlayedJson
        .map((json) {
          try {
            final parts = json.split('|');
            if (parts.length >= 6) {
              return SongModel(
                id: parts[0],
                title: parts[1],
                artist: parts[2],
                audioPath: parts[3],
                imagePath: parts[4],
                duration: Duration(seconds: int.tryParse(parts[5]) ?? 0),
                isBuiltIn: parts.length >= 7 ? parts[6] == 'true' : true,
              );
            }
          } catch (_) {}
          return null;
        })
        .whereType<SongModel>()
        .toList();
  }

  Future<void> _saveRecentlyPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final recentlyPlayedJson = _recentlyPlayed
        .map((s) =>
            '${s.id}|${s.title}|${s.artist}|${s.audioPath}|${s.imagePath}|${s.duration.inSeconds}|${s.isBuiltIn}')
        .toList();
    await prefs.setStringList('recently_played', recentlyPlayedJson);
  }

  void _addToRecentlyPlayed(SongModel song) {
    _recentlyPlayed.removeWhere((s) => s.id == song.id);
    _recentlyPlayed.insert(0, song);
    if (_recentlyPlayed.length > 20) {
      _recentlyPlayed = _recentlyPlayed.sublist(0, 20);
    }
    _saveRecentlyPlayed();
    notifyListeners();
  }

  void _generateShuffleIndices() {
    _shuffleIndices = List.generate(_playlist.length, (i) => i);
    _shuffleIndices.shuffle();
    final currentIdx = _playlist.indexOf(_currentSong!);
    if (currentIdx >= 0) {
      _shuffleIndices.remove(currentIdx);
      _shuffleIndices.insert(0, currentIdx);
    }
  }

  Future<void> playSong(SongModel song) async {
    _currentSong = song;
    _currentIndex = _playlist.indexOf(song);
    if (_currentIndex < 0) {
      _currentIndex = 0;
    }
    _addToRecentlyPlayed(song);
    await _player.stop();
    Source source;
    if (song.isBuiltIn) {
      source = AssetSource(song.audioPath.replaceFirst('assets/', ''));
    } else if (kIsWeb) {
      final bytes = SongService().audioBytesFor(song.id);
      if (bytes != null && bytes.isNotEmpty) {
        source = BytesSource(bytes);
      } else {
        source = AssetSource(song.audioPath.replaceFirst('assets/', ''));
      }
    } else {
      source = DeviceFileSource(song.audioPath);
    }
    try {
      await _player.setSource(source);
      await _player.setVolume(_volume);
      await _player.setPlaybackRate(_playbackSpeed);
      await _player.resume();
      _isPlaying = true;
    } catch (_) {
      _isPlaying = false;
    }
    notifyListeners();
  }

  Future<void> play() async {
    if (_currentSong == null && _playlist.isNotEmpty) {
      await playSong(_playlist[0]);
      return;
    }
    if (_currentSong != null) {
      await _player.resume();
      _isPlaying = true;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> resume() async {
    if (_currentSong != null) {
      await _player.resume();
      _isPlaying = true;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> next() async {
    if (_playlist.isEmpty) return;
    if (_isShuffled) {
      if (_shuffleIndices.isEmpty) _generateShuffleIndices();
      final nextIdx = _shuffleIndices[(_currentIndex + 1) % _shuffleIndices.length];
      await playSong(_playlist[nextIdx]);
    } else {
      final nextIdx = (_currentIndex + 1) % _playlist.length;
      await playSong(_playlist[nextIdx]);
    }
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    if (_isShuffled) {
      if (_shuffleIndices.isEmpty) _generateShuffleIndices();
      final prevIdx = (_currentIndex - 1 + _shuffleIndices.length) % _shuffleIndices.length;
      await playSong(_playlist[_shuffleIndices[prevIdx]]);
    } else {
      final prevIdx = (_currentIndex - 1 + _playlist.length) % _playlist.length;
      await playSong(_playlist[prevIdx]);
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _position = position;
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    if (_isShuffled && _currentSong != null) {
      _generateShuffleIndices();
    }
    notifyListeners();
  }

  void cycleRepeatMode() {
    switch (_repeatMode) {
      case LoopMode.off:
        _repeatMode = LoopMode.one;
        break;
      case LoopMode.one:
        _repeatMode = LoopMode.all;
        break;
      case LoopMode.all:
        _repeatMode = LoopMode.off;
        break;
    }
    _isRepeating = _repeatMode != LoopMode.off;
    notifyListeners();
  }

  void _onSongComplete() async {
    switch (_repeatMode) {
      case LoopMode.one:
        if (_currentSong != null) {
          await seek(Duration.zero);
          await _player.resume();
        }
        break;
      case LoopMode.all:
      case LoopMode.off:
        if (_currentIndex < _playlist.length - 1 || _repeatMode == LoopMode.all) {
          await next();
        } else {
          _isPlaying = false;
          notifyListeners();
        }
        break;
    }
  }

  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    notifyListeners();
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _player.setPlaybackRate(_playbackSpeed);
    notifyListeners();
  }

  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _sleepTimerMinutes = minutes;
    if (minutes > 0) {
      _sleepTimer = Timer(Duration(minutes: minutes), () async {
        await pause();
        _sleepTimerMinutes = 0;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerMinutes = 0;
    notifyListeners();
  }

  Future<void> toggleFavorite(SongModel song) async {
    final libSong = SongService().getSongById(song.id);
    if (libSong == null) return;
    libSong.favorite = !libSong.favorite;
    if (_currentSong?.id == song.id) {
      _currentSong = libSong;
    }
    await _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(String songId) {
    return SongService().getSongById(songId)?.favorite ?? false;
  }

  void setPlaylist(List<SongModel> newPlaylist) {
    _playlist = newPlaylist;
    notifyListeners();
  }

  void _syncPlaylistFromLibrary() {
    _playlist = List.from(SongService().songs);
  }

  Future<SongModel> addUserSong({
    required String title,
    required String artist,
    String? pickedAudioPath,
    Uint8List? pickedAudioBytes,
    String? pickedCoverPath,
    Uint8List? pickedCoverBytes,
  }) async {
    final song = await SongService().addSong(
      title: title,
      artist: artist,
      pickedAudioPath: pickedAudioPath,
      pickedAudioBytes: pickedAudioBytes,
      pickedCoverPath: pickedCoverPath,
      pickedCoverBytes: pickedCoverBytes,
    );
    _syncPlaylistFromLibrary();
    notifyListeners();
    return song;
  }

  Future<void> updateUserSong({
    required String songId,
    required String title,
    required String artist,
    String? pickedCoverPath,
    Uint8List? pickedCoverBytes,
  }) async {
    await SongService().updateSong(
      songId: songId,
      title: title,
      artist: artist,
      pickedCoverPath: pickedCoverPath,
      pickedCoverBytes: pickedCoverBytes,
    );
    final updated = SongService().getSongById(songId);
    if (updated != null && _currentSong?.id == songId) {
      _currentSong = updated;
    }
    _syncPlaylistFromLibrary();
    notifyListeners();
  }

  Future<void> deleteUserSong(String songId) async {
    await SongService().deleteSong(songId);
    await PlaylistService().removeSongFromAllPlaylists(songId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList('favorite_ids') ?? [];
      await prefs.setStringList(
        'favorite_ids',
        favoriteIds.where((id) => id != songId).toList(),
      );
    } catch (_) {}
    if (_currentSong?.id == songId) {
      await _player.stop();
      _currentSong = null;
      _isPlaying = false;
      _position = Duration.zero;
    }
    _queue.removeWhere((s) => s.id == songId);
    _recentlyPlayed.removeWhere((s) => s.id == songId);
    _syncPlaylistFromLibrary();
    notifyListeners();
  }

  /// Play a song next (after current song)
  void playNext(SongModel song) {
    _queue.insert(0, song);
    notifyListeners();
  }

  /// Add a song to the end of the queue
  void addToQueue(SongModel song) {
    _queue.add(song);
    notifyListeners();
  }

  /// Remove a song from the queue
  void removeFromQueue(SongModel song) {
    _queue.removeWhere((s) => s.id == song.id);
    notifyListeners();
  }

  /// Clear the entire queue
  void clearQueue() {
    _queue.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}

enum LoopMode { off, one, all }
