import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/models/player_group.dart';

void main() {
  group('PlayerGroup Model Tests', () {
    test('toMap and fromMap are consistent', () {
      final group = PlayerGroup(
        id: 'group-1',
        name: 'Friday Night',
        playerIds: ['p1', 'p2', 'p3'],
      );

      final map = group.toMap();
      final fromMap = PlayerGroup.fromMap(map);

      expect(fromMap.id, group.id);
      expect(fromMap.name, group.name);
      expect(fromMap.playerIds, group.playerIds);
    });

    test('copyWith works correctly', () {
      final group = PlayerGroup(
        id: 'group-1',
        name: 'Friday Night',
        playerIds: ['p1', 'p2'],
      );

      final updated = group.copyWith(name: 'Saturday Night', playerIds: ['p3']);

      expect(updated.id, 'group-1');
      expect(updated.name, 'Saturday Night');
      expect(updated.playerIds, ['p3']);
    });
  });
}
