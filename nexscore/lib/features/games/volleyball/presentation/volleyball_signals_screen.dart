import 'package:flutter/material.dart';
import '../../../../core/i18n/app_localizations.dart';

class VolleyballSignalsScreen extends StatelessWidget {
  const VolleyballSignalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final signals = [
      _Signal('serve', '🏐➡️'),
      _Signal('team_to_serve', '🙋‍♂️'),
      _Signal('change_sides', '🔄'),
      _Signal('timeout', '⏱️'),
      _Signal('substitution', '🔁'),
      _Signal('ball_in', '⬇️⭕'),
      _Signal('ball_out', '⬆️❌'),
      _Signal('touch', '🖐️'),
      _Signal('net_touch', '🕸️'),
      _Signal('over_net', '✋⬆️'),
      _Signal('four_hits', '4️⃣'),
      _Signal('double_hit', '2️⃣'),
      _Signal('rotation_fault', '🔄⚠️'),
      _Signal('held_ball', '🤲'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('vb_signals_title')),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ],
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.85,
          ),
          itemCount: signals.length,
          itemBuilder: (context, index) {
            final signal = signals[index];
            return Card(
              elevation: 4,
              shadowColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(signal.emoji, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    Text(
                      l10n.get('vb_signal_${signal.id}'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Signal {
  final String id;
  final String emoji;
  _Signal(this.id, this.emoji);
}
