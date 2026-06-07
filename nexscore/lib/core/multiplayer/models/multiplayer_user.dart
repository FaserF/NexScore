class MultiplayerUser {
  final String uid;
  final String name;
  final String avatarColor;
  final bool isHost;
  final DateTime lastActive;

  const MultiplayerUser({
    required this.uid,
    required this.name,
    required this.avatarColor,
    this.isHost = false,
    required this.lastActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'avatarColor': avatarColor,
      'isHost': isHost,
      'lastActive': lastActive.millisecondsSinceEpoch,
    };
  }

  factory MultiplayerUser.fromMap(Map<String, dynamic> map) {
    final activeRaw = map['lastActive'];
    DateTime parsedActive = DateTime.now();
    if (activeRaw is int) {
      parsedActive = DateTime.fromMillisecondsSinceEpoch(activeRaw);
    } else if (activeRaw != null) {
      // Handle cloud_firestore Timestamp or other DateTime representations safely
      try {
        if (activeRaw.runtimeType.toString() == 'Timestamp' || activeRaw.toString().contains('Timestamp')) {
          parsedActive = (activeRaw as dynamic).toDate();
        } else if (activeRaw is String) {
          parsedActive = DateTime.parse(activeRaw);
        }
      } catch (_) {
        parsedActive = DateTime.now();
      }
    }

    return MultiplayerUser(
      uid: map['uid'] as String,
      name: map['name'] ?? 'Unknown',
      avatarColor: map['avatarColor'] ?? '#FFFFFF',
      isHost: map['isHost'] ?? false,
      lastActive: parsedActive,
    );
  }

  MultiplayerUser copyWith({
    String? uid,
    String? name,
    String? avatarColor,
    bool? isHost,
    DateTime? lastActive,
  }) {
    return MultiplayerUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      avatarColor: avatarColor ?? this.avatarColor,
      isHost: isHost ?? this.isHost,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
