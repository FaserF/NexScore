import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/multiplayer/providers/multiplayer_provider.dart';
import '../../settings/provider/settings_provider.dart';

class JoinLobbyScreen extends ConsumerStatefulWidget {
  const JoinLobbyScreen({super.key});

  @override
  ConsumerState<JoinLobbyScreen> createState() => _JoinLobbyScreenState();
}

class _JoinLobbyScreenState extends ConsumerState<JoinLobbyScreen> {
  final _codeController = TextEditingController();
  late final _nameController = TextEditingController(
    text: ref.read(settingsProvider).hostName,
  );
  bool _isJoining = false;

  void _join(AppLocalizations l10n) async {
    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();

    if (code.length != 5 || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.get('error_msg').replaceFirst('{0}', 'Invalid code or name'),
          ),
        ),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      final service = ref.read(multiplayerServiceProvider);
      await service.joinLobby(
        roomCode: code,
        playerName: name,
        playerAvatarColor: '#4287f5', // generic blue for now
      );

      if (mounted) {
        // Connected! Navigate to the lobby view
        context.pushReplacement('/multiplayer/lobby');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.get('error')}: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('multiplayer_join'))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: l10n.get('multiplayer_room_code'),
                hintText: 'e.g. AB8X9',
                border: const OutlineInputBorder(),
              ),
              maxLength: 5,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.get('player_name'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isJoining ? null : () => _join(l10n),
              icon: _isJoining
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login),
              label: Text(
                _isJoining ? l10n.get('loading') : l10n.get('multiplayer_join'),
              ),
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
    );
  }
}
