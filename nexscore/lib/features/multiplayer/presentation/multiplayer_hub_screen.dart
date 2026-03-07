import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MultiplayerHubScreen extends ConsumerWidget {
  const MultiplayerHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We don't have i18n keys for multiplayer yet, using hardcoded for now or creating a fallback
    return Scaffold(
      appBar: AppBar(title: const Text('Multiplayer Hub')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.wifi_tethering,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () => context.push('/multiplayer/host'),
                icon: const Icon(Icons.add_box),
                label: const Text('Host a Room'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: () => context.push('/multiplayer/join'),
                icon: const Icon(Icons.login),
                label: const Text('Join a Room'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
