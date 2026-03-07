import 'dart:convert';

class PlayerGroup {
  final String id;
  final String name;
  final List<String> playerIds;

  const PlayerGroup({
    required this.id,
    required this.name,
    required this.playerIds,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'playerIds': jsonEncode(playerIds)};
  }

  factory PlayerGroup.fromMap(Map<String, dynamic> map) {
    return PlayerGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      playerIds: (jsonDecode(map['playerIds'] as String) as List<dynamic>)
          .cast<String>(),
    );
  }

  PlayerGroup copyWith({String? id, String? name, List<String>? playerIds}) {
    return PlayerGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      playerIds: playerIds ?? this.playerIds,
    );
  }
}
