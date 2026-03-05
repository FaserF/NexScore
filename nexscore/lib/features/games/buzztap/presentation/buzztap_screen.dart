import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/buzztap_models.dart';
import '../providers/buzztap_provider.dart';
import '../../../../core/theme/widgets/glass_container.dart';
import '../../../../core/theme/widgets/animated_scale_button.dart';

class BuzzTapScreen extends ConsumerStatefulWidget {
  const BuzzTapScreen({super.key});

  @override
  ConsumerState<BuzzTapScreen> createState() => _BuzzTapScreenState();
}

class _BuzzTapScreenState extends ConsumerState<BuzzTapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  ref.read(buzzTapStateProvider.notifier).resetGame(),
            ),
          ],
        ),
        body: players.isEmpty
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
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                  child: const Icon(Icons.bolt, size: 100, color: Colors.amber),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.get('sipdeck_select_modes'), // Reuse wording
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
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
                            color: isSelected ? Colors.amber : Colors.white54,
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
                                color: isSelected ? Colors.amber : Colors.white,
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
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.all(32),
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
            const Spacer(),
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
            const Spacer(),
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
            const SizedBox(height: 64),
            Text(
              l10n.get('sipdeck_tap_continue'),
              style: const TextStyle(color: Colors.white38, letterSpacing: 1),
            ),
          ],
        ),
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
}
