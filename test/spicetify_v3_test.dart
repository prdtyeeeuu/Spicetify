import 'package:flutter_test/flutter_test.dart';
import 'package:spicetify_v3/models/song_model.dart';

void main() {
  test('SongModel creates correctly', () {
    final song = SongModel(
      id: '1',
      title: 'Test Song',
      artist: 'Test Artist',
      audioPath: 'assets/audio/test.mp3',
      imagePath: 'assets/images/test.jpg',
      duration: const Duration(minutes: 3, seconds: 30),
    );

    expect(song.id, '1');
    expect(song.title, 'Test Song');
    expect(song.artist, 'Test Artist');
    expect(song.duration.inSeconds, 210);
    expect(song.favorite, false);
  });

  test('SongModel toJson/fromJson works', () {
    final song = SongModel(
      id: '2',
      title: 'Another Song',
      artist: 'Another Artist',
      audioPath: 'assets/audio/another.mp3',
      imagePath: 'assets/images/another.jpg',
      duration: const Duration(minutes: 4, seconds: 15),
      favorite: true,
    );

    final json = song.toJson();
    final restored = SongModel.fromJson(json);

    expect(restored.id, song.id);
    expect(restored.title, song.title);
    expect(restored.artist, song.artist);
    expect(restored.audioPath, song.audioPath);
    expect(restored.imagePath, song.imagePath);
    expect(restored.duration.inSeconds, song.duration.inSeconds);
    expect(restored.favorite, song.favorite);
  });
}
