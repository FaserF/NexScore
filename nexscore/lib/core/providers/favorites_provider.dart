import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing favorite games using shared_preferences.
final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends Notifier<Set<String>> {
  static const _favoritesKey = 'user_favorite_games';

  @override
  Set<String> build() {
    // Initial state is an empty set.
    // _loadFavorites will update this asynchronously.
    _loadFavorites();
    return {};
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList(_favoritesKey);
    if (favList != null) {
      state = favList.toSet();
    }
  }

  Future<void> toggleFavorite(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final newFavorites = Set<String>.from(state);

    if (newFavorites.contains(gameId)) {
      newFavorites.remove(gameId);
    } else {
      newFavorites.add(gameId);
    }

    await prefs.setStringList(_favoritesKey, newFavorites.toList());
    state = newFavorites;
  }
}
