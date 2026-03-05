import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schafkopf_models.dart';

class SchafkopfStateNotifier extends Notifier<List<SchafkopfRound>> {
  @override
  List<SchafkopfRound> build() => [];

  void addRound(SchafkopfRound round) {
    state = [...state, round];
  }

  void removeLastRound() {
    if (state.isNotEmpty) {
      state = state.sublist(0, state.length - 1);
    }
  }
}

final schafkopfStateProvider =
    NotifierProvider<SchafkopfStateNotifier, List<SchafkopfRound>>(
      SchafkopfStateNotifier.new,
    );
