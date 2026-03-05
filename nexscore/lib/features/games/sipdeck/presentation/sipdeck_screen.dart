import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/sipdeck_models.dart';
import '../providers/sipdeck_provider.dart';

class SipDeckScreen extends ConsumerWidget {
  const SipDeckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sipDeckStateProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('sipdeck_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showCategoriesModal(context, ref, state, l10n),
          ),
        ],
      ),
      body: players.isEmpty
          ? Center(child: Text(l10n.get('sipdeck_no_players')))
          : state.playedCards.isEmpty
          ? _buildStartScreen(context, ref, players, l10n)
          : _buildCardScreen(context, ref, state, players, l10n),
    );
  }

  Widget _buildStartScreen(
    BuildContext context,
    WidgetRef ref,
    List<Player> players,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        if (players.length == 2)
          MaterialBanner(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            content: Text(
              l10n.getWith('error_msg', [
                'SipDeck is best enjoyed with 3 or more players!',
              ]), // Reusing a fallback or ideal text
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            leading: Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                child: Text(l10n.get('ok')),
              ),
            ],
          ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_bar, size: 80, color: Colors.pink),
                const SizedBox(height: 24),
                Text(
                  l10n.get('sipdeck_title'),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.getWith('sipdeck_players_ready', [
                    players.length.toString(),
                  ]),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.get('sipdeck_18_warning'),
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: () => ref
                      .read(sipDeckStateProvider.notifier)
                      .drawNextCard(players),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    l10n.get('sipdeck_start'),
                    style: const TextStyle(fontSize: 20),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.pink.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardScreen(
    BuildContext context,
    WidgetRef ref,
    SipDeckGameState state,
    List<Player> players,
    AppLocalizations l10n,
  ) {
    final currentCard = state.playedCards.last;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              ref.read(sipDeckStateProvider.notifier).drawNextCard(players);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: GestureDetector(
            onTap: () =>
                ref.read(sipDeckStateProvider.notifier).drawNextCard(players),
            child: Container(
              width: double.infinity,
              color: currentCard.isVirus
                  ? Colors.deepOrange.shade800
                  : _colorForCategory(currentCard.category),
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _labelForCategory(currentCard.category, l10n).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    currentCard.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 48),
                  if (currentCard.sips > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        l10n.getWith('sipdeck_sips', [
                          currentCard.sips.toString(),
                        ]),
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (currentCard.isVirus)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Text(
                        '🦠 ONGOING RULE',
                        style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    l10n.get('sipdeck_tap_continue'),
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _labelForCategory(SipDeckCategory cat, AppLocalizations l10n) {
    switch (cat) {
      case SipDeckCategory.warmUp:
        return l10n.get('sipdeck_cat_warmUp');
      case SipDeckCategory.wildCards:
        return l10n.get('sipdeck_cat_wildCards');
      case SipDeckCategory.flirty:
        return l10n.get('sipdeck_cat_flirty');
      case SipDeckCategory.barNight:
        return l10n.get('sipdeck_cat_barNight');
      case SipDeckCategory.laughs:
        return l10n.get('sipdeck_cat_laughs');
    }
  }

  Color _colorForCategory(SipDeckCategory cat) {
    switch (cat) {
      case SipDeckCategory.warmUp:
        return Colors.blue.shade700;
      case SipDeckCategory.wildCards:
        return Colors.purple.shade700;
      case SipDeckCategory.flirty:
        return Colors.pink.shade700;
      case SipDeckCategory.barNight:
        return Colors.teal.shade700;
      case SipDeckCategory.laughs:
        return Colors.green.shade700;
    }
  }

  IconData _iconForCategory(SipDeckCategory cat) {
    switch (cat) {
      case SipDeckCategory.warmUp:
        return Icons.wb_sunny_outlined;
      case SipDeckCategory.wildCards:
        return Icons.bolt;
      case SipDeckCategory.flirty:
        return Icons.favorite_outline;
      case SipDeckCategory.barNight:
        return Icons.sports_bar_outlined;
      case SipDeckCategory.laughs:
        return Icons.sentiment_very_satisfied_outlined;
    }
  }

  void _showCategoriesModal(
    BuildContext context,
    WidgetRef ref,
    SipDeckGameState state,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.get('sipdeck_categories'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.get('sipdeck_categories'), // Use a desc if available
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...SipDeckCategory.values.map((cat) {
              final isSelected = state.selectedCategories.contains(cat);
              return CheckboxListTile(
                title: Text(_labelForCategory(cat, l10n)),
                secondary: Icon(
                  _iconForCategory(cat),
                  color: _colorForCategory(cat),
                ),
                value: isSelected,
                onChanged: (_) {
                  ref.read(sipDeckStateProvider.notifier).toggleCategory(cat);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        );
      },
    );
  }
}
