import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/widgets/glass_container.dart';
import '../../../../core/theme/widgets/animated_scale_button.dart';
import '../../../../core/providers/audio_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../models/sudoku_campaign_data.dart';
import '../models/sudoku_models.dart';
import '../providers/sudoku_provider.dart';

class SudokuCampaignScreen extends ConsumerStatefulWidget {
  const SudokuCampaignScreen({super.key});

  @override
  ConsumerState<SudokuCampaignScreen> createState() => _SudokuCampaignScreenState();
}

class _SudokuCampaignScreenState extends ConsumerState<SudokuCampaignScreen> {
  SudokuCampaignLevel? _selectedLevel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final completedLevelsAsync = ref.watch(completedCampaignLevelsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      appBar: AppBar(
        title: Text(
          l10n.get('game_sudoku_academy') ?? 'SUDOKU ACADEMY',
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: completedLevelsAsync.when(
        data: (completedSet) {
          return SafeArea(
            child: Stack(
              children: [
                // Connecting lines background + nodes
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 220),
                  itemCount: sudokuCampaignLevels.length,
                  itemBuilder: (context, index) {
                    final level = sudokuCampaignLevels[index];
                    final isCompleted = completedSet.contains(level.levelId);
                    
                    // Unlocked if first level or the previous one is completed
                    final isUnlocked = level.levelId == 1 || completedSet.contains(level.levelId - 1);
                    final isSelected = _selectedLevel?.levelId == level.levelId;

                    return Column(
                      children: [
                        // Vertical Connecting Line
                        if (index > 0)
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getNodeColor(sudokuCampaignLevels[index - 1], completedSet),
                                  _getNodeColor(level, completedSet),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        
                        // Node Card
                        AnimatedScaleButton(
                          onPressed: () {
                            ref.read(audioServiceProvider).play(SfxType.tap);
                            setState(() {
                              _selectedLevel = level;
                            });
                          },
                          child: GlassContainer(
                            borderRadius: 16,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.indigoAccent
                                  : (isCompleted
                                      ? Colors.greenAccent.withAlpha(100)
                                      : (isUnlocked
                                          ? Colors.blueAccent.withAlpha(60)
                                          : Colors.grey.withAlpha(40))),
                              width: isSelected ? 2 : 1.5,
                            ),
                            child: Row(
                              children: [
                                // Icon indicator
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? Colors.green.withAlpha(30)
                                        : (isUnlocked
                                            ? Colors.indigo.withAlpha(30)
                                            : Colors.grey.withAlpha(20)),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isCompleted
                                          ? Colors.greenAccent
                                          : (isUnlocked ? Colors.indigoAccent : Colors.grey),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    isCompleted
                                        ? Icons.check
                                        : (isUnlocked ? Icons.play_arrow : Icons.lock),
                                    color: isCompleted
                                        ? Colors.greenAccent
                                        : (isUnlocked ? Colors.indigoAccent : Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Level Title / Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'LEVEL ${level.levelId}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isUnlocked ? Colors.indigoAccent : Colors.grey,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        level.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isUnlocked ? Colors.white : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Extra Info Badge
                                if (isUnlocked)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getVariantBgColor(level.variant),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      level.variant.name.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // Bottom Panel Details Card
                if (_selectedLevel != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _buildDetailsCard(_selectedLevel!, completedSet, l10n),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading progress: $err')),
      ),
    );
  }

  Color _getNodeColor(SudokuCampaignLevel level, Set<int> completedSet) {
    if (completedSet.contains(level.levelId)) {
      return Colors.greenAccent;
    }
    final isUnlocked = level.levelId == 1 || completedSet.contains(level.levelId - 1);
    if (isUnlocked) {
      return Colors.indigoAccent;
    }
    return Colors.grey.withAlpha(100);
  }

  Color _getVariantBgColor(SudokuVariant variant) {
    return switch (variant) {
      SudokuVariant.standard => Colors.blueAccent,
      SudokuVariant.diagonal => Colors.pinkAccent,
      SudokuVariant.hyper => Colors.deepPurpleAccent,
      SudokuVariant.mini6x6 => Colors.teal,
    };
  }

  Widget _buildDetailsCard(
    SudokuCampaignLevel level,
    Set<int> completedSet,
    AppLocalizations l10n,
  ) {
    final isUnlocked = level.levelId == 1 || completedSet.contains(level.levelId - 1);
    final isCompleted = completedSet.contains(level.levelId);

    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      border: Border.all(color: Colors.indigoAccent.withAlpha(100), width: 1.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MISSION ${level.levelId}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigoAccent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    level.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => setState(() => _selectedLevel = null),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            level.description,
            style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 16),
          
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetaItem(Icons.grid_3x3, 'Variant', level.variant.name.toUpperCase()),
              _buildMetaItem(Icons.signal_cellular_alt, 'Difficulty', level.difficulty.name.toUpperCase()),
              _buildMetaItem(Icons.timer_outlined, 'Target', '${level.targetTimeSeconds}s'),
            ],
          ),
          const SizedBox(height: 20),
          
          // Action Button
          if (isUnlocked)
            FilledButton(
              onPressed: () {
                ref.read(audioServiceProvider).play(SfxType.success);
                // Initialize game state with campaign level
                ref.read(sudokuStateProvider.notifier).setupCampaignLevel(level.levelId);
                ref.read(activeGameIdProvider.notifier).state = 'sudoku';
                // Close campaign selector and enter game
                context.pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                isCompleted ? 'REPLAY MISSION' : 'START MISSION',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withAlpha(40)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, color: Colors.grey, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'LOCKED',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}
