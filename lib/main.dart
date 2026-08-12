import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:spicetify_v3/services/audio_service.dart';
import 'package:spicetify_v3/services/playlist_service.dart';
import 'package:spicetify_v3/services/song_service.dart';
import 'package:spicetify_v3/services/theme_provider.dart';
import 'package:spicetify_v3/pages/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const SpicetifyApp());
}

class SpicetifyApp extends StatefulWidget {
  const SpicetifyApp({super.key});

  @override
  State<SpicetifyApp> createState() => _SpicetifyAppState();
}

class _SpicetifyAppState extends State<SpicetifyApp> {
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider();
    _themeProvider.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    _themeProvider.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioService>.value(
          value: AudioService(),
        ),
        ChangeNotifierProvider<ThemeProvider>.value(
          value: _themeProvider,
        ),
        ChangeNotifierProvider<PlaylistService>.value(
          value: PlaylistService(),
        ),
        ChangeNotifierProvider<SongService>.value(
          value: SongService(),
        ),
      ],
      child: MaterialApp(
        title: 'Spicetify',
        debugShowCheckedModeBanner: false,
        theme: _themeProvider.lightTheme,
        darkTheme: _themeProvider.darkTheme,
        themeMode: _themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }
}
