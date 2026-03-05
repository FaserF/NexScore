import 'package:flutter/widgets.dart';

/// Complete localization for NexScore – English and German.
/// All keys must exist in both locales; the CI test enforces this.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>>
  localizedValues = <String, Map<String, String>>{
    'en': {
      // ── Navigation
      'nav_players': 'Players',
      'nav_games': 'Games',
      'nav_history': 'History',
      'nav_leaderboard': 'Leaderboard',
      'nav_account': 'Account',
      'account': 'Account',
      'nav_help': 'Help',

      // ── General
      'app_name': 'NexScore',
      'ok': 'OK',
      'cancel': 'Cancel',
      'close': 'Close',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'share': 'Share',
      'error': 'Error',
      'error_msg': 'Error: {0}',
      'loading': 'Loading…',
      'add': 'Add',
      'settings': 'Settings',
      'settings_theme': 'Design (Theme)',
      'settings_theme_light': 'Light',
      'settings_theme_dark': 'Dark',
      'settings_theme_system': 'System Default',
      'settings_language': 'Language',
      'settings_language_en': 'English',
      'settings_language_de': 'German',
      'settings_data': 'Data Management',
      'settings_db_reset': 'Reset Database',
      'settings_db_reset_confirm':
          'Are you sure? All players, history and leaderboards will be permanently deleted.',
      'settings_db_reset_success': 'Database has been reset.',
      'back': 'Back',

      // ── Home / Games List
      'home_choose_game': 'Choose a game to track scores',
      'home_tag_card': 'Card Game',
      'home_tag_dice': 'Dice Game',
      'home_tag_sport': 'Sport',
      'home_tag_party': '18+ Party',

      // ── Game Descriptions
      'desc_wizard':
          'Classic trick-taking card game. Bid your tricks, outsmart your rivals. Standard, Lenient & Extreme variants.',
      'desc_qwixx':
          'Cross off numbers in four coloured rows before anyone else. Every cross matters.',
      'desc_schafkopf':
          'Traditional Bavarian card game with full payout calculation. Laufende, Schneider & Schwarz included.',
      'desc_kniffel':
          'Roll five dice up to three times and fill your score sheet. complete the sheet to win.',
      'desc_phase10':
          'Complete all 10 phases before your opponents. Supports Original, Masters and Duel variants.',
      'desc_darts':
          'Classic 301, 501, 701 or 1001 darts scoring. Checkout on double.',
      'desc_romme':
          'Points-based card game tracker for multiple rounds. Lowest score wins.',
      'desc_arschloch':
          'President card game. Shed all your cards first to become President.',
      'desc_sipdeck':
          'Party card game for adults (18+). 50+ challenges across five categories.',

      // ── Players
      'players': 'Players',
      'no_players': 'No players yet. Add your first player!',
      'add_player': 'Add Player',
      'player_name': 'Player name',
      'edit_player': 'Edit Player',
      'name_required': 'Name is required',
      'players_add_success': 'Player {0} added',
      'players_delete_confirm': 'Delete player {0}?',

      // ── Games list
      'games_title': 'Games',
      'games_subtitle': 'Choose a game to track',

      // ── Game names & descriptions
      'game_wizard': 'Wizard',
      'game_wizard_desc':
          'The classic trick-taking card game. Bid your tricks, outsmart your rivals. Standard, Lenient & Extreme variants.',
      'game_qwixx': 'Qwixx',
      'game_qwixx_desc':
          'Cross off numbers in four coloured rows before anyone else. Every cross counts!',
      'game_schafkopf': 'Schafkopf',
      'game_schafkopf_desc':
          'Traditional Bavarian card game tracker. Supports Sauspiel, Solo, Wenz, and all variants with full payout calculation.',
      'game_kniffel': 'Kniffel',
      'game_kniffel_desc':
          'Roll five dice up to three times and fill your score sheet. Hit Kniffel for the jackpot!',
      'game_phase10': 'Phase 10',
      'game_phase10_desc':
          'Complete all 10 phases before anyone else. Track your current phase and penalty points.',
      'game_darts': 'Darts X01',
      'game_darts_desc':
          'Classic X01 darts scoring. Supports 301, 501, 701 and 1001. Checkout on double.',
      'game_romme': 'Rommé',
      'game_romme_desc':
          'Points-based Rommé score tracker. Lowest score after all rounds wins.',
      'game_sipdeck': 'SipDeck',
      'game_sipdeck_desc':
          'Party card game for adults (18+). Hundreds of challenges, dares & rules. Tap a card to begin.',
      'game_arschloch': 'Arschloch / President',
      'game_arschloch_desc':
          'Classic President card game. Shed all cards first to become President. Track ranks, card exchange rules and cumulative points.',

      // ── Help screen
      'help_title': 'Help & Feedback',
      'help_docs': 'NexScore Documentation',
      'help_docs_desc': 'Game rules, setup guides, and feature documentation.',
      'help_bug': 'Report a Bug',
      'help_bug_desc': 'Found an issue? Let us know via GitHub Issues.',
      'help_feature': 'Request a Feature',
      'help_feature_desc': 'Have an idea? Submit a feature request on GitHub.',
      'help_discuss': 'Community Discussions',
      'help_discuss_desc': 'Ask questions and chat with other NexScore users.',
      'help_source': 'Source Code',
      'help_source_desc': 'NexScore is open source on GitHub.',
      'help_settings': 'App Settings',

      // ── Wizard
      'wizard_title': 'Wizard',
      'wizard_round': 'Round',
      'wizard_next_round': 'Enter Round {0}',
      'wizard_bid': 'Bid',
      'wizard_predictions': 'Predictions',
      'wizard_actuals': 'Results',
      'wizard_won': 'Won',
      'wizard_save_round': 'Save Round',
      'wizard_start_round': 'Start at round',
      'wizard_end_game': 'End Game',
      'wizard_end_game_confirm': 'Are you sure you want to end the game early?',
      'wizard_error_tricks': 'Tricks sum ({0}) must equal round number ({1}).',
      'wizard_bombs': 'Played Bombs',
      'wizard_error_tricks_extreme':
          'Sum of won tricks ({0}) + bombs ({1}) must be equal to round number ({2}).',
      'wizard_history': 'Round History ({0} rounds)',
      'wizard_scoring_standard': 'Standard – correct bid = +20 + tricks×10',
      'wizard_scoring_lenient': 'Lenient – tricks offset against bids',
      'wizard_scoring_extreme': 'Extreme – correct = +30, wrong = ‒2× penalty',
      'wizard_rule_stiche': 'Stiche dürfen nicht aufgehen',
      'wizard_rule_stiche_desc': 'Last player cannot force a tie.',
      'wizard_2player_warning':
          'Note: Amigo does not officially support Wizard with only 2 players.',
      'game_no_players': 'No players selected.',
      'game_setup_title': 'Game Setup',
      'game_setup_choose_players': 'Choose players for {0}',
      'game_setup_start': 'Start Game',
      'game_setup_min_players': 'Please select at least {0} players.',

      // ── Schafkopf
      'schafkopf_title': 'Schafkopf',
      'schafkopf_payouts': 'Total Payouts (€)',
      'schafkopf_no_rounds': 'No rounds yet. Add the first round!',
      'schafkopf_game_type': 'Game Type',
      'schafkopf_active_player': 'Active Player (Spieler)',
      'schafkopf_partner': 'Partner (Mitspieler)',
      'schafkopf_active_won': 'Active player won?',
      'schafkopf_schneider': 'Schneider',
      'schafkopf_schwarz': 'Schwarz',
      'schafkopf_runners': 'Laufende (runners)',
      'schafkopf_runners_warning':
          '⚠ Laufende only count at ≥3 runners (official Bavarian rule)',
      'schafkopf_base_tariff': 'Base tariff (€)',
      'schafkopf_undo': 'Remove last round',
      'schafkopf_runners_count': '{0}× Laufende',
      'schafkopf_requires_4': 'Schafkopf requires exactly 4 players.',
      'schafkopf_gt_sauspiel': 'Sauspiel',
      'schafkopf_gt_wenz': 'Wenz',
      'schafkopf_gt_solo': 'Solo',
      'schafkopf_gt_tout': 'Tout',
      'schafkopf_won': 'Won',
      'schafkopf_lost': 'Lost',

      // ── Arschloch
      'arschloch_title': 'Arschloch / President',
      'arschloch_rank_president': 'President',
      'arschloch_rank_vice_president': 'Vice President',
      'arschloch_rank_neutral': 'Citizen',
      'arschloch_rank_vice_arschloch': 'Vice Asshole',
      'arschloch_rank_arschloch': 'Asshole',
      'arschloch_rounds': 'Rounds: Pres {0} | Asshole {1}',
      'arschloch_exchange_title': 'Card Exchange for next round:',
      'arschloch_exchange_p_to_a':
          '{0} gives 2 best cards to {1} (Asshole → President)',
      'arschloch_exchange_a_to_p': '{0} gives 2 lowest cards back',
      'arschloch_exchange_vp_to_vpa': '{0} gives 1 best card to {1}',
      'arschloch_rules': 'Rules',
      'arschloch_finish_order': 'Finish Order',
      'arschloch_ranked': 'Ranked:',
      'arschloch_tap_to_rank': 'Tap to rank:',
      'arschloch_min_3_players': '⚠ Arschloch requires at least 3 players.',
      'arschloch_goal': 'Goal',
      'arschloch_goal_desc':
          'Be the first to shed all cards → President. Last with cards = Asshole.',
      'arschloch_ranks_desc':
          '1. President | 2. Vice-President | Mid: Citizen | 2nd-to-last: Vice-Asshole | Last: Asshole',
      'arschloch_rules_exchange_p':
          'Asshole gives 2 best cards to President. President gives 2 cards back.',
      'arschloch_rules_exchange_vp':
          'Vice-Asshole gives 1 best card to Vice-President (≥5 players).',
      'arschloch_rules_special': 'Special Rules',
      'arschloch_rules_2_high': '• 2 is the highest card.',
      'arschloch_rules_bomb': '• Bomb: 4 of a kind beats everything.',
      'arschloch_rules_passing': '• Passing is allowed.',

      // ── Kniffel
      'kniffel_title': 'Kniffel',
      'kniffel_upper': 'Upper Section',
      'kniffel_lower': 'Lower Section',
      'kniffel_bonus': 'Bonus (63+)',
      'kniffel_total': 'Total',
      'kniffel_cat_aces': 'Aces (1s)',
      'kniffel_cat_twos': 'Twos (2s)',
      'kniffel_cat_threes': 'Threes (3s)',
      'kniffel_cat_fours': 'Fours (4s)',
      'kniffel_cat_fives': 'Fives (5s)',
      'kniffel_cat_sixes': 'Sixes (6s)',
      'kniffel_cat_3ofakind': '3 of a kind',
      'kniffel_cat_4ofakind': '4 of a kind',
      'kniffel_cat_fullhouse': 'Full House (25)',
      'kniffel_cat_smstraight': 'Small Straight (30)',
      'kniffel_cat_lgstraight': 'Large Straight (40)',
      'kniffel_cat_yahtzee': 'Yahtzee (50)',
      'kniffel_cat_chance': 'Chance',
      'kniffel_enter_score': 'Enter score for {0}',

      // ── Darts
      'darts_title': 'Darts (X01)',
      'darts_target': 'Darts ({0})',
      'darts_avg': 'Avg: {0}',
      'darts_thrown': 'Darts thrown: {0}',
      'darts_bust': 'Bust',
      'darts_enter_score': 'Score for {0}',
      'darts_input_desc': 'Enter total score of 3 darts',

      // ── Phase 10
      'phase10_variant': 'Phase 10 Variant',
      'phase10_original': 'Original',
      'phase10_masters': 'Masters',
      'phase10_duel': 'Duel',
      'phase10_phase': 'Phase',
      'phase10_legend_tap': 'Tap for phase descriptions',
      'phase10_penalty': 'Penalty Points',
      'phase10_penalty_desc':
          'Cards remaining in hand (number cards = face value, wild = 25, skip = 15)',
      'phase10_done': 'Done: {0}',
      'phase10_pick_phase': 'Pick next phase',
      'phase10_legend_title': 'Phase Descriptions',
      'phase10_v_desc_original': 'Original – complete phases 1–10 in order',
      'phase10_v_desc_masters':
          'Masters – choose any phase each round (can repeat)',
      'phase10_v_desc_duel': 'Duel (2 players) – choose phases tactically',
      'phase10_p1_title': 'Phase 1', 'phase10_p1_desc': '2 sets of 3',
      'phase10_p2_title': 'Phase 2',
      'phase10_p2_desc': '1 set of 3 + 1 run of 4',
      'phase10_p3_title': 'Phase 3',
      'phase10_p3_desc': '1 set of 4 + 1 run of 4',
      'phase10_p4_title': 'Phase 4', 'phase10_p4_desc': '1 run of 7',
      'phase10_p5_title': 'Phase 5', 'phase10_p5_desc': '1 run of 8',
      'phase10_p6_title': 'Phase 6', 'phase10_p6_desc': '1 run of 9',
      'phase10_p7_title': 'Phase 7', 'phase10_p7_desc': '2 sets of 4',
      'phase10_p8_title': 'Phase 8', 'phase10_p8_desc': '7 cards of 1 color',
      'phase10_p9_title': 'Phase 9',
      'phase10_p9_desc': '1 set of 5 + 1 set of 2',
      'phase10_p10_title': 'Phase 10',
      'phase10_p10_desc': '1 set of 5 + 1 set of 3',

      // ── Rommé
      'romme_title': 'Rommé',
      'romme_round': 'Round',
      'romme_no_rounds': 'No rounds yet. Tap + to add.',
      'romme_leader': 'Leader: {0}',
      'romme_penalty_title': 'Round {0} – Enter Penalty Points',

      // ── History
      'history': 'History',
      'history_empty': 'No completed games yet. Start playing!',
      'history_share': 'Share Results',
      'history_completed': 'Completed',
      'history_duration': 'Duration',
      'history_players': 'Players',
      'history_share_tooltip': 'Share result',
      'history_copied': 'Result copied to clipboard!',
      'history_pts': 'Pts',
      'history_no_sessions': 'No completed sessions yet.',

      // ── Leaderboard
      'leaderboard_title': 'Leaderboard',
      'leaderboard_empty':
          'No game history yet. Play some games to see rankings!',
      'leaderboard_wins': 'W',
      'leaderboard_games': 'Games',
      'leaderboard_win_rate': 'Win Rate',
      'leaderboard_score': 'Score',

      // ── SipDeck
      'sipdeck_title': 'SipDeck',
      'sipdeck_ready': 'Ready to play?',
      'sipdeck_players_ready': '{0} players ready',
      'sipdeck_start': 'START GAME',
      'sipdeck_tap_continue': 'Tap anywhere for next card',
      'sipdeck_sips': '{0} Sips',
      'sipdeck_categories': 'Categories',
      'sipdeck_select_modes': 'Which modes do you want to play?',
      'sipdeck_no_players': 'Add players first to play SipDeck.',
      'sipdeck_18_warning': 'Must be 18+ to play.',
      'sipdeck_2player_warning':
          'SipDeck is best enjoyed with 3 or more players!',
      'sipdeck_cat_warmUp': 'Warm Up',
      'sipdeck_cat_wildCards': 'Wild Cards',
      'sipdeck_cat_flirty': 'Flirty (18+)',
      'sipdeck_cat_barNight': 'Bar Night',
      'sipdeck_cat_laughs': 'Laughs',

      // ── Account / Auth
      'account_title': 'Account',
      'account_signed_out_title': 'Sign in to sync',
      'account_signed_out_body':
          'Sign in to backup and sync your match history across all your devices. We support Google Cloud and GitHub Gist.',
      'account_offline_note':
          'NexScore works fully offline without an account.',
      'account_sign_in_google': 'Sign in with Google',
      'account_sign_in_github': 'Sign in with GitHub (Gist)',
      'account_sync_active': 'Sync active',
      'account_sync_github': 'Gist Sync active',
      'account_sign_out': 'Sign Out',
      'account_sign_in_error': 'Sign-in failed: {0}',
      'account_data_stay_note':
          'Your local data remains on this device when you sign out.',
      'error_name_taken': 'A player with this name already exists.',

      // ── SipDeck Cards (EN)
      'sd_card_w001':
          '🔵 {0}, name three things you can see that are blue. Fail? Take 2 sips.',
      'sd_card_w001_expl':
          'Look around and name 3 blue objects. If you can\'t find them or stutter, drink the penalty.',
      'sd_card_w002':
          '🌊 Waterfall! {0} starts. Everyone follows. Stop only when the person to your left stops.',
      'sd_card_w002_expl':
          'Everyone starts drinking. You can only stop once the person before you stops. {0} is the first who can choose to stop.',
      'sd_card_w003':
          '🗣️ {0} gives {1} a compliment. {1} must respond in a made-up language. Fail? Take 3 sips.',
      'sd_card_w003_expl':
          '{0} says something nice. {1} must reply with gibberish. If {1} uses real words, {1} drinks 3.',
      'sd_card_w004':
          '🧟 Group votes: who would survive a zombie apocalypse? Fewest votes = 2 sips.',
      'sd_card_w004_expl':
          'On three, everyone points to the person they think is most survival-ready. The "loser" drinks.',
      'sd_card_w005':
          '🐘 {0}, 10 seconds to name 5 animals. Miss any? Drink 1 sip per miss.',
      'sd_card_w005_expl':
          'Quick! Name 5 animals before the group counts to 10. Drink for every animal you missed.',
      'sd_card_w006': '👍 Thumb war! {0} vs {1}. Loser takes 2 sips.',
      'sd_card_w006_expl':
          'The classic duel. Hook fingers, pin the opponent\'s thumb for 3 seconds to win.',
      'sd_card_w007': '🧦 Everyone wearing socks takes 1 sip.',
      'sd_card_w007_expl': 'Socks on? Drink. Barefoot? You\'re safe.',
      'sd_card_w008':
          '🎭 {0}, do your best celebrity impression. Bad impression? Take 3 sips.',
      'sd_card_w008_expl':
          'Impersonate someone famous. The group decides if it was recognizable. If not, drink.',
      'sd_card_w009':
          '🤫 Never Have I Ever: {0} starts. Go around the circle once.',
      'sd_card_w009_expl':
          '{0} says something they\'ve never done. Anyone who HAS done it must take a sip.',
      'sd_card_w010':
          '👁️ {0} and {1} have a staring contest. First to blink takes 2 sips.',
      'sd_card_w010_expl':
          'Look into each other\'s eyes. No blinking allowed. The first to blink or look away drinks 2.',
      'sd_card_w011':
          '✂️ Rock Paper Scissors tournament. Last place takes 3 sips.',
      'sd_card_w011_expl':
          'Play RPS in rounds. The ultimate loser of the whole group drinks 3 sips.',
      'sd_card_w012':
          '👥 {0}, mimic the person to your left for the next 2 minutes. Forget? Take 2 sips.',
      'sd_card_w012_expl':
          'You are now a shadow. Copy their gestures and speech. If you break character, take 2 sips.',
      'sd_card_w013':
          '🗣️ Group vote: who talks the most? That person takes 2 sips.',
      'sd_card_w013_expl':
          'The group identifies the chatterbox. That lucky person takes 2 sips.',
      'sd_card_wc001':
          '🏴‍☠️ {0} must speak like a pirate for the next 3 rounds, or take 4 sips.',
      'sd_card_wc001_expl':
          'Use "Arrgh", "Ahoy" and pirate slang. If you use normal speech before 3 rounds end, drink 4.',
      'sd_card_wc002':
          '⚖️ Make a rule. {0} creates a rule everyone must follow this round. Break it? 2 sips.',
      'sd_card_wc002_expl':
          'Invent something crazy (e.g. no using names). Anyone who breaks it takes 2 sips.',
      'sd_card_wc003':
          '🏷️ {0}, you have a new name: "{1}". Anyone using your real name drinks 1 sip.',
      'sd_card_wc003_expl':
          '{0} is now "{1}". If anyone slips up and uses {0}\'s real name, they must sip.',
      'sd_card_wc004':
          '🎯 {0} assigns one sip each to three different people. No questions asked.',
      'sd_card_wc004_expl':
          'You are the Sip Master. Choose 3 people to take 1 sip each.',
      'sd_card_wc005':
          '💪 CHALLENGE: {0} does 10 jumping jacks, or takes 5 sips.',
      'sd_card_wc005_expl':
          'Burn those calories! Do 10 clean jumping jacks or admit defeat and drink 5.',
      'sd_card_wc006':
          '📞 Telephone! {0} whispers a phrase, it goes around. Wrong at the end? Take 3 sips.',
      'sd_card_wc006_expl':
          'Whisper a secret phrase. If it arrives mangled at the last person, everyone (or the mangler) drinks 3.',
      'sd_card_wc007':
          '📱 Everyone on their phones: screenshot your last search. Most embarrassing? Take 3 sips.',
      'sd_card_wc007_expl':
          'Show your browser history. The group identifies the weirdest search. That person drinks.',
      'sd_card_wc008':
          '😂 {0}, every time you laugh for the next 5 minutes, take 1 sip.',
      'sd_card_wc008_expl':
          'Stay serious! Every chuckle or giggle costs you 1 sip. Good luck staying stony-faced.',
      'sd_card_wc009':
          '✨ VIRUS CURED: The ongoing rule ends. Everyone else takes 1 sip in celebration.',
      'sd_card_wc009_expl':
          'All active viruses/rules are gone! The group drinks a celebratory sip.',
      'sd_card_wc010':
          '🎨 {0} draws a portrait of {1} without looking at the paper. Worst drawing? Drink 3.',
      'sd_card_wc010_expl':
          'Pen on paper, eyes on {1}. Draw! The group judges the "masterpiece". Drink 3 if it\'s a mess.',
      'sd_card_wc011':
          '🤸 Group challenge: plank position. Last one standing gives out 5 sips.',
      'sd_card_wc011_expl':
          'Everyone hit the floor! The one who holds the plank the longest assigns 5 sips to others.',
      'sd_card_f001':
          '💖 {0}, give {1} a genuine compliment about their style. If you blush, take 2 sips.',
      'sd_card_f001_expl':
          'Pick something specific (hair, outfit, eyes) and be sincere. If you turn red, you drink 2.',
      'sd_card_f002':
          '🤝 {0} and {1} have 30 seconds to find one thing in common. Fail? Both take 3 sips.',
      'sd_card_f002_expl':
          'Talk! Find a shared hobby, food preference, or experience. If 30s pass without a match, both drink.',
      'sd_card_f003':
          '💌 {0}, text your most recent contact a heart emoji. Refuse? Take 2 sips.',
      'sd_card_f003_expl':
          'Open your messaging app and send a "❤️" to the very first person in your list. No heart? Take 2 sips.',
      'sd_card_f004':
          '😁 Everyone votes: cutest smile in the room. That person gives out 3 sips.',
      'sd_card_f004_expl':
          'Flash those pearly whites! The group points to their favorite. The winner chooses who drinks 3 sips.',
      'sd_card_f005':
          '🤐 {0}, describe your crush without naming them. Group tries to guess.',
      'sd_card_f005_expl':
          'Give hints about their looks or personality. If nobody can guess within a minute, you might need to give a better hint!',
      'sd_card_f006':
          '📊 Truth: {0}, rate each person 1–10. Refuse? Take 4 sips.',
      'sd_card_f006_expl':
          'Be honest but gentle! Rate everyone on a scale of 1 to 10. If you\'re too chicken to do it, drink 4.',
      'sd_card_f007':
          '📝 Everyone writes a one-word compliment for {0}. {0} guesses who wrote each. Wrong? 1 sip each.',
      'sd_card_f007_expl':
          'Each player (except {0}) writes a nice word on their phone. {0} tries to match the word to the writer. Drink for every wrong guess.',
      'sd_card_b001':
          '🥂 {0} starts a toast. Everyone adds a sentence. Break the flow? Take 2 sips.',
      'sd_card_b001_expl':
          'Start a speech. Each person in the circle continues the story with one sentence. Stumble or stop? Drink.',
      'sd_card_b002':
          '💰 Guess the price of the most expensive drink here. Furthest off takes 2 sips.',
      'sd_card_b002_expl':
          'Check the menu! Everyone shouts a price. The one who is the furthest from the actual price drinks 2.',
      'sd_card_b003':
          '🍹 Everyone orders something they have never tried before, or takes 2 sips.',
      'sd_card_b003_expl':
          'Next round duty! If you order your usual, you take 2 sips as a penalty. Trial a new drink!',
      'sd_card_b004':
          '🍻 {0} must say "cheers" in 3 languages this round, or 1 sip per missing language.',
      'sd_card_b004_expl':
          'Show off your worldliness. "Prost", "Salute", "Cheers"... you need 3. Drink for every one you can\'t name.',
      'sd_card_b005':
          '🪑 Group: everyone stands and switches seats. Last to sit takes 2 sips.',
      'sd_card_b005_expl':
          'Chinese Laundry! Everyone must find a new chair. The slowpoke who is last to sit down drinks 2.',
      'sd_card_b006':
          '🤝 {0}, talk to a stranger for at least 1 minute. Fail? Take 4 sips.',
      'sd_card_b006_expl':
          'Social challenge! Approach someone you don\'t know and keep a conversation going for 60s. Or drink 4.',
      'sd_card_l001':
          '🐧 {0}, walk like a penguin to the other end of the room and back.',
      'sd_card_l001_expl':
          'Keep your arms tight and waddle! If you break character or stop waddling, the group may demand 2 sips.',
      'sd_card_l002':
          '☕ VIRUS: {0} must end every sentence with "and that\'s the tea" for the next 5 cards, or take 2 sips.',
      'sd_card_l002_expl':
          'For the next 5 rounds, every time you talk, you MUST say "and that\'s the tea" at the end. Forget? Drink 2.',
      'sd_card_l003':
          '🦒 {0}, narrate what is happening right now as a nature documentary. 60 seconds.',
      'sd_card_l003_expl':
          'Channel your inner David Attenborough. Describe the "wild animals" (your friends) at the bar/party.',
      'sd_card_l004':
          '🤣 Everyone says the funniest word they know at the same time. Best word gives out 2 sips.',
      'sd_card_l004_expl':
          'On three, shout! The funniest sounding word (by group consensus) allows its speaker to assign 2 sips.',
      'sd_card_l005':
          '❓ {0} can only ask questions for the next 2 minutes. Statements? 1 sip each.',
      'sd_card_l005_expl':
          'Don\'t say facts! Every time you speak, it must be a question? If you make a statement, drink!',
      'sd_card_l006':
          '🖐️ {0}, explain your job using only hand gestures. Nobody guesses in 30s? Take 3 sips.',
      'sd_card_l006_expl':
          'Pantomime your daily work. No speaking! if your friends are too clueless to guess in 30s, you drink.',
      'sd_card_l007':
          '🆕 {0}, invent a new word and use it convincingly. Group votes if it sounds real.',
      'sd_card_l007_expl':
          'Make up a word and give its definition. If the group thinks it sounds like a real word, you\'re safe.',
      'sd_card_l008':
          '🏙️ Speed round: name a film, a song, and a city starting with the letter the person to your left picks.',
      'sd_card_l008_expl':
          'The person to your left gives you a letter (e.g. "B"). You have 10 seconds for all three. Fail? Drink 2.',
      'sd_card_l009':
          '🐢 {0}, speak in slow motion for the next 3 turns or take 3 sips.',
      'sd_card_l009_expl':
          'Every. Single. Word. Drawn. Out. Long. If you talk at normal speed within 3 turns, drink 3.',
    },
    'de': {
      // ── Navigation
      'nav_players': 'Spieler',
      'nav_games': 'Spiele',
      'nav_history': 'Verlauf',
      'nav_leaderboard': 'Rangliste',
      'nav_account': 'Konto',
      'account': 'Konto',
      'nav_help': 'Hilfe',

      // ── General
      'app_name': 'NexScore',
      'ok': 'OK',
      'cancel': 'Abbrechen',
      'close': 'Schließen',
      'save': 'Speichern',
      'delete': 'Löschen',
      'edit': 'Bearbeiten',
      'share': 'Teilen',
      'error': 'Fehler',
      'error_msg': 'Fehler: {0}',
      'loading': 'Laden…',
      'add': 'Hinzufügen',
      'settings': 'Einstellungen',
      'settings_theme': 'Design (Farbschema)',
      'settings_theme_light': 'Hell',
      'settings_theme_dark': 'Dunkel',
      'settings_theme_system': 'Systemvorgabe',
      'settings_language': 'Sprache',
      'settings_language_en': 'Englisch',
      'settings_language_de': 'Deutsch',
      'settings_data': 'Datenverwaltung',
      'settings_db_reset': 'Datenbank zurücksetzen',
      'settings_db_reset_confirm':
          'Bist du sicher? Alle Spieler, der Verlauf und die Ranglisten werden permanent gelöscht.',
      'settings_db_reset_success': 'Datenbank wurde zurückgesetzt.',
      'back': 'Zurück',

      // ── Home / Games List
      'home_choose_game': 'Wähle ein Spiel zum Punkte-Tracking',
      'home_tag_card': 'Kartenspiel',
      'home_tag_dice': 'Würfelspiel',
      'home_tag_sport': 'Sport',
      'home_tag_party': '18+ Party',

      // ── Game Descriptions
      'desc_wizard':
          'Klassisches Stichspiel. Sage deine Stiche voraus und überliste deine Rivalen. Standard, Kulant & Extrem Varianten.',
      'desc_qwixx':
          'Kreuze Zahlen in vier farbigen Reihen ab, bevor es jemand anderes tut. Jedes Kreuz zählt.',
      'desc_schafkopf':
          'Traditionelles bayerisches Kartenspiel mit voller Tarifberechnung. Laufende, Schneider & Schwarz inklusive.',
      'desc_kniffel':
          'Würfle fünf Würfel bis zu dreimal und fülle deinen Block. Fülle den Block komplett, um zu gewinnen.',
      'desc_phase10':
          'Schließe alle 10 Phasen vor deinen Gegnern ab. Unterstützt Original, Masters und Duell Varianten.',
      'desc_darts':
          'Klassisches 301, 501, 701 oder 1001 Darts Scoring. Checkout mit Double.',
      'desc_romme':
          'Punktebasierter Kartenspurbetreuer für mehrere Runden. Die niedrigste Punktzahl gewinnt.',
      'desc_arschloch':
          'Präsidenten-Kartenspiel. Werde als Erster alle deine Karten los, um Präsident zu werden.',
      'desc_sipdeck':
          'Party-Kartenspiel für Erwachsene (18+). 50+ Herausforderungen in fünf Kategorien.',

      // ── Players
      'players': 'Spieler',
      'no_players': 'Noch keine Spieler. Füge deinen ersten Spieler hinzu!',
      'add_player': 'Spieler hinzufügen',
      'player_name': 'Spielername',
      'edit_player': 'Spieler bearbeiten',
      'name_required': 'Name ist erforderlich',
      'players_add_success': 'Spieler {0} hinzugefügt',
      'players_delete_confirm': 'Spieler {0} löschen?',

      // ── Games list
      'games_title': 'Spiele',
      'games_subtitle': 'Wähle ein Spiel aus',

      // ── Game names & descriptions
      'game_wizard': 'Wizard',
      'game_wizard_desc':
          'Das klassische Stichkartenspiel. Biete deine Stiche, übertrumpfe deine Rivalen. Standard-, Lenient- & Extreme-Varianten.',
      'game_qwixx': 'Qwixx',
      'game_qwixx_desc':
          'Streiche Zahlen in vier farbigen Reihen durch, bevor es jemand anderes tut. Jedes Kreuz zählt!',
      'game_schafkopf': 'Schafkopf',
      'game_schafkopf_desc':
          'Traditioneller bayerischer Kartenspiel-Tracker. Unterstützt Sauspiel, Solo, Wenz und alle Varianten mit vollständiger Auszahlungsberechnung.',
      'game_kniffel': 'Kniffel',
      'game_kniffel_desc':
          'Würfle bis zu dreimal mit fünf Würfeln und fülle deinen Spielzettel aus. Triff Kniffel für den Jackpot!',
      'game_phase10': 'Phase 10',
      'game_phase10_desc':
          'Schließe alle 10 Phasen ab, bevor es jemand anderes tut. Verfolge deine aktuelle Phase und Strafpunkte.',
      'game_darts': 'Darts X01',
      'game_darts_desc':
          'Klassisches X01-Darts-Scoring. Unterstützt 301, 501, 701 und 1001. Checkout auf Doppel.',
      'game_romme': 'Rommé',
      'game_romme_desc':
          'Punktebasierter Rommé-Tracker. Wer nach allen Runden die wenigsten Punkte hat, gewinnt.',

      'game_sipdeck': 'SipDeck',
      'game_sipdeck_desc':
          'Partykartenspiel für Erwachsene (18+). 50+ Challenges, Aufgaben & Regeln über 5 Kategorien.',

      'game_arschloch': 'Arschloch / Präsident',
      'game_arschloch_desc':
          'Das klassische Präsidenten-Kartenspiel. Werde zuerst alle Karten los. Ränge, Kartentausch und kumulative Punkte über mehrere Runden.',

      // ── Help screen (added for in-app help feature)
      'help_title': 'Hilfe & Feedback',
      'help_docs': 'NexScore Dokumentation',
      'help_docs_desc':
          'Spielregeln, Einrichtungsanleitungen und Feature-Dokumentation.',
      'help_bug': 'Fehler melden',
      'help_bug_desc': 'Einen Fehler gefunden? Melde ihn über GitHub Issues.',
      'help_feature': 'Feature anfragen',
      'help_feature_desc': 'Eine Idee? Sende einen Feature-Request auf GitHub.',
      'help_discuss': 'Community-Diskussionen',
      'help_discuss_desc':
          'Stell Fragen und chatte mit anderen NexScore-Nutzern.',
      'help_source': 'Quellcode',
      'help_source_desc': 'NexScore ist Open Source auf GitHub.',
      'help_settings': 'App-Einstellungen',

      // ── Wizard
      'wizard_title': 'Wizard',
      'wizard_round': 'Runde',
      'wizard_next_round': 'Runde {0} eingeben',
      'wizard_bid': 'Gebot',
      'wizard_predictions': 'Ansagen',
      'wizard_actuals': 'Ergebnisse',
      'wizard_won': 'Gewonnen',
      'wizard_save_round': 'Runde speichern',
      'wizard_start_round': 'Bei Runde starten',
      'wizard_end_game': 'Spiel beenden',
      'wizard_end_game_confirm':
          'Bist du sicher, dass du das Spiel vorzeitig beenden willst?',
      'wizard_error_tricks':
          'Stichsumme ({0}) muss der Rundenzahl ({1}) entsprechen.',
      'wizard_bombs': 'Gespielte Bomben',
      'wizard_error_tricks_extreme':
          'Summe der gewonnenen Stiche ({0}) + Bomben ({1}) muss der Rundenzahl ({2}) entsprechen.',
      'wizard_history': 'Rundenverlauf ({0} Runden)',
      'wizard_scoring_standard': 'Standard – richtiges Gebot = +20 + Stiche×10',
      'wizard_scoring_lenient':
          'Lenient – Stiche werden mit Geboten verrechnet',
      'wizard_scoring_extreme':
          'Extreme – nur exaktes Gebot, falsch = ‑2× Stiche',
      'wizard_rule_stiche': 'Stiche dürfen nicht aufgehen',
      'wizard_rule_stiche_desc':
          'Der letzte Spieler kann keinen Gleichstand erzwingen.',
      'wizard_2player_warning':
          'Hinweis: Amigo unterstützt Wizard mit nur 2 Spielern offiziell nicht.',
      'game_no_players': 'Keine Spieler ausgewählt.',
      'game_setup_title': 'Spiel-Setup',
      'game_setup_choose_players': 'Wähle Spieler für {0}',
      'game_setup_start': 'Spiel starten',
      'game_setup_min_players': 'Bitte wähle mindestens {0} Spieler aus.',

      // ── Schafkopf
      'schafkopf_title': 'Schafkopf',
      'schafkopf_payouts': 'Gesamtauszahlung (€)',
      'schafkopf_no_rounds': 'Noch keine Runden. Füge die erste Runde hinzu!',
      'schafkopf_game_type': 'Spieltyp',
      'schafkopf_active_player': 'Aktiver Spieler (Spieler)',
      'schafkopf_partner': 'Partner (Mitspieler)',
      'schafkopf_active_won': 'Aktiver Spieler gewonnen?',
      'schafkopf_schneider': 'Schneider',
      'schafkopf_schwarz': 'Schwarz',
      'schafkopf_runners': 'Laufende',
      'schafkopf_runners_warning':
          '⚠ Laufende zählen erst ab ≥3 (offizielle bayerische Regel)',
      'schafkopf_base_tariff': 'Basistarif (€)',
      'schafkopf_undo': 'Letzte Runde entfernen',
      'schafkopf_runners_count': '{0}× Laufende',
      'schafkopf_requires_4': 'Schafkopf benötigt genau 4 Spieler.',
      'schafkopf_gt_sauspiel': 'Sauspiel',
      'schafkopf_gt_wenz': 'Wenz',
      'schafkopf_gt_solo': 'Solo',
      'schafkopf_gt_tout': 'Tout',
      'schafkopf_won': 'Gewonnen',
      'schafkopf_lost': 'Verloren',

      // ── Arschloch
      'arschloch_title': 'Arschloch / Präsident',
      'arschloch_rank_president': 'Präsident',
      'arschloch_rank_vice_president': 'Vizepräsident',
      'arschloch_rank_neutral': 'Bürger',
      'arschloch_rank_vice_arschloch': 'Vize-Arschloch',
      'arschloch_rank_arschloch': 'Arschloch',
      'arschloch_rounds': 'Runden: Präs {0} | Arsch {1}',
      'arschloch_exchange_title': 'Kartentausch für nächste Runde:',
      'arschloch_exchange_p_to_a':
          '{0} gibt 2 beste Karten an {1} (Arschloch → Präsident)',
      'arschloch_exchange_a_to_p': '{0} gibt 2 niedrigste Karten zurück',
      'arschloch_exchange_vp_to_vpa': '{0} gibt 1 beste Karte an {1}',
      'arschloch_rules': 'Regeln',
      'arschloch_finish_order': 'Reihenfolge',
      'arschloch_ranked': 'Platziert:',
      'arschloch_tap_to_rank': 'Tippe zum Platzieren:',
      'arschloch_min_3_players': '⚠ Arschloch benötigt mindestens 3 Spieler.',
      'arschloch_goal': 'Ziel',
      'arschloch_goal_desc':
          'Als Erster alle Karten ablegen → Präsident. Letzter mit Karten = Arschloch.',
      'arschloch_ranks_desc':
          '1. Präsident | 2. Vizepräsident | Mitte: Bürger | Vorletzter: Vize-Arschloch | Letzter: Arschloch',
      'arschloch_rules_exchange_p':
          'Arschloch gibt 2 beste Karten an Präsidenten. Präsident gibt 2 Karten zurück.',
      'arschloch_rules_exchange_vp':
          'Vize-Arschloch gibt 1 beste Karte an Vizepräsidenten (≥5 Spieler).',
      'arschloch_rules_special': 'Sonderregeln',
      'arschloch_rules_2_high': '• 2 ist die höchste Karte.',
      'arschloch_rules_bomb': '• Bombe: Vierling schlägt alles.',
      'arschloch_rules_passing': '• Passen ist jederzeit erlaubt.',

      // ── Kniffel
      'kniffel_title': 'Kniffel',
      'kniffel_upper': 'Oberer Abschnitt',
      'kniffel_lower': 'Unterer Abschnitt',
      'kniffel_bonus': 'Bonus (63+)',
      'kniffel_total': 'Gesamt',
      'kniffel_cat_aces': 'Einser',
      'kniffel_cat_twos': 'Zweier',
      'kniffel_cat_threes': 'Dreier',
      'kniffel_cat_fours': 'Vierer',
      'kniffel_cat_fives': 'Fünfer',
      'kniffel_cat_sixes': 'Sechser',
      'kniffel_cat_3ofakind': 'Dreierpasch',
      'kniffel_cat_4ofakind': 'Viererpasch',
      'kniffel_cat_fullhouse': 'Full House (25)',
      'kniffel_cat_smstraight': 'Kleine Straße (30)',
      'kniffel_cat_lgstraight': 'Große Straße (40)',
      'kniffel_cat_yahtzee': 'Kniffel (50)',
      'kniffel_cat_chance': 'Chance',
      'kniffel_enter_score': 'Punkte eingeben für {0}',

      // ── Darts
      'darts_title': 'Darts (X01)',
      'darts_target': 'Darts ({0})',
      'darts_avg': 'Schnitt: {0}',
      'darts_thrown': 'Darts geworfen: {0}',
      'darts_bust': 'Bust',
      'darts_enter_score': 'Score für {0}',
      'darts_input_desc': 'Gesamtpunktzahl von 3 Darts eingeben',

      // ── Phase 10
      'phase10_variant': 'Phase 10 Variante',
      'phase10_original': 'Original',
      'phase10_masters': 'Masters',
      'phase10_duel': 'Duell',
      'phase10_phase': 'Phase',
      'phase10_legend_tap': 'Für Phasenbeschreibungen tippen',
      'phase10_penalty': 'Strafpunkte',
      'phase10_penalty_desc':
          'Karten auf der Hand (Zahlen = Wert, Joker = 25, Aussetzen = 15)',
      'phase10_done': 'Erledigt: {0}',
      'phase10_pick_phase': 'Nächste Phase wählen',
      'phase10_legend_title': 'Phasenbeschreibungen',
      'phase10_v_desc_original':
          'Original – Phasen 1–10 in der Reihenfolge abschließen',
      'phase10_v_desc_masters':
          'Masters – jede Runde eine beliebige Phase wählen',
      'phase10_v_desc_duel': 'Duell (2 Spieler) – Phasen taktisch wählen',
      'phase10_p1_title': 'Phase 1', 'phase10_p1_desc': '2 Drillinge',
      'phase10_p2_title': 'Phase 2',
      'phase10_p2_desc': '1 Drilling + 1 Viererfolge',
      'phase10_p3_title': 'Phase 3',
      'phase10_p3_desc': '1 Vierling + 1 Viererfolge',
      'phase10_p4_title': 'Phase 4', 'phase10_p4_desc': '1 Siebenerfolge',
      'phase10_p5_title': 'Phase 5', 'phase10_p5_desc': '1 Achterfolge',
      'phase10_p6_title': 'Phase 6', 'phase10_p6_desc': '1 Neunerfolge',
      'phase10_p7_title': 'Phase 7', 'phase10_p7_desc': '2 Vierlinge',
      'phase10_p8_title': 'Phase 8', 'phase10_p8_desc': '7 Karten einer Farbe',
      'phase10_p9_title': 'Phase 9',
      'phase10_p9_desc': '1 Fünfling + 1 Zwilling',
      'phase10_p10_title': 'Phase 10',
      'phase10_p10_desc': '1 Fünfling + 1 Drilling',

      // ── Rommé
      'romme_title': 'Rommé',
      'romme_round': 'Runde',
      'romme_no_rounds': 'Noch keine Runden. Tippe auf + zum Hinzufügen.',
      'romme_leader': 'Führender: {0}',
      'romme_penalty_title': 'Runde {0} – Strafpunkte eingeben',

      // ── History
      'history': 'Verlauf',
      'history_empty': 'Noch keine abgeschlossenen Spiele. Fang an zu spielen!',
      'history_share': 'Ergebnis teilen',
      'history_completed': 'Abgeschlossen',
      'history_duration': 'Dauer',
      'history_players': 'Spieler',
      'history_share_tooltip': 'Ergebnis teilen',
      'history_copied': 'Ergebnis in die Zwischenablage kopiert!',
      'history_pts': 'Pkt',
      'history_no_sessions': 'Noch keine abgeschlossenen Spiele.',

      // ── Leaderboard
      'leaderboard_title': 'Rangliste',
      'leaderboard_empty':
          'Noch kein Spielverlauf. Spiele ein paar Spiele, um die Rangliste zu sehen!',
      'leaderboard_wins': 'S',
      'leaderboard_games': 'Spiele',
      'leaderboard_win_rate': 'Gewinnrate',
      'leaderboard_score': 'Punkte',

      // ── SipDeck
      'sipdeck_title': 'SipDeck',
      'sipdeck_ready': 'Bereit zum Spielen?',
      'sipdeck_players_ready': '{0} Spieler bereit',
      'sipdeck_start': 'SPIEL STARTEN',
      'sipdeck_tap_continue': 'Tippe irgendwo für die nächste Karte',
      'sipdeck_sips': '{0} Schlücke',
      'sipdeck_categories': 'Kategorien',
      'sipdeck_select_modes': 'Welche Modi möchtest du spielen?',
      'sipdeck_no_players': 'Füge zuerst Spieler hinzu, um SipDeck zu spielen.',
      'sipdeck_18_warning': 'Ab 18 Jahren freigegeben.',
      'sipdeck_2player_warning':
          'SipDeck macht am meisten Spaß mit 3 oder mehr Spielern!',
      'sipdeck_cat_warmUp': 'Warm Up',
      'sipdeck_cat_wildCards': 'Wild Cards',
      'sipdeck_cat_flirty': 'Flirt (18+)',
      'sipdeck_cat_barNight': 'Bier-Abend',
      'sipdeck_cat_laughs': 'Lachen',

      // ── Account / Auth
      'account_title': 'Konto',
      'account_signed_out_title': 'Anmelden zum Synchronisieren',
      'account_signed_out_body':
          'Melde dich an, um deine Spielhistorie auf allen Geräten zu sichern und zu synchronisieren. Wir unterstützen Google Cloud und GitHub Gist.',
      'account_offline_note':
          'NexScore funktioniert vollständig offline ohne Konto.',
      'account_sign_in_google': 'Mit Google anmelden',
      'account_sign_in_github': 'Mit GitHub anmelden (Gist)',
      'account_sync_active': 'Sync aktiv',
      'account_sync_github': 'Gist Sync aktiv',
      'account_sign_out': 'Abmelden',
      'account_sign_in_error': 'Anmeldung fehlgeschlagen: {0}',
      'account_data_stay_note':
          'Deine lokalen Daten bleiben auf diesem Gerät gespeichert, wenn du dich abmeldest.',
      'error_name_taken': 'Ein Spieler mit diesem Namen existiert bereits.',

      // ── SipDeck Cards (DE)
      'sd_card_w001':
          '🔵 {0}, nenne drei Dinge, die du siehst und die blau sind. Vergessen? Trinke 2 Schlücke.',
      'sd_card_w001_expl':
          'Schau dich um und nenne 3 blaue Objekte. Wenn du keine findest oder stotterst, trinke die Strafe.',
      'sd_card_w002':
          '🌊 Wasserfall! {0} beginnt. Alle folgen. Hör erst auf, wenn die Person links von dir aufhört.',
      'sd_card_w002_expl':
          'Alle fangen gleichzeitig an zu trinken. Du darfst erst absetzen, wenn dein rechter Nachbar aufhört. {0} darf als Erster entscheiden, wann er stoppt.',
      'sd_card_w003':
          '🗣️ {0} gibt {1} ein Kompliment. {1} muss in einer erfundenen Sprache antworten. Vergessen? Trinke 3 Schlücke.',
      'sd_card_w003_expl':
          '{0} sagt etwas Nettes. {1} muss mit Kauderwelsch antworten. Benutzt {1} echte Wörter, muss {1} 3 Schlücke trinken.',
      'sd_card_w004':
          '🧟 Abstimmung: Wer würde eine Zombie-Apokalypse überleben? Wenigste Stimmen = 2 Schlücke.',
      'sd_card_w004_expl':
          'Auf drei zeigt jeder auf die Person, die er für am fähigsten hält. Der "Verlierer" mit den wenigsten Stimmen trinkt.',
      'sd_card_w005':
          '🐘 {0}, nenne in 10 Sekunden 5 Tiere. Jedes fehlende Tier = 1 Schluck.',
      'sd_card_w005_expl':
          'Schnell! Nenne 5 Tiere, bevor die Gruppe bis 10 gezählt hat. Trinke für jedes Tier, das du nicht geschafft hast.',
      'sd_card_w006':
          '👍 Daumencatchen! {0} gegen {1}. Verlierer trinkt 2 Schlücke.',
      'sd_card_w006_expl':
          'Der Klassiker. Finger verhaken und den Daumen des Gegners für 3 Sekunden runterdrücken, um zu gewinnen.',
      'sd_card_w007': '🧦 Alle, die Socken tragen, trinken 1 Schluck.',
      'sd_card_w007_expl': 'Socken an? Trinken. Barfuß? Du bist sicher.',
      'sd_card_w008':
          '🎭 {0}, mache deine beste Promi-Imitation. Schlecht? Trinke 3 Schlucke.',
      'sd_card_w008_expl':
          'Ahme eine bekannte Person nach. Die Gruppe entscheidet, ob es erkennbar war. Wenn nicht, trinke.',
      'sd_card_w009':
          '🤫 Noch nie habe ich: {0} beginnt. Einmal die Runde herum.',
      'sd_card_w009_expl':
          '{0} nennt eine Sache, die er/sie noch nie getan hat. Jeder, der es SCHON getan hat, muss einen Schluck trinken.',
      'sd_card_w010':
          '👁️ {0} und {1}: Starre-Wettbewerb. Wer zuerst blinzelt, trinkt 2 Schlücke.',
      'sd_card_w010_expl':
          'Schaut euch tief in die Augen. Blinzeln verboten! Wer zuerst blinzelt oder wegschaut, trinkt 2.',
      'sd_card_w011':
          '✂️ Schere-Stein-Papier-Turnier. Der Letzte trinkt 3 Schlücke.',
      'sd_card_w011_expl':
          'Spielt RPS in Runden. Der absolute Verlierer der ganzen Gruppe muss 3 Schlücke trinken.',
      'sd_card_w012':
          '👥 {0}, ahme die Person links von dir für die nächsten 2 Minuten nach. Vergessen? Trinke 2 Schlücke.',
      'sd_card_w012_expl':
          'Du bist jetzt ein Schatten. Kopiere Gestik und Sprache deines Nachbarn. Wenn du aus der Rolle fällst, trinke 2.',
      'sd_card_w013':
          '🗣️ Abstimmung: Wer redet am meisten? Diese Person trinkt 2 Schlücke.',
      'sd_card_w013_expl':
          'Die Gruppe identifiziert die Plaudertasche. Diese glückliche Person nimmt 2 Schlücke.',
      'sd_card_wc001':
          '🏴‍☠️ {0} muss für die nächsten 3 Runden wie ein Pirat sprechen, oder 4 Schlücke trinken.',
      'sd_card_wc001_expl':
          'Nutze "Arrr", "Ahoi" und Piraten-Slang. Wenn du vor Ablauf der 3 Runden normal sprichst, trinke 4.',
      'sd_card_wc002':
          '⚖️ Regel erstellen! {0} denkt sich eine Regel aus, die für diese Runde gilt. Bruch? 2 Schlucke.',
      'sd_card_wc002_expl':
          'Erfinde etwas Verrücktes (z.B. keine Namen benutzen). Jeder, der die Regel bricht, trinkt 2.',
      'sd_card_wc003':
          '🏷️ {0}, du hast einen neuen Namen: "{1}". Wer deinen echten Namen benutzt, trinkt 1 Schluck.',
      'sd_card_wc003_expl':
          '{0} heißt ab jetzt "{1}". Wenn jemand den echten Namen benutzt, muss er zur Strafe einen Schluck trinken.',
      'sd_card_wc004':
          '🎯 {0} verteilt jeweils einen Schluck an drei verschiedene Personen. Keine Fragen erlaubt.',
      'sd_card_wc004_expl':
          'Du bist der Schluck-Meister. Wähle 3 Personen aus, die jeweils 1 Schluck trinken müssen.',
      'sd_card_wc005':
          '💪 CHALLENGE: {0} macht 10 Hampelmänner oder trinkt 5 Schlucke.',
      'sd_card_wc005_expl':
          'Kalorien verbrennen! Mache 10 saubere Hampelmänner oder gib auf und trinke stattdessen 5.',
      'sd_card_wc006':
          '📞 Stille Post! {0} flüstert einen Satz. Falsch am Ende? Trinke 3 Schlucke.',
      'sd_card_wc006_expl':
          'Flüstere einen geheimen Satz herum. Wenn er am Ende völlig entstellt ankommt, trinken alle (oder der Schuldige) 3.',
      'sd_card_wc007':
          '📱 Alle am Handy: Screenshot von der letzten Suche zeigen. Am peinlichsten? Trinke 3 Schlucke.',
      'sd_card_wc007_expl':
          'Zeigt euren Browserverlauf. Die Gruppe bestimmt die peinlichste Suche. Diese Person trinkt.',
      'sd_card_wc008':
          '😂 {0}, jedes Mal wenn du in den nächsten 5 Minuten lachst, trinke 1 Schluck.',
      'sd_card_wc008_expl':
          'Bleib ernst! Jedes Kichern oder Lachen kostet dich 1 Schluck. Viel Glück beim Pokerface.',
      'sd_card_wc009':
          '✨ VIRUS GEHEILT: Die aktive Regel endet. Alle anderen trinken 1 Schluck zur Feier.',
      'sd_card_wc009_expl':
          'Alle aktiven Viren/Regeln sind aufgehoben! Die Gruppe trinkt einen Schluck zur Feier.',
      'sd_card_wc010':
          '🎨 {0} zeichnet ein Porträt von {1}, ohne auf das Papier zu schauen. Schlechteste Zeichnung? Trinke 3.',
      'sd_card_wc010_expl':
          'Stift aufs Papier, Augen nur auf {1}. Zeichne! Die Gruppe bewertet das "Meisterwerk". Trinke 3, falls es ein Desaster ist.',
      'sd_card_wc011':
          '🤸 Gruppen-Challenge: Planken! Wer zuletzt aufgibt, darf 5 Schlucke verteilen.',
      'sd_card_wc011_expl':
          'Alle auf den Boden! Wer am längsten plankt, darf 5 Schlucke an die anderen verteilen.',
      'sd_card_f001':
          '{0}, mache {1} ein echtes Kompliment über den Style. Wenn du rot wirst, trinke 2 Schlucke.',
      'sd_card_f002':
          '{0} und {1} haben 30 Sekunden Zeit, eine Gemeinsamkeit zu finden. Scheitern? Beide 3 Schlucke.',
      'sd_card_f003':
          '{0}, schreibe dem letzten Kontakt ein Herz-Emoji. Verweigern? Trinke 2 Schlucke.',
      'sd_card_f004':
          'Abstimmung: Schönstes Lächeln im Raum. Diese Person darf 3 Schlucke verteilen.',
      'sd_card_f005':
          '{0}, beschreibe deinen Schwarm, ohne den Namen zu nennen. Die Gruppe rät.',
      'sd_card_f006':
          'Wahrheit: {0}, bewerte jede Person von 1–10. Verweigern? Trinke 4 Schlucke.',
      'sd_card_f007':
          'Jeder schreibt ein Ein-Wort-Kompliment für {0}. {0} rät, von wem es ist. Falsch? 1 Schluck jeweils.',
      'sd_card_b001':
          '{0} beginnt einen Trinkspruch. Jeder fügt einen Satz hinzu. Fehler? Trinke 2 Schlucke.',
      'sd_card_b002':
          'Rate den Preis des teuersten Getränks hier. Am weitesten weg? Trinke 2 Schlucke.',
      'sd_card_b003':
          'Alle bestellen etwas, das sie noch nie probiert haben, oder trinken 2 Schlucke.',
      'sd_card_b004':
          '{0} muss diese Runde "Prost" in 3 Sprachen sagen. Pro fehlender Sprache 1 Schluck.',
      'sd_card_b005':
          'Alle stehen auf und tauschen Sitzplätze. Der Letzte trinkt 2 Schlucke.',
      'sd_card_b006':
          '{0}, rede für mindestens 1 Minute mit einem Fremden. Scheitern? Trinke 4 Schlucke.',
      'sd_card_l001':
          '{0}, watschele wie ein Pinguin ans andere Ende des Raums und zurück.',
      'sd_card_l002':
          'VIRUS: {0} muss die nächsten 5 Karten jeden Satz mit "und das ist Tee-Zeit" beenden. Vergessen? 2 Schlucke.',
      'sd_card_l003':
          '{0}, kommentiere das aktuelle Geschehen für 60s wie eine Naturdokumentation.',
      'sd_card_l004':
          'Alle sagen gleichzeitig das lustigste Wort, das sie kennen. Bestes Wort darf 2 Schlucke verteilen.',
      'sd_card_l005':
          '{0} darf für die nächsten 2 Minuten nur Fragen stellen. Aussage getätigt? 1 Schluck.',
      'sd_card_l006':
          '{0}, erkläre deinen Job nur mit Handbewegungen. Keiner rät nach 30s? Trinke 3 Schlucke.',
      'sd_card_l007':
          '{0}, erfinde ein neues Wort und nutze es überzeugend. Die Gruppe stimmt ab.',
      'sd_card_l008':
          'Schnellrunde: Nenne einen Film, ein Lied und eine Stadt mit dem Anfangsbuchstaben, den die Person links wählt.',
      'sd_card_l009':
          '{0}, sprich für die nächsten 3 Runden in Zeitlupe oder trinke 3 Schlucke.',
    },
  };

  String get(String key) {
    final langCode = locale.languageCode;
    final langMap = localizedValues[langCode] ?? localizedValues['en']!;
    return langMap[key] ?? localizedValues['en']![key] ?? key;
  }

  /// Interpolates positional args {0}, {1}, … into a localized string.
  String getWith(String key, List<String> args) {
    String value = get(key);
    for (int i = 0; i < args.length; i++) {
      value = value.replaceAll('{$i}', args[i]);
    }
    return value;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.localizedValues.containsKey(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
