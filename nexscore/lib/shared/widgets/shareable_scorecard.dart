import 'package:flutter/material.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/widgets/glass_container.dart';

class ShareableScorecard extends StatelessWidget {
  final String gameName;
  final String winnerName;
  final String? winnerEmoji;
  final Color winnerColor;
  final List<PlayerScore> finalScores;

  const ShareableScorecard({
    super.key,
    required this.gameName,
    required this.winnerName,
    this.winnerEmoji,
    required this.winnerColor,
    required this.finalScores,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final theme = Theme.of(context);

    final winnerLabel = l10n?.get('winner') ?? 'Winner';

    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header / Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.leaderboard,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'NexScore',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Winner Section
          GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: 24,
            child: Column(
              children: [
                Text(
                  winnerLabel.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: winnerColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: winnerColor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: winnerEmoji != null
                        ? Text(
                            winnerEmoji!,
                            style: const TextStyle(fontSize: 40),
                          )
                        : Text(
                            winnerName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  winnerName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  gameName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Ranking Section
          Column(
            children: finalScores.take(3).map((ps) {
              final isWinner = ps.name == winnerName;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Text(
                      '#${finalScores.indexOf(ps) + 1}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isWinner ? theme.colorScheme.primary : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(ps.name, style: theme.textTheme.titleMedium),
                    ),
                    Text(
                      ps.score.toString(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 48),

          // Call to Action / Website
          Text(
            'nexscore.app',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerScore {
  final String name;
  final int score;
  const PlayerScore(this.name, this.score);
}
