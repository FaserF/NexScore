import 'dart:async';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'models/lobby.dart';
import 'models/multiplayer_user.dart';
import 'multiplayer_service.dart';

class FirestoreMultiplayerImpl implements MultiplayerService {
  FirebaseFirestore get _firestore {
    _checkFirebase();
    return FirebaseFirestore.instance;
  }

  FirebaseAuth get _auth {
    _checkFirebase();
    return FirebaseAuth.instance;
  }

  void _checkFirebase() {
    if (Firebase.apps.isEmpty) {
      throw Exception('FIREBASE_NOT_CONFIGURED');
    }
  }

  String? _uid;
  StreamSubscription<DocumentSnapshot>? _lobbySubscription;
  final _lobbyStreamController = StreamController<Lobby?>.broadcast();
  Lobby? _currentLobby;

  @override
  bool get isHost => _currentLobby?.hostUid == _uid && _uid != null;

  @override
  Lobby? get currentLobby => _currentLobby;

  @override
  Stream<Lobby?> get lobbyUpdates => _lobbyStreamController.stream;

  Future<void> _ensureAuth() async {
    if (_uid != null) return;
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
      _uid = _auth.currentUser?.uid;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      // Fallback for environments where Auth fails or isn't set up yet
      _uid ??= const Uuid().v4();
    }
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        5,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  @override
  Future<String> hostLobby({
    required String hostName,
    required String hostAvatarColor,
    int maxPlayers = 10,
  }) async {
    await _ensureAuth();
    final uid = _uid!;

    // Generate unique code
    String roomCode = '';
    bool isUnique = false;
    while (!isUnique) {
      roomCode = _generateRoomCode();
      final doc = await _firestore
          .collection('lobbies')
          .doc(roomCode)
          .get()
          .timeout(const Duration(seconds: 10));
      if (!doc.exists) {
        isUnique = true;
      }
    }

    final hostUser = MultiplayerUser(
      uid: uid,
      name: hostName,
      avatarColor: hostAvatarColor,
      isHost: true,
      lastActive: DateTime.now(),
    );

    final lobby = Lobby(
      id: roomCode,
      hostUid: uid,
      maxPlayers: maxPlayers,
      state: LobbyState.waiting,
      users: {uid: hostUser},
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('lobbies')
        .doc(roomCode)
        .set(lobby.toMap())
        .timeout(const Duration(seconds: 10));
    _listenToLobby(roomCode);

    return roomCode;
  }

  @override
  Future<void> joinLobby({
    required String roomCode,
    required String playerName,
    required String playerAvatarColor,
  }) async {
    await _ensureAuth();
    final uid = _uid!;
    roomCode = roomCode.toUpperCase();

    final docRef = _firestore.collection('lobbies').doc(roomCode);
    final docSnap = await docRef.get().timeout(const Duration(seconds: 10));

    if (!docSnap.exists) {
      throw Exception('Lobby not found');
    }

    final lobbyMap = docSnap.data() as Map<String, dynamic>;
    final currentLobby = Lobby.fromMap(lobbyMap);

    if (currentLobby.users.length >= currentLobby.maxPlayers &&
        !currentLobby.users.containsKey(uid)) {
      throw Exception('Lobby is full');
    }

    final joinUser = MultiplayerUser(
      uid: uid,
      name: playerName,
      avatarColor: playerAvatarColor,
      isHost: false,
      lastActive: DateTime.now(),
    );

    // Atomic update to add the user
    await docRef
        .update({'users.$uid': joinUser.toMap()})
        .timeout(const Duration(seconds: 10));

    _listenToLobby(roomCode);
  }

  @override
  Future<void> leaveLobby() async {
    if (_currentLobby == null || _uid == null) return;

    final roomCode = _currentLobby!.id;
    final docRef = _firestore.collection('lobbies').doc(roomCode);

    if (isHost) {
      // Host leaves -> destroy lobby or close it
      await docRef.update({'state': LobbyState.closed.name});
      // Optionally delete the document entirely: await docRef.delete();
    } else {
      // Client leaves -> remove from users
      await docRef.update({'users.$_uid': FieldValue.delete()});
    }

    await _lobbySubscription?.cancel();
    _lobbySubscription = null;
    _currentLobby = null;
    _lobbyStreamController.add(null);
  }

  @override
  Future<void> syncGameState(Map<String, dynamic> state) async {
    if (_currentLobby == null || !isHost) return;

    final roomCode = _currentLobby!.id;
    await _firestore.collection('lobbies').doc(roomCode).update({
      'gameState': state,
    });
  }

  @override
  Future<void> sendEvent(String eventName, Map<String, dynamic> payload) async {
    if (_currentLobby == null || _uid == null) return;

    final roomCode = _currentLobby!.id;

    // We can write events to a subcollection for the host to listen to
    await _firestore
        .collection('lobbies')
        .doc(roomCode)
        .collection('events')
        .add({
          'eventName': eventName,
          'payload': payload,
          'senderUid': _uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  void _listenToLobby(String roomCode) {
    _lobbySubscription?.cancel();
    _lobbySubscription = _firestore
        .collection('lobbies')
        .doc(roomCode)
        .snapshots()
        .listen(
          (snapshot) {
            if (!snapshot.exists) {
              // Lobby was deleted
              _currentLobby = null;
              _lobbyStreamController.add(null);
              _lobbySubscription?.cancel();
              return;
            }

            _currentLobby = Lobby.fromMap(
              snapshot.data() as Map<String, dynamic>,
            );
            _lobbyStreamController.add(_currentLobby);
          },
          onError: (error) {
            debugPrint('Error listening to lobby: $error');
          },
        );
  }

  // Ensure streams are closed when service is disposed
  void dispose() {
    _lobbySubscription?.cancel();
    _lobbyStreamController.close();
  }
}
