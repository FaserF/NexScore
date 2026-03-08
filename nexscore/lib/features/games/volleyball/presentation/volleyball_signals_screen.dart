import 'package:flutter/material.dart';
import '../../../../core/i18n/app_localizations.dart';

class VolleyballSignalsScreen extends StatelessWidget {
  const VolleyballSignalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final signals = [
      _Signal('serve', Icons.arrow_forward),
      _Signal('team_to_serve', Icons.accessibility_new),
      _Signal('change_sides', Icons.sync),
      _Signal('timeout', Icons.timer),
      _Signal('substitution', Icons.refresh),
      _Signal('ball_in', Icons.south_east),
      _Signal('ball_out', Icons.north_east),
      _Signal('touch', Icons.back_hand),
      _Signal('net_touch', Icons.grid_on),
      _Signal('over_net', Icons.pan_tool),
      _Signal('four_hits', Icons.looks_4),
      _Signal('double_hit', Icons.looks_two),
      _Signal('rotation_fault', Icons.rotate_right),
      _Signal('held_ball', Icons.back_hand),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('vb_signals_title'))),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: signals.length,
        itemBuilder: (context, index) {
          final signal = signals[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(signal.icon, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    l10n.get('vb_signal_${signal.id}'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Signal {
  final String id;
  final IconData icon;
  _Signal(this.id, this.icon);
}
