import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/factquest_provider.dart';
import '../../../../core/i18n/app_localizations.dart';

/// FactQuest – a trivia game for car rides featuring interesting facts,
/// "Dumb Ways to Die" stories, and clickable source links.
class FactQuestScreen extends ConsumerStatefulWidget {
  const FactQuestScreen({super.key});

  @override
  ConsumerState<FactQuestScreen> createState() => _FactQuestScreenState();
}

class _FactQuestScreenState extends ConsumerState<FactQuestScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(factQuestStateProvider);

    // Listen for card changes to trigger animation
    ref.listen<FactQuestGameState>(factQuestStateProvider, (previous, next) {
      if (previous?.playedCards.length != next.playedCards.length) {
        _animController.reset();
        _animController.forward();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('game_factquest')),
        actions: [
          if (state.playedCards.isNotEmpty) ...[
            if (state.canUndo)
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: l10n.get('game_undo'),
                onPressed: () =>
                    ref.read(factQuestStateProvider.notifier).undo(),
              ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: l10n.get('factquest_categories'),
              onPressed: () => _showFilterModal(context, ref, l10n),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.get('game_reset'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.get('game_reset')),
                    content: Text(l10n.get('game_reset_confirm')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.get('cancel')),
                      ),
                      FilledButton(
                        onPressed: () {
                          ref.read(factQuestStateProvider.notifier).resetGame();
                          Navigator.pop(ctx);
                        },
                        child: Text(l10n.get('ok')),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () => context.go('/games'),
            tooltip: l10n.get('finishGame'),
          ),
        ],
      ),
      body: state.playedCards.isEmpty
          ? _FactQuestSetup(l10n: l10n)
          : FadeTransition(
              opacity: _fadeAnim,
              child: _FactQuestGame(l10n: l10n, state: state),
            ),
    );
  }

  void _showFilterModal(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.get('factquest_categories'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(factQuestStateProvider);
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: FactQuestCategory.values.map((cat) {
                      final isSelected = state.selectedCategories.contains(cat);
                      return FilterChip(
                        avatar: _getCategoryIcon(cat),
                        label: Text(l10n.get('factquest_cat_${cat.name}')),
                        selected: isSelected,
                        onSelected: (_) {
                          ref
                              .read(factQuestStateProvider.notifier)
                              .toggleCategory(cat);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.get('ok')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getCategoryIcon(FactQuestCategory cat) {
    switch (cat) {
      case FactQuestCategory.randomFacts:
        return const Icon(Icons.lightbulb_outline, size: 18);
      case FactQuestCategory.dumbWaysToDie:
        return const Icon(Icons.warning_amber, size: 18);
    }
  }
}

// ─── Setup Phase ──────────────────────────────────────────────────────────────

class _FactQuestSetup extends ConsumerWidget {
  final AppLocalizations l10n;
  const _FactQuestSetup({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(factQuestStateProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.get('factquest_categories'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: FactQuestCategory.values.map((cat) {
              final isSelected = state.selectedCategories.contains(cat);
              return FilterChip(
                avatar: _getCategoryIcon(cat),
                label: Text(l10n.get('factquest_cat_${cat.name}')),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(factQuestStateProvider.notifier).toggleCategory(cat);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                ref.read(factQuestStateProvider.notifier).drawNextCard();
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.get('factquest_start')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCategoryIcon(FactQuestCategory cat) {
    switch (cat) {
      case FactQuestCategory.randomFacts:
        return const Icon(Icons.lightbulb_outline, size: 18);
      case FactQuestCategory.dumbWaysToDie:
        return const Icon(Icons.warning_amber, size: 18);
    }
  }
}

// ─── Game Phase ───────────────────────────────────────────────────────────────

class _FactQuestGame extends ConsumerWidget {
  final AppLocalizations l10n;
  final FactQuestGameState state;
  const _FactQuestGame({required this.l10n, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCard = state.currentCard;
    if (currentCard == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final categoryColor = _getCategoryColor(context, currentCard.category);

    return GestureDetector(
      onTap: () => ref.read(factQuestStateProvider.notifier).drawNextCard(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (currentCard.emoji != null) ...[
                        Text(
                          currentCard.emoji!,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        l10n.get('factquest_cat_${currentCard.category.name}'),
                        style: TextStyle(
                          color: categoryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${state.playedCards.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Fact headline
            Text(
              l10n.get(currentCard.text),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),

            // Detailed explanation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: categoryColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                l10n.get(currentCard.explanation),
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Source link button
            OutlinedButton.icon(
              onPressed: () => _launchUrl(currentCard.sourceUrl),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(l10n.get('factquest_source')),
              style: OutlinedButton.styleFrom(
                foregroundColor: categoryColor,
                side: BorderSide(color: categoryColor.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(height: 32),

            // Tap to continue hint
            Center(
              child: Text(
                l10n.get('factquest_tap_continue'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _getCategoryColor(BuildContext context, FactQuestCategory cat) {
    switch (cat) {
      case FactQuestCategory.randomFacts:
        return Colors.teal;
      case FactQuestCategory.dumbWaysToDie:
        return Colors.deepOrange;
    }
  }
}
