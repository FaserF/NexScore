import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/player_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/drink_intensity.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/buzztap_models.dart';
import '../providers/buzztap_provider.dart';
import '../../../../core/theme/widgets/glass_container.dart';
import '../../../../core/theme/widgets/animated_scale_button.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';

class BuzzTapScreen extends ConsumerStatefulWidget {
  const BuzzTapScreen({super.key});

  @override
  ConsumerState<BuzzTapScreen> createState() => _BuzzTapScreenState();
}

class _BuzzTapScreenState extends ConsumerState<BuzzTapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial auto-toggle based on player count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final players = ref.read(activePlayersProvider);
      ref
          .read(buzzTapStateProvider.notifier)
          .toggle2PlayerOptimization(players.length == 2);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(buzzTapStateProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    // Auto-toggle optimization based on player count
    ref.listen<List<Player>>(activePlayersProvider, (previous, next) {
      if (next.length == 2 && previous?.length != 2) {
        ref.read(buzzTapStateProvider.notifier).toggle2PlayerOptimization(true);
      } else if (next.length != 2 && previous?.length == 2) {
        ref
            .read(buzzTapStateProvider.notifier)
            .toggle2PlayerOptimization(false);
      }
    });

    // Force dark theme experience for BuzzTap regardless of system settings
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'BuzzTap'.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                launchUrl(
                  Uri.parse(
                    'https://faserf.github.io/NexScore/docs/user_guide/games/#buzztap-18',
                  ),
                );
              },
              tooltip: l10n.get('nav_help'),
            ),
            IconButton(
              icon: const Icon(Icons.local_drink),
              onPressed: () =>
                  _showSipsModal(context, ref, state, players, l10n),
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
      ),
    );
  }

  Widget _buildStartScreen(
    BuildContext context,
    WidgetRef ref,
    BuzzTapGameState state,
    List<Player> players,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade900.withValues(alpha: 0.1),
            Colors.black,
            Colors.deepOrange.shade900.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          if (players.length == 2 && !_isBannerDismissed)
            MaterialBanner(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              content: Text(
                l10n.get('buzztap_2player_warning'),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bolt,
                          size: 100,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.get('sipdeck_select_modes'), // Reuse wording
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.help_outline,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () =>
                              _showCategoryHelpDialog(context, l10n),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ...BuzzTapCategory.values.map((cat) {
                      final isSelected = state.selectedCategories.contains(cat);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AnimatedScaleButton(
                          onPressed: () => ref
                              .read(buzzTapStateProvider.notifier)
                              .toggleCategory(cat),
                          child: GlassContainer(
                            padding: const EdgeInsets.all(16),
                            borderRadius: 16,
                            color: isSelected
                                ? Colors.amber.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            child: Row(
                              children: [
                                Icon(
                                  _iconForCategory(cat),
                                  color: isSelected
                                      ? Colors.amber
                                      : Colors.white54,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _labelForCategory(cat, l10n),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.amber
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    // Drink Intensity Selection
                    Text(
                      l10n.get('drink_intensity_title'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.get('drink_intensity_subtitle'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
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
                              .read(buzzTapStateProvider.notifier)
                              .toggleIntensity(val.first);
                        },
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: Colors.amber.withValues(
                            alpha: 0.2,
                          ),
                          selectedForegroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                        ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                            Slider(
                              value: state.customIntensityMultiplier,
                              min: 0.1,
                              max: 10.0,
                              divisions: 99,
                              activeColor: Colors.amber,
                              inactiveColor: Colors.amber.withValues(
                                alpha: 0.3,
                              ),
                              label: state.customIntensityMultiplier
                                  .toStringAsFixed(1),
                              onChanged: (val) {
                                ref
                                    .read(buzzTapStateProvider.notifier)
                                    .setCustomIntensity(val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    if (players.length == 2) ...[
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            l10n.get('sipdeck_optimize_2players'),
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            l10n.get('sipdeck_optimize_2players_desc'),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          value: state.optimizeForTwoPlayers,
                          activeThumbColor: Colors.amber,
                          onChanged: (val) {
                            ref
                                .read(buzzTapStateProvider.notifier)
                                .toggle2PlayerOptimization(val);
                          },
                          secondary: const Icon(
                            Icons.people_outline,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 48),
                    FilledButton(
                      onPressed: () => ref
                          .read(buzzTapStateProvider.notifier)
                          .drawNextCard(players, l10n),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 64),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'GO!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardScreen(
    BuildContext context,
    WidgetRef ref,
    BuzzTapGameState state,
    List<Player> players,
    AppLocalizations l10n,
  ) {
    final currentCard = state.playedCards.last;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        ref.read(buzzTapStateProvider.notifier).drawNextCard(players, l10n);
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _colorForCategory(currentCard.category).withValues(alpha: 0.15),
              Colors.black,
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  96, // Account for padding
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  label: Text(
                    _labelForCategory(currentCard.category, l10n).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  backgroundColor: _colorForCategory(
                    currentCard.category,
                  ).withValues(alpha: 0.2),
                  side: BorderSide(
                    color: _colorForCategory(
                      currentCard.category,
                    ).withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 32),
                if (currentCard.emoji != null)
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Text(
                      currentCard.emoji!,
                      style: const TextStyle(fontSize: 100),
                    ),
                  ),
                const SizedBox(height: 48),
                Text(
                  currentCard.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 48),
                if (currentCard.sips > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${currentCard.sips} SIPS',
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.amber,
                        fontWeight: FontWeight.w900,
                      ),
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
                                  BuzzTapTargetType.single ||
                              currentCard.targetType ==
                                  BuzzTapTargetType.everyone)
                            Expanded(
                              child: AnimatedScaleButton(
                                onPressed: () {
                                  HapticFeedback.vibrate();
                                  ref
                                      .read(buzzTapStateProvider.notifier)
                                      .completeCard(false);
                                  ref
                                      .read(buzzTapStateProvider.notifier)
                                      .drawNextCard(players, l10n);
                                },
                                child: GlassContainer(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  borderRadius: 20,
                                  color: Colors.amber,
                                  child: Text(
                                    currentCard.targetType ==
                                            BuzzTapTargetType.everyone
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
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (currentCard.targetType ==
                              BuzzTapTargetType.dual) ...[
                            Expanded(
                              child: AnimatedScaleButton(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  ref
                                      .read(buzzTapStateProvider.notifier)
                                      .incrementSips(
                                        currentCard.targetIds.first,
                                        currentCard.sips,
                                      );
                                  ref
                                      .read(buzzTapStateProvider.notifier)
                                      .drawNextCard(players, l10n);
                                },
                                child: GlassContainer(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  borderRadius: 16,
                                  color: Colors.white.withValues(alpha: 0.1),
                                  child: Text(
                                    players
                                        .firstWhere(
                                          (p) =>
                                              p.id ==
                                              currentCard.targetIds.first,
                                        )
                                        .name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AnimatedScaleButton(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  ref
                                      .read(buzzTapStateProvider.notifier)
                                      .incrementSips(
                                        currentCard.targetIds.last,
                                        currentCard.sips,
                                      );
                                  ref
                                      .read(buzzTapStateProvider.notifier)
                                      .drawNextCard(players, l10n);
                                },
                                child: GlassContainer(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  borderRadius: 16,
                                  color: Colors.white.withValues(alpha: 0.1),
                                  child: Text(
                                    players
                                        .firstWhere(
                                          (p) =>
                                              p.id ==
                                              currentCard.targetIds.last,
                                        )
                                        .name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (currentCard.targetType ==
                              BuzzTapTargetType.manual)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  ref
                                      .read(buzzTapStateProvider.notifier)
                                      .drawNextCard(players, l10n);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.amber),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(l10n.get('sipdeck_tap_continue')),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(buzzTapStateProvider.notifier)
                              .completeCard(true);
                          ref
                              .read(buzzTapStateProvider.notifier)
                              .drawNextCard(players, l10n);
                        },
                        icon: const Icon(Icons.skip_next, size: 20),
                        label: Text(l10n.get('game_skip')),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white54,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    l10n.get('sipdeck_tap_continue'),
                    style: const TextStyle(
                      color: Colors.white38,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineSipCounter(BuzzTapGameState state, List<Player> players) {
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(
                      int.parse(p.avatarColor.replaceFirst('#', '0xff')),
                    ),
                    child: Text(
                      p.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$sips',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  String _labelForCategory(BuzzTapCategory cat, AppLocalizations l10n) {
    // Add these keys to localization later
    switch (cat) {
      case BuzzTapCategory.warmup:
        return l10n.get('buzztap_cat_warmup');
      case BuzzTapCategory.party:
        return l10n.get('buzztap_cat_party');
      case BuzzTapCategory.hot:
        return l10n.get('buzztap_cat_hot');
      case BuzzTapCategory.extreme:
        return l10n.get('buzztap_cat_extreme');
    }
  }

  IconData _iconForCategory(BuzzTapCategory cat) {
    switch (cat) {
      case BuzzTapCategory.warmup:
        return Icons.wb_sunny_outlined;
      case BuzzTapCategory.party:
        return Icons.celebration;
      case BuzzTapCategory.hot:
        return Icons.whatshot;
      case BuzzTapCategory.extreme:
        return Icons.warning_amber_rounded;
    }
  }

  Color _colorForCategory(BuzzTapCategory cat) {
    switch (cat) {
      case BuzzTapCategory.warmup:
        return Colors.blue;
      case BuzzTapCategory.party:
        return Colors.purple;
      case BuzzTapCategory.hot:
        return Colors.orange;
      case BuzzTapCategory.extreme:
        return Colors.red;
    }
  }

  void _showSipsModal(
    BuildContext context,
    WidgetRef ref,
    BuzzTapGameState state,
    List<Player> players,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final currentState = ref.watch(buzzTapStateProvider);
            // Inside BuzzTap, we use the dark theme specifically
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.amber,
                  brightness: Brightness.dark,
                  surface: const Color(0xFF121212),
                ),
              ),
              child: Container(
                color: const Color(0xFF121212),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      l10n.get('sip_tracker'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...players.map((p) {
                      final sips = currentState.playerSips[p.id] ?? 0;
                      return ListTile(
                        title: Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.amber,
                              ),
                              onPressed: () => ref
                                  .read(buzzTapStateProvider.notifier)
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
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Colors.amber,
                              ),
                              onPressed: () => ref
                                  .read(buzzTapStateProvider.notifier)
                                  .incrementSips(p.id, 1),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
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
          title: Text(
            l10n.get('category_help_title'),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E1E1E), // Dark theme match
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpRow(
                  l10n.get('buzztap_cat_warmup'),
                  l10n.get('buzztap_help_warmup'),
                ),
                _buildHelpRow(
                  l10n.get('buzztap_cat_party'),
                  l10n.get('buzztap_help_party'),
                ),
                _buildHelpRow(
                  l10n.get('buzztap_cat_hot'),
                  l10n.get('buzztap_help_hot'),
                ),
                _buildHelpRow(
                  l10n.get('buzztap_cat_extreme'),
                  l10n.get('buzztap_help_extreme'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.get('ok'),
                style: const TextStyle(color: Colors.amber),
              ),
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
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
              ref.read(buzzTapStateProvider.notifier).resetGame();
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
