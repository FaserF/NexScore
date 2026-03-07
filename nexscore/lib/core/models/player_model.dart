class Player {
  final String id;
  final String name;
  final String avatarColor;
  final String? emoji;
  final String? ownerUid;
  final bool isDeleted;

  const Player({
    required this.id,
    required this.name,
    required this.avatarColor,
    this.emoji,
    this.ownerUid,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarColor': avatarColor,
      'emoji': emoji,
      'ownerUid': ownerUid,
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarColor: map['avatarColor'] as String,
      emoji: map['emoji'] as String?,
      ownerUid: map['ownerUid'] as String?,
      isDeleted: (map['isDeleted'] as int) == 1,
    );
  }

  Player copyWith({
    String? id,
    String? name,
    String? avatarColor,
    String? emoji,
    String? ownerUid,
    bool? isDeleted,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarColor: avatarColor ?? this.avatarColor,
      emoji: emoji ?? this.emoji,
      ownerUid: ownerUid ?? this.ownerUid,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
