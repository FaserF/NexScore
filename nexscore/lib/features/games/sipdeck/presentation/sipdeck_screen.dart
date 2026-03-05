import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/sipdeck_models.dart';
import '../providers/sipdeck_provider.dart';

class SipDeckScreen extends ConsumerStatefulWidget {
  const SipDeckScreen({super.key});

  @override
  ConsumerState<SipDeckScreen> createState() => _SipDeckScreenState();
}

class _SipDeckScreenState extends ConsumerState<SipDeckScreen> {
  bool _isBannerDismissed = false;

  @override
  Widget build(BuildContext context) {
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
          ? _buildStartScreen(context, ref, state, players, l10n)
          : _buildCardScreen(context, ref, state, players, l10n),
    );
  }

  Widget _buildStartScreen(
    BuildContext context,
    WidgetRef ref,
    SipDeckGameState state,
    List<Player> players,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        if (players.length == 2 && !_isBannerDismissed)
          MaterialBanner(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            content: Text(
              l10n.get('sipdeck_2player_warning'),
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
                onPressed: () => setState(() => _isBannerDismissed = true),
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
                const SizedBox(height: 24),

                // 2-Player Optimization Toggle (only show if 2 players)
                if (players.length == 2)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SwitchListTile(
                      title: Text(l10n.get('sipdeck_optimize_2players')),
                      subtitle: Text(
                        l10n.get('sipdeck_optimize_2players_desc'),
                      ),
                      value: state.filterMultiplayerOnly,
                      onChanged: (val) {
                        ref
                            .read(sipDeckStateProvider.notifier)
                            .toggleFilterMultiplayerOnly(val);
                      },
                    ),
                  ),

                if (players.length == 2) const SizedBox(height: 24),

                // Category Selection Section
                Text(
                  l10n.get('sipdeck_select_modes'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: SipDeckCategory.values.map((cat) {
                      final isSelected = state.selectedCategories.contains(cat);
                      final label = _labelForCategory(cat, l10n);
                      final icon = _iconForCategory(cat);
                      final color = _colorForCategory(cat);

                      return FilterChip(
                        label: Text(label),
                        avatar: Icon(icon, size: 16, color: color),
                        selected: isSelected,
                        onSelected: (_) {
                          ref
                              .read(sipDeckStateProvider.notifier)
                              .toggleCategory(cat);
                        },
                        selectedColor: color.withValues(alpha: 0.2),
                        checkmarkColor: color,
                        labelStyle: TextStyle(
                          color: isSelected ? color : null,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => ref
                      .read(sipDeckStateProvider.notifier)
                      .drawNextCard(players, l10n),
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
              ref
                  .read(sipDeckStateProvider.notifier)
                  .drawNextCard(players, l10n);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: GestureDetector(
            onTap: () => ref
                .read(sipDeckStateProvider.notifier)
                .drawNextCard(players, l10n),
            child: Container(
              width: double.infinity,
              color: currentCard.isVirus
                  ? Colors.deepOrange.shade800
                  : _colorForCategory(currentCard.category),
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
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
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  // Emoji Section
                  if (currentCard.emoji != null)
                    Text(
                      currentCard.emoji!,
                      style: const TextStyle(fontSize: 80),
                    )
                  else
                    Icon(
                      _iconForCategory(currentCard.category),
                      size: 80,
                      color: Colors.white24,
                    ),
                  const SizedBox(height: 32),
                  // Main Challenge Text
                  Text(
                    currentCard.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Explanation Section
                  if (currentCard.explanation != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentCard.explanation!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  if (currentCard.sips > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
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
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🦠', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text(
                            'ONGOING RULE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  // Interactive hint
                  Column(
                    children: [
                      const Icon(Icons.touch_app, color: Colors.white38),
                      const SizedBox(height: 8),
                      Text(
                        l10n.get('sipdeck_tap_continue'),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
