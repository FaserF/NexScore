"""
NexScore Card Generator Tool
============================

This tool automatically generates Dart models and Localization keys for SipDeck and BuzzTap.
It is robust and designed to be reused whenever you want to add hundreds of new cards
to the games without tedious manual copying and pasting.

Usage:
1. Add new tuples to the sipdeck_data or buzztap_data lists.
   Format: (ID, Category, Emoji, EnglishText, GermanText, Sips, MinPlayers, ExplEN, ExplDE)
   Note: explanation fields are optional and can be left empty.

2. Run this script from the project root: `python tools/generate_game_cards.py`

3. The script will output the Dart expansion files in the respective model directories
   and generate translation snippets. Since injecting into AppLocalizations is delicate,
   the script generates `expansion_locales_en.txt` and `expansion_locales_de.txt`. You
   should manually copy these into `lib/core/i18n/app_localizations.dart`.
"""

import os
import sys

# Example Data. Add your massive card lists here!
# ID must be unique (e.g. w100 for WarmUp 100).
sipdeck_data = [
    # ('w100', 'warmUp', '🧠', 'Take {0} sips.', 'Trinke {0} Schlücke.', 2, 2, '', ''),
]

buzztap_data = [
    # ('w100', 'warmup', '👋', 'Drink {0}.', 'Trinke {0}.', 2, 2),
]


def generate_expansions():
    # 1. SIPDECK
    sd_models = []
    for (id, cat, emoji, en, de, sips, minP, expl, explDE) in sipdeck_data:
        sd_models.append(f"  SipDeckCard(\n    id: '{id}',\n    emoji: '{emoji}',\n    text: l10n.get('sd_card_{id}'),\n    sips: {sips},\n    category: SipDeckCategory.{cat},\n    minPlayers: {minP},\n  ),")

    if len(sd_models) > 0:
        with open('lib/features/games/sipdeck/models/sipdeck_expansion.dart', 'w', encoding='utf-8') as f:
            f.write("import 'sipdeck_models.dart';\nimport '../../../../core/i18n/app_localizations.dart';\n\n")
            f.write("List<SipDeckCard> generateSipDeckExpansion(AppLocalizations l10n) {\n  return [\n")
            f.write('\n'.join(sd_models))
            f.write("\n  ];\n}\n")
        print("Generated sipdeck_expansion.dart")

    # 2. BUZZTAP
    bt_models = []
    for (id, cat, emoji, en, de, sips, minP) in buzztap_data:
        bt_models.append(f"  BuzzTapCard(\n    id: '{id}',\n    emoji: '{emoji}',\n    text: l10n.get('bt_card_{id}'),\n    sips: {sips},\n    category: BuzzTapCategory.{cat},\n    minPlayers: {minP},\n  ),")

    if len(bt_models) > 0:
        with open('lib/features/games/buzztap/models/buzztap_expansion.dart', 'w', encoding='utf-8') as f:
            f.write("import 'buzztap_models.dart';\nimport '../../../../core/i18n/app_localizations.dart';\n\n")
            f.write("List<BuzzTapCard> generateBuzzTapExpansion(AppLocalizations l10n) {\n  return [\n")
            f.write('\n'.join(bt_models))
            f.write("\n  ];\n}\n")
        print("Generated buzztap_expansion.dart")

    # 3. TRANSLATIONS
    locales_en = []
    locales_de = []

    for (id, cat, emoji, en, de, sips, minP, expl, explDE) in sipdeck_data:
        en = en.replace("{0}", str(sips))
        de = de.replace("{0}", str(sips))
        locales_en.append(f"      'sd_card_{id}': '{en}',")
        locales_de.append(f"      'sd_card_{id}': '{de}',")

    for (id, cat, emoji, en, de, sips, minP) in buzztap_data:
        en = en.replace("{0}", str(sips))
        de = de.replace("{0}", str(sips))
        locales_en.append(f"      'bt_card_{id}': '{en}',")
        locales_de.append(f"      'bt_card_{id}': '{de}',")

    if len(locales_en) > 0:
        with open('expansion_locales_en.txt', 'w', encoding='utf-8') as f:
            f.write("\n".join(locales_en))
        with open('expansion_locales_de.txt', 'w', encoding='utf-8') as f:
            f.write("\n".join(locales_de))
        print("Generated expansion_locales_en.txt and expansion_locales_de.txt")

if __name__ == "__main__":
    generate_expansions()
    print("Done. Remember to copy the contents of the translation text files into lib/core/i18n/app_localizations.dart!")
