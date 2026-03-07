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
    return MultiplayerUser(
      uid: map['uid'] as String,
      name: map['name'] ?? 'Unknown',
      avatarColor: map['avatarColor'] ?? '#FFFFFF',
      isHost: map['isHost'] ?? false,
      lastActive: map['lastActive'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastActive'] as int)
          : DateTime.now(),
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
