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
    if (_isHosting) return; // Prevent concurrent calls

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
    } catch (e, stack) {
      if (mounted) {
        setState(() => _isHosting = false);
        final l10n = AppLocalizations.of(context);
        String message = e.toString();
        
        // Handle minified exceptions on web
        String displayMessage = message;
        if (message.contains('minified')) {
          displayMessage = 'A connection error occurred. Please check your internet and AdBlocker.';
        }

        void showDetails() {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.get('multiplayer_error_details')),
              content: SingleChildScrollView(
                child: SelectableText('Error: $e\n\nStack: $stack'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.get('ok')),
                ),
              ],
            ),
          );
        }

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
                  child: Text(l10n.get('ok')),
                ),
              ],
            ),
          );
        } else if (message.contains('unavailable') ||
            message.contains('client is offline')) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.get('multiplayer_error_offline_title')),
              content: Text(l10n.get('multiplayer_error_offline_desc')),
              actions: [
                TextButton(
                  onPressed: showDetails,
                  child: Text(l10n.get('multiplayer_error_details')),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _initLobby(); // Retry
                  },
                  child: Text(l10n.get('multiplayer_error_retry')),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.pop();
                  },
                  child: Text(l10n.get('ok')),
                ),
              ],
            ),
          );
        } else if (message.contains('firestore_timeout')) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.get('multiplayer_diagnostics')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.get('multiplayer_diagnostics_desc')),
                  const SizedBox(height: 12),
                  Text('• ${l10n.get('multiplayer_adblock_title')}'),
                  Text('• ${l10n.get('multiplayer_domains_title')}'),
                  Text('• ${l10n.get('multiplayer_diagnostics_auth')}'),
                  Text('• ${l10n.get('multiplayer_diagnostics_db')}'),
                  const SizedBox(height: 12),
                  Text(l10n.get('multiplayer_diagnostics_timeout')),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: showDetails,
                  child: Text(l10n.get('multiplayer_error_details')),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _initLobby(); // Retry
                  },
                  child: Text(l10n.get('multiplayer_error_retry')),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.pop();
                  },
                  child: Text(l10n.get('ok')),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.getWith('multiplayer_error_host', [displayMessage]),
              ),
              action: SnackBarAction(
                label: l10n.get('multiplayer_error_details'),
                onPressed: showDetails,
              ),
            ),
          );
          context.pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lobby = ref.watch(currentLobbyProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('multiplayer_host')),
        leading: BackButton(
          onPressed: () async {
            await ref.read(multiplayerServiceProvider).leaveLobby();
            if (context.mounted) context.pop();
          },
        ),
      ),
      body: _isHosting
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (lobby == null)
                  Expanded(
                    child: Center(
                      child: Text(l10n.get('multiplayer_lobby_closed')),
                    ),
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.all(32),
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Column(
                      children: [
                        Text(
                          l10n.get('multiplayer_room_code').toUpperCase(),
                          style: const TextStyle(letterSpacing: 2),
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
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
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
                      child: Text(
                        l10n.get('home_choose_game'),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
