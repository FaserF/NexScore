import 'package:flutter/material.dart';
import '../../core/theme/widgets/glass_container.dart';

class ShareableCard extends StatelessWidget {
  final String title;
  final String text;
  final String? emoji;
  final String? explanation;
  final Color baseColor;
  final String? brandText;

  const ShareableCard({
    super.key,
    required this.title,
    required this.text,
    this.emoji,
    this.explanation,
    required this.baseColor,
    this.brandText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [baseColor.withValues(alpha: 0.8), baseColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Branding
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NexScore',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (brandText != null)
                Text(
                  brandText!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white60,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 40),

          // Content
          GlassContainer(
            padding: const EdgeInsets.all(32),
            borderRadius: 32,
            child: Column(
              children: [
                Text(
                  title.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white70,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                if (emoji != null) ...[
                  Text(emoji!, style: const TextStyle(fontSize: 80)),
                  const SizedBox(height: 24),
                ],
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                if (explanation != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    explanation!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Footer
          Text(
            'Join the fun at nexscore.app',
            style: theme.textTheme.labelMedium?.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
