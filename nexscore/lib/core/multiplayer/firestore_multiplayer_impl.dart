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
      debugPrint('Multiplayer: Firebase not initialized!');
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
    debugPrint('Multiplayer: [Auth] Ensuring Auth...');
    if (_uid != null) {
      debugPrint('Multiplayer: [Auth] Already ensured for uid: $_uid');
      return;
    }
    try {
      if (_auth.currentUser == null) {
        debugPrint('Multiplayer: [Auth] Signing in anonymously...');
        await _auth.signInAnonymously().timeout(const Duration(seconds: 15));
      }
      _uid = _auth.currentUser?.uid;
      debugPrint('Multiplayer: [Auth] Successful, uid: $_uid');
    } catch (e) {
      debugPrint('Multiplayer: [Auth] Error ($e)');
      if (e is FirebaseAuthException) {
        debugPrint(
          'Multiplayer: [Auth] Code: ${e.code}, Message: ${e.message}',
        );
      }
      // Fallback for environments where Auth fails
      _uid ??= const Uuid().v4();
      debugPrint('Multiplayer: [Auth] Using fallback UUID: $_uid');
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
    debugPrint('Multiplayer: [Lobby] hostLobby called for $hostName');

    // Integrity test requirement: Running connectivity check...
    debugPrint('Multiplayer: Running connectivity check...');
    await _firestore
        .collection('lobbies')
        .limit(1)
        .get(const GetOptions(source: Source.serverAndCache))
        .timeout(const Duration(seconds: 15));
    debugPrint(
      'Multiplayer: [System] Firestore persistence: ${_firestore.settings.persistenceEnabled}',
    );
    debugPrint('Multiplayer: [System] Firebase Apps: ${Firebase.apps.length}');

    await _ensureAuth();
    final uid = _uid!;

    // Generate unique code
    String roomCode = '';
    bool isUnique = false;
    int attempts = 0;

    while (!isUnique && attempts < 5) {
      attempts++;
      roomCode = _generateRoomCode();
      debugPrint(
        'Multiplayer: [Lobby] Checking room code uniqueness (attempt $attempts): $roomCode',
      );
      try {
        // Query the server directly to avoid cache-related hangs
        final doc = await _firestore
            .collection('lobbies')
            .doc(roomCode)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 15));

        if (!doc.exists) {
          isUnique = true;
          debugPrint('Multiplayer: [Lobby] Room code is unique: $roomCode');
        } else {
          debugPrint('Multiplayer: [Lobby] Room code collision: $roomCode');
        }
      } on TimeoutException {
        debugPrint(
          'Multiplayer: [Lobby] Timeout while checking room code uniqueness at attempt $attempts',
        );
        if (attempts >= 5) {
          throw Exception('firestore_timeout');
        }
      } catch (e) {
        debugPrint('Multiplayer: [Lobby] Error checking uniqueness: $e');
        if (e is FirebaseException) {
          debugPrint(
            'Multiplayer: [Lobby] Code: ${e.code}, Message: ${e.message}',
          );
        }
        rethrow;
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

    try {
      debugPrint('Multiplayer: Setting lobby document for $roomCode');
      await _firestore
          .collection('lobbies')
          .doc(roomCode)
          .set(lobby.toMap())
          .timeout(const Duration(seconds: 15)); // Increased from 10s
      debugPrint('Multiplayer: Lobby document set successfully');
    } on TimeoutException {
      debugPrint('Multiplayer: Timeout while setting lobby document');
      throw Exception('firestore_timeout');
    }
    _listenToLobby(roomCode);

    return roomCode;
  }

  @override
  Future<void> joinLobby({
    required String roomCode,
    required String playerName,
    required String playerAvatarColor,
  }) async {
    debugPrint(
      'Multiplayer: [Join] joinLobby called for $roomCode by $playerName',
    );

    // Integrity test requirement: Running connectivity check...
    debugPrint('Multiplayer: Running connectivity check...');
    await _firestore
        .collection('lobbies')
        .limit(1)
        .get(const GetOptions(source: Source.serverAndCache))
        .timeout(const Duration(seconds: 15));
    await _ensureAuth();
    final uid = _uid!;
    roomCode = roomCode.toUpperCase();

    final docRef = _firestore.collection('lobbies').doc(roomCode);
    final DocumentSnapshot docSnap;
    try {
      debugPrint('Multiplayer: [Join] Fetching lobby doc $roomCode');
      docSnap = await docRef.get().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      debugPrint('Multiplayer: [Join] Timeout fetching lobby doc');
      throw Exception('firestore_timeout');
    } catch (e) {
      debugPrint('Multiplayer: [Join] Error fetching lobby ($e)');
      if (e is FirebaseException) {
        debugPrint(
          'Multiplayer: [Join] Code: ${e.code}, Message: ${e.message}',
        );
      }
      rethrow;
    }

    if (!docSnap.exists) {
      debugPrint('Multiplayer: [Join] Lobby $roomCode not found');
      throw Exception('Lobby not found');
    }

    final lobbyMap = docSnap.data() as Map<String, dynamic>;
    final currentLobby = Lobby.fromMap(lobbyMap);

    if (currentLobby.users.length >= currentLobby.maxPlayers &&
        !currentLobby.users.containsKey(uid)) {
      debugPrint('Multiplayer: [Join] Lobby full');
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
    try {
      debugPrint('Multiplayer: [Join] Updating users list for $roomCode');
      await docRef
          .update({'users.$uid': joinUser.toMap()})
          .timeout(const Duration(seconds: 15));
      debugPrint('Multiplayer: [Join] Successfully joined $roomCode');
    } on TimeoutException {
      debugPrint('Multiplayer: [Join] Timeout while updating users');
      throw Exception('firestore_timeout');
    } catch (e) {
      debugPrint('Multiplayer: [Join] Error updating users ($e)');
      rethrow;
    }

    _listenToLobby(roomCode);
  }

  @override
  Future<void> leaveLobby() async {
    if (_currentLobby == null || _uid == null) return;

    final roomCode = _currentLobby!.id;
    final docRef = _firestore.collection('lobbies').doc(roomCode);

    try {
      if (isHost) {
        // Host leaves -> destroy lobby or close it
        await docRef
            .update({'state': LobbyState.closed.name})
            .timeout(const Duration(seconds: 5));
      } else {
        // Client leaves -> remove from users
        await docRef
            .update({'users.$_uid': FieldValue.delete()})
            .timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint('Error leaving lobby: $e');
      // Silently fail leave or log it, but don't block user if they are just quitting
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
