/// All Schafkopf game types supported including doubles and solo variants.
enum SchafkopfGameType { sauspiel, wenz, farbwenz, geier, solo, tout, sie }

/// Represents a single round of Schafkopf with full Bavarian payout calculation.
/// Payouts are in Euro-cents (base = 0.10 €). Solo variants carry a 0.50 € premium.
class SchafkopfRound {
  final int roundIndex;
  final SchafkopfGameType gameType;
  final String activePlayerId;
  final String? partnerPlayerId; // Only for Sauspiel
  final Map<String, int> points; // Trick points – max 120 total
  final bool schneider; // Opponent has ≤30 trick points
  final bool schwarz; // Opponent has 0 tricks
  final int runners; // Laufende: uninterrupted trump chain from Ober down
  final double baseTariff; // Default: 0.10 (10 Euro-cent)

  const SchafkopfRound({
    required this.roundIndex,
    required this.gameType,
    required this.activePlayerId,
    this.partnerPlayerId,
    required this.points,
    this.schneider = false,
    this.schwarz = false,
    this.runners = 0,
    this.baseTariff = 0.10,
  });

  /// Calculates the payout for each player involved in this round.
  ///
  /// Rules applied:
  /// - Solo variants (Wenz, Solo, Geier, Farbwenz, Tout) add a +0.50 base premium.
  /// - Schneider adds +0.10 per player.
  /// - Schwarz adds +0.10 per player (on top of Schneider).
  /// - Each Laufende (runner) adds +0.10 per player.
  /// - In Sauspiel (team play), active player + partner each earn `gameValue`; each opponent loses `gameValue`.
  /// - In Solo variants, the solo player earns `gameValue * 3`; each of the 3 opponents loses `gameValue`.
  /// Calculates the payout for each of the 4 players involved in this round.
  /// The resulting map will contain values for all players in `allPlayerIds`.
  Map<String, double> calculatePayouts(List<String> allPlayerIds) {
    double gameValue = baseTariff;

    if (gameType != SchafkopfGameType.sauspiel) {
      // Solo variants: base tariff is doubled (official Bavarian premium)
      gameValue *= 2;
    }
    if (schneider) gameValue += baseTariff;
    if (schwarz) gameValue += baseTariff;
    if (runners >= 3) {
      gameValue += (runners * baseTariff);
    }

    final int activeTeamPoints =
        (points[activePlayerId] ?? 0) + (points[partnerPlayerId] ?? 0);
    final bool activeWon = activeTeamPoints > 60;

    final Map<String, double> payouts = {for (var id in allPlayerIds) id: 0.0};

    if (gameType == SchafkopfGameType.sauspiel) {
      // Sauspiel: two-vs-two team game
      final double perPlayerValue = activeWon ? gameValue : -gameValue;
      payouts[activePlayerId] = perPlayerValue;
      if (partnerPlayerId != null) {
        payouts[partnerPlayerId!] = perPlayerValue;
      }

      // Opponents lose what winners gain
      final opponents = allPlayerIds
          .where((id) => id != activePlayerId && id != partnerPlayerId)
          .toList();
      for (final opId in opponents) {
        payouts[opId] = -perPlayerValue;
      }
    } else {
      // Solo variant: one player against three opponents
      final double soloTotal = gameValue * 3;
      final double winAmount = activeWon ? soloTotal : -soloTotal;
      payouts[activePlayerId] = winAmount;

      // Each opponent pays 1/3 of the solo total
      final opponents = allPlayerIds
          .where((id) => id != activePlayerId)
          .toList();
      for (final opId in opponents) {
        payouts[opId] = -(winAmount / 3);
      }
    }

    return payouts;
  }
}
