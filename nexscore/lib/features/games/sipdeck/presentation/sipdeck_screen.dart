import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/drink_intensity.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/sipdeck_models.dart';
import '../providers/sipdeck_provider.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';
import '../../../../shared/widgets/swipeable_card.dart';

class SipDeckScreen extends ConsumerStatefulWidget {
  const SipDeckScreen({super.key});

  @override
  ConsumerState<SipDeckScreen> createState() => _SipDeckScreenState();
}

class _SipDeckScreenState extends ConsumerState<SipDeckScreen> {
  bool _isBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    // Initial auto-toggle based on player count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final players = ref.read(activePlayersProvider);
      ref
          .read(sipDeckStateProvider.notifier)
          .toggleFilterMultiplayerOnly(players.length == 2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sipDeckStateProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    // Auto-toggle optimization based on player count
    ref.listen<List<Player>>(activePlayersProvider, (previous, next) {
      if (next.length == 2 && previous?.length != 2) {
        ref
            .read(sipDeckStateProvider.notifier)
            .toggleFilterMultiplayerOnly(true);
      } else if (next.length != 2 && previous?.length == 2) {
        ref
            .read(sipDeckStateProvider.notifier)
            .toggleFilterMultiplayerOnly(false);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('sipdeck_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              launchUrl(
                Uri.parse(
                  'https://faserf.github.io/NexScore/docs/user_guide/games/#sipdeck-18',
                ),
              );
            },
            tooltip: l10n.get('nav_help'),
          ),
          IconButton(
            icon: const Icon(Icons.local_drink),
            onPressed: () => _showSipsModal(context, ref, state, players, l10n),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showCategoriesModal(context, ref, state, l10n),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmReset(context, ref, l10n),
          ),
        ],
      ),
      body: MultiplayerClientOverlay(
        child: players.isEmpty
            ? Center(child: Text(l10n.get('sipdeck_no_players')))
            : state.playedCards.isEmpty
            ? _buildStartScreen(context, ref, state, players, l10n)
            : _buildCardScreen(context, ref, state, players, l10n),
      ),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
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

                  // Drink Intensity Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.get('drink_intensity_title'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.get('drink_intensity_subtitle'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SegmentedButton<DrinkIntensity>(
                      segments: [
                        ButtonSegment(
                          value: DrinkIntensity.chill,
                          label: Text(
                            l10n.get('drink_intensity_chill'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        ButtonSegment(
                          value: DrinkIntensity.normal,
                          label: Text(
                            l10n.get('drink_intensity_normal'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        ButtonSegment(
                          value: DrinkIntensity.extreme,
                          label: Text(
                            l10n.get('drink_intensity_extreme'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        ButtonSegment(
                          value: DrinkIntensity.custom,
                          label: Text(
                            l10n.get('drink_intensity_custom'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                      selected: {state.intensity},
                      onSelectionChanged: (val) {
                        ref
                            .read(sipDeckStateProvider.notifier)
                            .toggleIntensity(val.first);
                      },
                    ),
                  ),
                  if (state.intensity == DrinkIntensity.custom) ...[
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        children: [
                          Text(
                            l10n.getWith('drink_intensity_custom_slider', [
                              state.customIntensityMultiplier.toStringAsFixed(
                                1,
                              ),
                            ]),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Slider(
                            value: state.customIntensityMultiplier,
                            min: 0.1,
                            max: 10.0,
                            divisions: 99,
                            label: state.customIntensityMultiplier
                                .toStringAsFixed(1),
                            onChanged: (val) {
                              ref
                                  .read(sipDeckStateProvider.notifier)
                                  .setCustomIntensity(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Category Selection Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.get('sipdeck_select_modes'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.help_outline, size: 20),
                        onPressed: () => _showCategoryHelpDialog(context, l10n),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: SipDeckCategory.values.map((cat) {
                        final isSelected = state.selectedCategories.contains(
                          cat,
                        );
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
                  const SizedBox(height: 24),

                  // Task Filters Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.get('sipdeck_filters'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: SipDeckTaskTag.values.map((tag) {
                        final isDisabled = state.disabledTags.contains(tag);
                        final label = _labelForTag(tag, l10n);
                        final icon = _iconForTag(tag);
                        final color = _colorForTag(tag);

                        return FilterChip(
                          label: Text(label),
                          avatar: Icon(icon, size: 16, color: color),
                          selected: !isDisabled,
                          onSelected: (_) {
                            ref
                                .read(sipDeckStateProvider.notifier)
                                .toggleTag(tag);
                          },
                          selectedColor: color.withValues(alpha: 0.2),
                          checkmarkColor: color,
                          labelStyle: TextStyle(
                            color: !isDisabled ? color : null,
                            fontWeight: !isDisabled
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
          child: SwipeableCard(
            cardKey: ValueKey(
              currentCard.id + state.playedCards.length.toString(),
            ),
            onSwipe: () {
              ref
                  .read(sipDeckStateProvider.notifier)
                  .drawNextCard(players, l10n);
            },
            child: Container(
              width: double.infinity,
              color: currentCard.isVirus
                  ? Colors.deepOrange.shade800
                  : _colorForCategory(currentCard.category),
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _labelForCategory(
                        currentCard.category,
                        l10n,
                      ).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 48),
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
                    const SizedBox(height: 48),
                    _buildInlineSipCounter(state, players),
                    const SizedBox(height: 24),
                    // Action Area
                    if (currentCard.sips > 0)
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (currentCard.targetType ==
                                      SipTargetType.single ||
                                  currentCard.targetType ==
                                      SipTargetType.everyone)
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      HapticFeedback.heavyImpact();
                                      ref
                                          .read(sipDeckStateProvider.notifier)
                                          .completeCard(false);
                                      ref
                                          .read(sipDeckStateProvider.notifier)
                                          .drawNextCard(players, l10n);
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: _colorForCategory(
                                        currentCard.category,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: Text(
                                      currentCard.targetType ==
                                              SipTargetType.everyone
                                          ? l10n.get('game_drink_everyone')
                                          : l10n.getWith('game_drink_single', [
                                              players
                                                  .firstWhere(
                                                    (p) =>
                                                        p.id ==
                                                        currentCard
                                                            .targetIds
                                                            .first,
                                                    orElse: () => players.first,
                                                  )
                                                  .name,
                                            ]),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              if (currentCard.targetType ==
                                  SipTargetType.dual) ...[
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      ref
                                          .read(sipDeckStateProvider.notifier)
                                          .incrementSips(
                                            currentCard.targetIds.first,
                                            currentCard.sips,
                                          );
                                      ref
                                          .read(sipDeckStateProvider.notifier)
                                          .drawNextCard(players, l10n);
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black87,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: Text(
                                      players
                                          .firstWhere(
                                            (p) =>
                                                p.id ==
                                                currentCard.targetIds.first,
                                          )
                                          .name,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      ref
                                          .read(sipDeckStateProvider.notifier)
                                          .incrementSips(
                                            currentCard.targetIds.last,
                                            currentCard.sips,
                                          );
                                      ref
                                          .read(sipDeckStateProvider.notifier)
                                          .drawNextCard(players, l10n);
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black87,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: Text(
                                      players
                                          .firstWhere(
                                            (p) =>
                                                p.id ==
                                                currentCard.targetIds.last,
                                          )
                                          .name,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                              if (currentCard.targetType ==
                                  SipTargetType.manual)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      ref
                                          .read(sipDeckStateProvider.notifier)
                                          .drawNextCard(players, l10n);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white54,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: Text(
                                      l10n.get('sipdeck_tap_continue'),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(sipDeckStateProvider.notifier)
                                  .completeCard(true);
                              ref
                                  .read(sipDeckStateProvider.notifier)
                                  .drawNextCard(players, l10n);
                            },
                            icon: const Icon(Icons.skip_next, size: 20),
                            label: Text(l10n.get('game_skip')),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
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
      ),
    );
  }

  Widget _buildInlineSipCounter(SipDeckGameState state, List<Player> players) {
    if (players.every((p) => (state.playerSips[p.id] ?? 0) == 0)) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: players.map((p) {
          final sips = state.playerSips[p.id] ?? 0;
          if (sips == 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: Color(
                      int.parse(p.avatarColor.replaceFirst('#', '0xff')),
                    ),
                    child: Text(
                      p.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$sips',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _labelForTag(SipDeckTaskTag tag, AppLocalizations l10n) {
    switch (tag) {
      case SipDeckTaskTag.dare:
        return l10n.get('sipdeck_tag_dare');
      case SipDeckTaskTag.social:
        return l10n.get('sipdeck_tag_social');
      case SipDeckTaskTag.messaging:
        return l10n.get('sipdeck_tag_messaging');
      case SipDeckTaskTag.physical:
        return l10n.get('sipdeck_tag_physical');
    }
  }

  IconData _iconForTag(SipDeckTaskTag tag) {
    switch (tag) {
      case SipDeckTaskTag.dare:
        return Icons.assignment_outlined;
      case SipDeckTaskTag.social:
        return Icons.group_outlined;
      case SipDeckTaskTag.messaging:
        return Icons.chat_bubble_outline;
      case SipDeckTaskTag.physical:
        return Icons.fitness_center_outlined;
    }
  }

  Color _colorForTag(SipDeckTaskTag tag) {
    switch (tag) {
      case SipDeckTaskTag.dare:
        return Colors.orange.shade700;
      case SipDeckTaskTag.social:
        return Colors.indigo.shade700;
      case SipDeckTaskTag.messaging:
        return Colors.amber.shade800;
      case SipDeckTaskTag.physical:
        return Colors.cyan.shade700;
    }
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

  void _showSipsModal(
    BuildContext context,
    WidgetRef ref,
    SipDeckGameState state,
    List<Player> players,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final currentState = ref.watch(sipDeckStateProvider);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.get('sip_tracker'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...players.map((p) {
                  final sips = currentState.playerSips[p.id] ?? 0;
                  return ListTile(
                    title: Text(p.name, style: const TextStyle(fontSize: 18)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => ref
                              .read(sipDeckStateProvider.notifier)
                              .decrementSips(p.id, 1),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '$sips',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => ref
                              .read(sipDeckStateProvider.notifier)
                              .incrementSips(p.id, 1),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
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
        return Consumer(
          builder: (context, ref, _) {
            final currentState = ref.watch(sipDeckStateProvider);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.get('sipdeck_categories'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...SipDeckCategory.values.map((cat) {
                  final isSelected = currentState.selectedCategories.contains(
                    cat,
                  );
                  return CheckboxListTile(
                    title: Text(_labelForCategory(cat, l10n)),
                    secondary: Icon(
                      _iconForCategory(cat),
                      color: _colorForCategory(cat),
                    ),
                    value: isSelected,
                    onChanged: (_) {
                      ref
                          .read(sipDeckStateProvider.notifier)
                          .toggleCategory(cat);
                    },
                  );
                }),
                const Divider(),
                Text(
                  l10n.get('sipdeck_filters'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...SipDeckTaskTag.values.map((tag) {
                  final isDisabled = currentState.disabledTags.contains(tag);
                  return CheckboxListTile(
                    title: Text(_labelForTag(tag, l10n)),
                    secondary: Icon(_iconForTag(tag), color: _colorForTag(tag)),
                    value: !isDisabled,
                    onChanged: (_) {
                      ref.read(sipDeckStateProvider.notifier).toggleTag(tag);
                    },
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  void _showCategoryHelpDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.get('category_help_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpRow(
                  l10n.get('sipdeck_cat_warmUp'),
                  l10n.get('sipdeck_help_warmup'),
                ),
                _buildHelpRow(
                  l10n.get('sipdeck_cat_wildCards'),
                  l10n.get('sipdeck_help_wildcards'),
                ),
                _buildHelpRow(
                  l10n.get('sipdeck_cat_flirty'),
                  l10n.get('sipdeck_help_flirty'),
                ),
                _buildHelpRow(
                  l10n.get('sipdeck_cat_barNight'),
                  l10n.get('sipdeck_help_barnight'),
                ),
                _buildHelpRow(
                  l10n.get('sipdeck_cat_laughs'),
                  l10n.get('sipdeck_help_laughs'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.get('ok')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
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
              ref.read(sipDeckStateProvider.notifier).resetGame();
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
