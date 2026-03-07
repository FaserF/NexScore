import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/multiplayer/providers/multiplayer_provider.dart';
import 'package:go_router/go_router.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final bool isHostingStart;

  const LobbyScreen({super.key, this.isHostingStart = false});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  bool _isHosting = false;
  String? _roomCode;

  @override
  void initState() {
    super.initState();
    _initLobby();
  }

  Future<void> _initLobby() async {
    if (!widget.isHostingStart) return;
    setState(() => _isHosting = true);
    try {
      final service = ref.read(multiplayerServiceProvider);
      // For now, hardcode host name, later we can fetch from a generic profile/settings provider
      final code = await service.hostLobby(
        hostName: 'Host Player',
        hostAvatarColor: '#FFD700', // Gold for host
      );
      if (mounted) {
        setState(() {
          _roomCode = code;
          _isHosting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error hosting lobby: $e')));
        context.pop();
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
