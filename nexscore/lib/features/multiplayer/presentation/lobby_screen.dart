import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/multiplayer/providers/multiplayer_provider.dart';
import '../../settings/provider/settings_provider.dart';
import 'package:go_router/go_router.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final bool isHostingStart;

  const LobbyScreen({super.key, this.isHostingStart = false});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  bool _isHosting = false;

  @override
  void initState() {
    super.initState();
    _initLobby();
  }

  Future<void> _initLobby() async {
    if (!widget.isHostingStart) return;
    setState(() => _isHosting = true);
    try {
      final settings = ref.read(settingsProvider);
      final service = ref.read(multiplayerServiceProvider);
      await service.hostLobby(
        hostName: settings.hostName,
        hostAvatarColor: settings.hostColor,
      );
      if (mounted) {
        setState(() {
          _isHosting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        String message = e.toString();
        if (message.contains('FIREBASE_NOT_CONFIGURED')) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(l10n.get('multiplayer_firebase_missing')),
              content: Text(l10n.get('multiplayer_firebase_missing_desc')),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Pop dialog
                    context.pop(); // Go back from lobby screen
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error hosting lobby: $e')));
          context.pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lobby = ref.watch(currentLobbyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobby'),
        leading: BackButton(
          onPressed: () async {
            await ref.read(multiplayerServiceProvider).leaveLobby();
            if (context.mounted) context.pop();
          },
        ),
      ),
      body: _isHosting
          ? const Center(child: CircularProgressIndicator())
          : lobby == null
          ? const Center(child: Text('Lobby closed.'))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Column(
                    children: [
                      const Text(
                        'ROOM CODE',
                        style: TextStyle(letterSpacing: 2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lobby.id,
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: lobby.users.length,
                    itemBuilder: (context, index) {
                      final user = lobby.users.values.elementAt(index);
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(user.name),
                        trailing: user.isHost
                            ? const Icon(Icons.star, color: Colors.amber)
                            : null,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: FilledButton(
                    onPressed: lobby.users.length > 1
                        ? () {
                            // Start Game logic
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                    ),
                    child: const Text(
                      'Choose Game',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
