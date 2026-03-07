import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/multiplayer/providers/multiplayer_provider.dart';

class JoinLobbyScreen extends ConsumerStatefulWidget {
  const JoinLobbyScreen({super.key});

  @override
  ConsumerState<JoinLobbyScreen> createState() => _JoinLobbyScreenState();
}

class _JoinLobbyScreenState extends ConsumerState<JoinLobbyScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isJoining = false;

  void _join() async {
    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();

    if (code.length != 5 || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 5-digit code and name.')),
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
        ).showSnackBar(SnackBar(content: Text('Failed to join: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Room')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Room Code',
                hintText: 'e.g. AB8X9',
                border: OutlineInputBorder(),
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
              decoration: const InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isJoining ? null : _join,
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
              label: Text(_isJoining ? 'Joining...' : 'Join'),
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
