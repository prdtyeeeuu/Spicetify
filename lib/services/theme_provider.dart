import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _darkModeKey = 'dark_mode';

  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }

  static const Color _primaryDark = Color(0xFF9C4DFF);
  static const Color _primaryLight = Color(0xFF8A2BE2);
  static const Color _bgDark = Color(0xFF0D0A16);
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _cardDark = Color(0xFF1A1730);
  static const Color _cardLight = Color(0xFFF5F5FA);
  static const Color _textDark = Colors.white;
  static const Color _textLight = Color(0xFF1A1A2E);
  static const Color _textSecondaryDark = Color(0xFFB0B0C3);
  static const Color _textSecondaryLight = Color(0xFF666666);

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _primaryDark,
      scaffoldBackgroundColor: _bgDark,
      cardColor: _cardDark,
      dividerColor: Colors.white.withValues(alpha: 0.08),
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.dark(
        primary: _primaryDark,
        secondary: _primaryDark,
        surface: _cardDark,
        onSurface: _textDark,
        onSurfaceVariant: _textSecondaryDark,
        error: const Color(0xFFCF6679),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: _textDark,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: _textDark,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: _textDark,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: _textDark,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: _textDark),
        bodyMedium: TextStyle(color: _textSecondaryDark),
        bodySmall: TextStyle(color: _textSecondaryDark),
        labelSmall: TextStyle(color: _textSecondaryDark),
      ),
      iconTheme: const IconThemeData(
        color: _textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _textDark,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _bgDark,
        selectedItemColor: _primaryDark,
        unselectedItemColor: _textSecondaryDark.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        activeTrackColor: _primaryDark,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
        thumbColor: _primaryDark,
        overlayColor: _primaryDark.withValues(alpha: 0.2),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primaryDark;
          return Colors.white.withValues(alpha: 0.3);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryDark.withValues(alpha: 0.5);
          }
          return Colors.white.withValues(alpha: 0.1);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _cardDark,
        contentTextStyle: const TextStyle(color: _textDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardDark,
        hintStyle: const TextStyle(color: _textSecondaryDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        selectedColor: _primaryDark,
        labelStyle: const TextStyle(color: _textDark, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _primaryLight,
      scaffoldBackgroundColor: _bgLight,
      cardColor: _cardLight,
      dividerColor: Colors.black.withValues(alpha: 0.06),
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.light(
        primary: _primaryLight,
        secondary: _primaryLight,
        surface: _cardLight,
        onSurface: _textLight,
        onSurfaceVariant: _textSecondaryLight,
        error: const Color(0xFFB00020),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: _textLight,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: _textLight,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: _textLight,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: _textLight,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: _textLight),
        bodyMedium: TextStyle(color: _textSecondaryLight),
        bodySmall: TextStyle(color: _textSecondaryLight),
        labelSmall: TextStyle(color: _textSecondaryLight),
      ),
      iconTheme: const IconThemeData(
        color: _textLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _textLight,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _bgLight,
        selectedItemColor: _primaryLight,
        unselectedItemColor: _textSecondaryLight.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _cardLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        activeTrackColor: _primaryLight,
        inactiveTrackColor: Colors.black.withValues(alpha: 0.1),
        thumbColor: _primaryLight,
        overlayColor: _primaryLight.withValues(alpha: 0.2),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primaryLight;
          return Colors.black.withValues(alpha: 0.2);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryLight.withValues(alpha: 0.5);
          }
          return Colors.black.withValues(alpha: 0.08);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _cardLight,
        contentTextStyle: const TextStyle(color: _textLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardLight,
        hintStyle: const TextStyle(color: _textSecondaryLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.black.withValues(alpha: 0.06),
        selectedColor: _primaryLight,
        labelStyle: const TextStyle(color: _textLight, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
