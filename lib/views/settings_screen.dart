import 'package:flutter/material.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLanguageChanged;

  const SettingsScreen({super.key, required this.onLanguageChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _sound;
  late bool _haptic;
  late String _language;

  @override
  void initState() {
    super.initState();
    _sound = GameStorage.getSoundEnabled();
    _haptic = GameStorage.getHapticEnabled();
    _language = GameStorage.getSelectedLanguage();
  }

  void _resetProgress() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardPeach,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.borderDark, width: 2.0),
          ),
          title: const Text('Reset Progress?', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark)),
          content: Text(
            'Are you sure you want to reset all progress for ${_language.toUpperCase()}?',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await GameStorage.resetLanguageProgress(_language);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Progress reset for ${_language.toUpperCase()}')),
                  );
                }
                widget.onLanguageChanged();
              },
              child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.cardPeachLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderDark, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.borderDark.withOpacity(0.12),
                            offset: const Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'SETTINGS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Language Selection
                  _buildSectionHeader('GAME LANGUAGE'),
                  Material(
                    color: AppColors.cardPeach,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderDark, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.borderDark.withOpacity(0.12),
                            offset: const Offset(0, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        children: LevelLoader.supportedLanguages.map((lang) {
                          final isSelected = lang == _language;
                          final name = LevelLoader.languageDisplayNames[lang] ?? lang;

                          return ListTile(
                            title: Text(
                              name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                                color: isSelected ? AppColors.terracotta : AppColors.textDark,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: AppColors.terracotta)
                                : null,
                            onTap: () async {
                              setState(() => _language = lang);
                              await GameStorage.setSelectedLanguage(lang);
                              widget.onLanguageChanged();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Audio & Haptics
                  _buildSectionHeader('AUDIO & FEEDBACK'),
                  Material(
                    color: AppColors.cardPeach,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderDark, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.borderDark.withOpacity(0.12),
                            offset: const Offset(0, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Sound Effects', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            secondary: const Icon(Icons.volume_up_rounded, color: AppColors.textDark),
                            value: _sound,
                            activeColor: AppColors.terracotta,
                            onChanged: (val) async {
                              setState(() => _sound = val);
                              await GameStorage.setSoundEnabled(val);
                            },
                          ),
                          const Divider(color: AppColors.borderSubtle, height: 1),
                          SwitchListTile(
                            title: const Text('Haptic Vibration', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            secondary: const Icon(Icons.vibration_rounded, color: AppColors.textDark),
                            value: _haptic,
                            activeColor: AppColors.terracotta,
                            onChanged: (val) async {
                              setState(() => _haptic = val);
                              await GameStorage.setHapticEnabled(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reset Progress
                  _buildSectionHeader('DATA MANAGEMENT'),
                  Material(
                    color: AppColors.cardPeach,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderDark, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.borderDark.withOpacity(0.12),
                            offset: const Offset(0, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.delete_forever_rounded, color: AppColors.terracotta),
                        title: const Text('Reset Current Language Progress', style: TextStyle(color: AppColors.terracotta, fontWeight: FontWeight.bold)),
                        onTap: _resetProgress,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // About
                  const Center(
                    child: Text(
                      'Word Tiles Flutter Edition\n9,550 Levels • 5 Languages',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: AppColors.terracotta,
        ),
      ),
    );
  }
}
