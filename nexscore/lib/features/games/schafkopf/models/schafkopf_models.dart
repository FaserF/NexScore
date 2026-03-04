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
  Map<String, double> calculatePayouts() {
    double gameValue = baseTariff;

    if (gameType != SchafkopfGameType.sauspiel) {
      // Solo variants: base tariff is doubled (official Bavarian premium)
      gameValue *= 2;
    }
    if (schneider) gameValue += baseTariff;
    if (schwarz) gameValue += baseTariff;
    // Laufende (runners): official rule – only count if ≥3 consecutive trumps.
    // With runner count ≥ 3, each runner adds baseTariff.
    // With 1–2 runners, laufende are NOT scored (they are simply not Laufende).
    if (runners >= 3) {
      gameValue += (runners * baseTariff);
    }

    final bool activeWon =
        (points[activePlayerId] ?? 0) + (points[partnerPlayerId] ?? 0) > 60;

    final Map<String, double> payouts = {};

    if (gameType == SchafkopfGameType.sauspiel) {
      // Sauspiel: two-vs-two team game
      // Active player and partner split the win/loss
      final double teamValue = activeWon ? gameValue : -gameValue;
      payouts[activePlayerId] = teamValue;
      if (partnerPlayerId != null) {
        payouts[partnerPlayerId!] = teamValue;
      }
      // Opponents (not tracked individually here, handled in screen layer)
    } else {
      // Solo variant: one player against three opponents
      // Solo player earns 3× gameValue (one unit from each opponent)
      final double soloTotal = gameValue * 3;
      payouts[activePlayerId] = activeWon ? soloTotal : -soloTotal;
    }

    return payouts;
  }
}
