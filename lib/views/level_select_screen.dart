import 'package:flutter/material.dart';
import '../services/game_storage.dart';
import '../services/level_loader.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  final String language;

  const LevelSelectScreen({super.key, required this.language});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  List<int> _levelIds = [];
  bool _isLoading = true;
  int _maxUnlockedIndex = 0;
  Map<int, int> _starsMap = {};

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    setState(() => _isLoading = true);
    _levelIds = await LevelLoader.loadLevelList(widget.language);
    _maxUnlockedIndex = GameStorage.getMaxUnlockedLevelIndex(widget.language);
    _starsMap = GameStorage.getLevelStars(widget.language);

    setState(() => _isLoading = false);

    // Scroll to currently unlocked level
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _maxUnlockedIndex > 10) {
        final row = _maxUnlockedIndex ~/ 5;
        final targetOffset = row * 84.0;
        _scrollController.jumpTo(targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent));
      }
    });
  }

  void _openLevel(int index, int levelId) {
    if (index > _maxUnlockedIndex) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          language: widget.language,
          levelIndex: index,
        ),
      ),
    ).then((_) => _loadLevels());
  }

  @override
  Widget build(BuildContext context) {
    final langName = LevelLoader.languageDisplayNames[widget.language] ?? widget.language;

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SELECT LEVEL',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '$langName • ${_levelIds.length} Levels',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  // Coins Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.cardPeachLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderDark, width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.borderDark.withOpacity(0.12),
                          offset: const Offset(0, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          '${GameStorage.getCoins()}',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Level Grid (Matching Reference Screenshot Card Style)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.84,
                      ),
                      itemCount: _levelIds.length,
                      itemBuilder: (context, index) {
                        final levelId = _levelIds[index];
                        final isUnlocked = index <= _maxUnlockedIndex;
                        final isCurrent = index == _maxUnlockedIndex;
                        final stars = _starsMap[levelId] ?? 0;

                        return _LevelCard(
                          levelNumber: index + 1,
                          isUnlocked: isUnlocked,
                          isCurrent: isCurrent,
                          stars: stars,
                          onTap: () => _openLevel(index, levelId),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int levelNumber;
  final bool isUnlocked;
  final bool isCurrent;
  final int stars;
  final VoidCallback onTap;

  const _LevelCard({
    required this.levelNumber,
    required this.isUnlocked,
    required this.isCurrent,
    required this.stars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isCurrent
        ? AppColors.terracotta
        : (isUnlocked ? AppColors.cardPeach : AppColors.cardPeachLight.withOpacity(0.5));

    final textColor = isCurrent ? Colors.white : AppColors.textDark;

    return InkWell(
      onTap: isUnlocked ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderDark, // Crisp 2px dark border
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.borderDark.withOpacity(isCurrent ? 0.25 : 0.12),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isUnlocked)
              const Icon(Icons.lock_rounded, size: 20, color: AppColors.textMuted)
            else ...[
              Text(
                '$levelNumber',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final hasStar = isCurrent ? false : (i < (stars > 0 ? stars : 3));
                  return Icon(
                    Icons.star_rounded,
                    size: 11,
                    color: hasStar ? AppColors.goldAccent : AppColors.textDark.withOpacity(0.2),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
