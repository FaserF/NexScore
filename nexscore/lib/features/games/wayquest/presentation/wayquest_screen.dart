import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/wayquest_models.dart';
import '../providers/wayquest_provider.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';
import '../../../../core/providers/tts_provider.dart';
import '../../../../core/providers/audio_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../../../settings/provider/settings_provider.dart';

class WayQuestScreen extends ConsumerStatefulWidget {
  const WayQuestScreen({super.key});

  @override
  ConsumerState<WayQuestScreen> createState() => _WayQuestScreenState();
}

class _WayQuestScreenState extends ConsumerState<WayQuestScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = ref.read(settingsProvider);
      ref.read(ttsActiveProvider.notifier).setEnabled(settings.ttsEnabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wayQuestStateProvider);
    final l10n = AppLocalizations.of(context);

    ref.listen<WayQuestGameState>(wayQuestStateProvider, (previous, next) {
      if (next.playedCards.length > (previous?.playedCards.length ?? 0)) {
        // Play swipe sound
        ref.read(audioServiceProvider).play(SfxType.swipe);

        if (ref.read(ttsActiveProvider)) {
          final card = next.currentCard;
          if (card != null) {
            final ttsService = ref.read(ttsServiceProvider);
            final settings = ref.read(settingsProvider);
            final locale = settings.locale?.languageCode ?? 'en';
            ttsService.setLanguage(locale);
            ttsService.speak(card.text);
          }
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('game_wayquest')),
        leading: BackButton(onPressed: () => context.go('/games')),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(ttsActiveProvider) ? Icons.volume_up : Icons.volume_off,
              color: ref.watch(ttsActiveProvider)
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () {
              ref.read(ttsActiveProvider.notifier).toggle();
              final active = ref.read(ttsActiveProvider);
              if (!active) {
                ref.read(ttsServiceProvider).stop();
              }
            },
            tooltip: l10n.get('tts_toggle'),
          ),
          if (state.playedCards.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _confirmReset(context, ref, l10n),
            ),
        ],
      ),
      body: MultiplayerClientOverlay(
        child: state.playedCards.isEmpty
            ? _WayQuestSetup(l10n: l10n)
            : _WayQuestGame(l10n: l10n, state: state),
      ),
    );
  }

  void _confirmReset(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('game_reset')),
        content: Text(l10n.get('game_reset_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              ref.read(wayQuestStateProvider.notifier).resetGame();
              Navigator.pop(context);
            },
            child: Text(
              l10n.get('ok'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _WayQuestSetup extends ConsumerWidget {
  final AppLocalizations l10n;
  const _WayQuestSetup({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wayQuestStateProvider);
    final players = ref.watch(activePlayersProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.get('wayquest_categories'),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: WayQuestCategory.values.map((cat) {
                final isSelected = state.selectedCategories.contains(cat);
                return Card(
                  elevation: isSelected ? 4 : 1,
                  color: isSelected
                      ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => ref
                        .read(wayQuestStateProvider.notifier)
                        .toggleCategory(cat),
                    title: Text(
                      l10n.get('wayquest_cat_${cat.name}'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    leading: _getCategoryIcon(cat),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (_) => ref
                          .read(wayQuestStateProvider.notifier)
                          .toggleCategory(cat),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              ref
                  .read(wayQuestStateProvider.notifier)
                  .drawNextCard(players, l10n);
            },
            icon: const Icon(Icons.directions_car),
            label: Text(l10n.get('wayquest_start')),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCategoryIcon(WayQuestCategory cat) {
    switch (cat) {
      case WayQuestCategory.deepTalks:
        return const Icon(Icons.favorite, color: Colors.redAccent);
      case WayQuestCategory.wouldYouRather:
        return const Icon(Icons.compare_arrows, color: Colors.blueAccent);
      case WayQuestCategory.roadChallenges:
        return const Icon(Icons.map, color: Colors.green);
      case WayQuestCategory.hypotheticals:
        return const Icon(Icons.psychology, color: Colors.purpleAccent);
      case WayQuestCategory.storyStarters:
        return const Icon(Icons.auto_stories, color: Colors.orangeAccent);
    }
  }
}

class _WayQuestGame extends ConsumerWidget {
  final AppLocalizations l10n;
  final WayQuestGameState state;
  const _WayQuestGame({required this.l10n, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(activePlayersProvider);
    final currentCard = state.currentCard;

    if (currentCard == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () =>
          ref.read(wayQuestStateProvider.notifier).drawNextCard(players, l10n),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: Card(
                    key: ValueKey(
                      currentCard.id + state.playedCards.length.toString(),
                    ),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    color: _getCategoryColor(context, currentCard.category),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      width: double.infinity,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _getCategoryIcon(currentCard.category, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              l10n
                                  .get(
                                    'wayquest_cat_${currentCard.category.name}',
                                  )
                                  .toUpperCase(),
                              style: const TextStyle(
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              currentCard.text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Icon(
                              Icons.touch_app,
                              color: Colors.white54,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.get('wayquest_tap_continue'),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'QUEST ${state.playedCards.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(BuildContext context, WayQuestCategory cat) {
    switch (cat) {
      case WayQuestCategory.deepTalks:
        return Colors.red.shade400;
      case WayQuestCategory.wouldYouRather:
        return Colors.blue.shade400;
      case WayQuestCategory.roadChallenges:
        return Colors.green.shade400;
      case WayQuestCategory.hypotheticals:
        return Colors.purple.shade400;
      case WayQuestCategory.storyStarters:
        return Colors.orange.shade400;
    }
  }

  Widget _getCategoryIcon(WayQuestCategory cat, {double size = 24}) {
    IconData data;
    switch (cat) {
      case WayQuestCategory.deepTalks:
        data = Icons.favorite;
        break;
      case WayQuestCategory.wouldYouRather:
        data = Icons.compare_arrows;
        break;
      case WayQuestCategory.roadChallenges:
        data = Icons.map;
        break;
      case WayQuestCategory.hypotheticals:
        data = Icons.psychology;
        break;
      case WayQuestCategory.storyStarters:
        data = Icons.auto_stories;
        break;
    }
    return Icon(data, color: Colors.white, size: size);
  }
}
