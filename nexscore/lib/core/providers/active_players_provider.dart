import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player_model.dart';

class ActivePlayersNotifier extends Notifier<List<Player>> {
  @override
  List<Player> build() => [];

  void setPlayers(List<Player> players) {
    state = players;
  }
}

final activePlayersProvider =
    NotifierProvider<ActivePlayersNotifier, List<Player>>(
      ActivePlayersNotifier.new,
    );
