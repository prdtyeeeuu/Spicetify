import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spicetify_v3/pages/about_page.dart';
import 'package:spicetify_v3/services/audio_service.dart';
import 'package:spicetify_v3/services/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Consumer2<AudioService, ThemeProvider>(
      builder: (context, audioService, themeProvider, _) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8A2BE2),
                            Color(0xFF6A0DAD),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              // Appearance Section
              _buildSectionTitle(context, 'Appearance'),
              _buildCard(
                context,
                children: [
                  _buildSettingRow(
                    context,
                    icon: themeProvider.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    title: 'Theme',
                    subtitle: themeProvider.isDarkMode
                        ? 'Dark Mode'
                        : 'Light Mode',
                    trailing: Switch.adaptive(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Playback Section
              _buildSectionTitle(context, 'Playback'),
              _buildCard(
                context,
                children: [
                  _buildSettingRow(
                    context,
                    icon: Icons.volume_up_rounded,
                    title: 'Volume',
                    subtitle: '${(audioService.volume * 100).round()}%',
                    trailing: SizedBox(
                      width: 160,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: cs.primary,
                          inactiveTrackColor:
                              cs.onSurface.withValues(alpha: 0.15),
                          thumbColor: cs.primary,
                        ),
                        child: Slider(
                          value: audioService.volume,
                          onChanged: (val) => audioService.setVolume(val),
                        ),
                      ),
                    ),
                  ),
                  _buildDivider(context),
                  _buildSettingRow(
                    context,
                    icon: Icons.speed_rounded,
                    title: 'Playback Speed',
                    subtitle: '${audioService.playbackSpeed}x',
                    trailing: _buildChipSelector(
                      context,
                      values: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
                      selected: audioService.playbackSpeed,
                      onSelected: (val) =>
                          audioService.setPlaybackSpeed(val),
                      format: (val) => '${val}x',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sleep Timer Section
              _buildSectionTitle(context, 'Sleep Timer'),
              _buildCard(
                context,
                children: [
                  _buildSettingRow(
                    context,
                    icon: audioService.sleepTimerMinutes > 0
                        ? Icons.timer_off_outlined
                        : Icons.timer_outlined,
                    title: 'Sleep Timer',
                    subtitle: audioService.sleepTimerMinutes > 0
                        ? '${audioService.sleepTimerMinutes} min remaining'
                        : 'Off',
                    trailing: _buildChipSelector(
                      context,
                      values: [0, 5, 10, 15, 30, 45, 60],
                      selected: audioService.sleepTimerMinutes,
                      onSelected: (val) =>
                          audioService.setSleepTimer(val),
                      format: (val) =>
                          val == 0 ? 'Off' : '${val}m',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // About Section
              _buildSectionTitle(context, 'About'),
              _buildCard(
                context,
                children: [
                  // Navigate to About page
                  GestureDetector(
                    onTap: () => _openAboutPage(context),
                    behavior: HitTestBehavior.opaque,
                    child: _buildSettingRow(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'About',
                      subtitle: 'About Spicetify & developers',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  _buildDivider(context),
                  // Logo header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/icons/logo.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Spicetify',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Version 1.0.0',
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'v1.0',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDivider(context),
                  _buildSettingRow(
                    context,
                    icon: Icons.code_rounded,
                    title: 'Developer',
                    subtitle: 'Built with Flutter & ❤️',
                    trailing: Icon(
                      Icons.favorite,
                      size: 18,
                      color: cs.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  _buildDivider(context),
                  _buildSettingRow(
                    context,
                    icon: Icons.library_music_rounded,
                    title: 'Total Songs',
                    subtitle: '${audioService.playlist.length} songs loaded',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${audioService.playlist.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAboutPage(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AboutPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cs.onSurface.withValues(alpha: 0.4),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Widget? leading,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          leading ?? Icon(
            icon,
            size: 20,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildChipSelector(
    BuildContext context, {
    required List<dynamic> values,
    required dynamic selected,
    required Function(dynamic) onSelected,
    required String Function(dynamic) format,
  }) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 200,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 4,
        runSpacing: 4,
        children: values.map((val) {
          final isSelected = val == selected;
          return GestureDetector(
            onTap: () => onSelected(val),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                format(val),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).dividerColor,
    );
  }
}
