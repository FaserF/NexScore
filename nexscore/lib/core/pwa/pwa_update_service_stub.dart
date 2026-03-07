import 'package:flutter_riverpod/flutter_riverpod.dart';

final pwaUpdateProvider = NotifierProvider<PwaUpdateNotifier, bool>(() {
  return PwaUpdateNotifier();
});

class PwaUpdateNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void reloadApp() {}
}
