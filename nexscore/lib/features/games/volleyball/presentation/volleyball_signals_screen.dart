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
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // or a dedicated section if available.
              // For now, using the general volleyball guide.
            },
            tooltip: l10n.get('nav_help'),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: l10n.get('finishGame'),
          ),
        ],
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.85,
              ),
              itemCount: signals.length,
              itemBuilder: (context, index) {
                final signal = signals[index];
                return InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          children: [
                            Text(signal.emoji, style: const TextStyle(fontSize: 32)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(l10n.get('vb_signal_${signal.id}'))),
                          ],
                        ),
                        content: Text(l10n.get('vb_signal_${signal.id}_desc')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.get('ok')),
                          ),
                        ],
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Card(
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
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Text(signal.emoji, style: const TextStyle(fontSize: 100)),
                            ),
                          ),
                          const SizedBox(height: 12),
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
                  ),
                );
              },
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
