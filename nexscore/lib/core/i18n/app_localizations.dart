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

      // ── Drink Intensity
      'drink_intensity_title': 'Drink Intensity',
      'drink_intensity_chill': 'Chill',
      'drink_intensity_normal': 'Normal',
      'drink_intensity_extreme': 'Extreme',
      'drink_intensity_custom': 'Custom',
      'drink_intensity_subtitle':
          'Adjust the multiplier for sipping challenges',
      'drink_intensity_custom_slider': '{0}x',
      'mode_sips_adjusted': '[{0} Mode: {1} Sips]',
      'mode_sips_adjusted_1': '[{0} Mode: {1} Sip]',

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
      'qwixx_variant_original': 'Original',

      // ── Home / Games List
      'home_choose_game': 'Choose a Game',
      'home_search_games': 'Search games...',
      'home_filter_all': 'All',
      'home_tag_card': 'Card Game',
      'home_tag_dice': 'Dice Game',
      'home_tag_board': 'Board Game',
      'home_tag_sport': 'Sport',
      'home_tag_party': 'Drinking Game',

      'settings_language': 'Language',
      'settings_language_en': 'English',
      'settings_language_de': 'German',
      'settings_tts': 'Text-To-Speech',
      'settings_tts_desc': 'Play audio for cards in SipDeck and BuzzTap.',
      'settings_sfx': 'Sound Effects',
      'settings_sfx_desc': 'Play sounds for clicks, swipes, and wins.',
      'settings_host_name': 'Host Name',
      'tts_toggle': 'Toggle Text-To-Speech',
      'tts_active': 'TTS Active',
      'tts_inactive': 'TTS Inactive',
      'settings_data': 'Data Management',
      'settings_db_reset': 'Reset Database',
      'settings_db_reset_confirm':
          'Are you sure? All players, history and leaderboards will be permanently deleted.',
      'settings_db_reset_success': 'Database has been reset.',
      'game_reset': 'Reset Game',
      'game_reset_confirm':
          'Are you sure you want to reset the current game? All progress will be lost.',
      'game_drink_single': '{0} Drinks',
      'game_drink_everyone': 'Everyone Drinks!',
      'game_skip': 'Skip',
      'game_show_winner': 'Show Winner',
      'game_undo': 'Undo',
      'back': 'Back',

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
      'desc_buzztap': 'Dynamic challenges and drinking prompts for your party.',

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
      'game_buzztap': 'BuzzTap',
      'game_settings': 'Game Settings',
      'winner': 'Winner',
      'home_tag_ext': 'Extra',

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
      'help_multiplayer': 'Multiplayer Guide',
      'help_multiplayer_desc': 'Learn how to host and join games with friends.',
      'settings_pwa_install': 'Install NexScore',
      'settings_pwa_install_desc':
          'Install NexScore on your home screen for a better experience and offline access.',
      'settings_pwa_guide_title': 'Installation Guide',
      'settings_pwa_guide_msg':
          'Your device or browser doesn\'t support automatic installation. You can still add NexScore to your home screen manually:',
      'settings_pwa_guide_ios':
          'Safari: Tap the Share button [icon] and then "Add to Home Screen".',
      'settings_pwa_guide_android':
          'Chrome: Tap the menu button (three dots) and then "Install App".',
      'settings_pwa_guide_windows':
          'Edge/Chrome: Tap the Install icon in the address bar or the "..." menu and then "Install NexScore".',
      'multiplayer_firebase_missing': 'Firebase not configured',
      'multiplayer_firebase_missing_desc':
          'Multiplayer requires Firebase. Please configure environment variables or secrets.',
      'multiplayer': 'Multiplayer',
      'multiplayer_hub': 'Multiplayer Hub',
      'multiplayer_host': 'Host a Room',
      'multiplayer_join': 'Join a Room',
      'multiplayer_room_code': 'Room Code',
      'multiplayer_diagnostics': 'Multiplayer Diagnostics',
      'settings_presets': 'Player Groups',
      'presets_save': 'Save as Group',
      'presets_load': 'Load Group',
      'presets_name': 'Group Name',
      'presets_delete': 'Delete Group',
      'presets_empty': 'No groups saved yet.',
      'presets_save_success': 'Group saved successfully.',
      'presets_save_error': 'Failed to save group.',
      'presets_load_confirm':
          'Load this group? (Current players will be replaced)',
      'multiplayer_diagnostics_desc':
          'If you are having trouble connecting, check the following:',
      'multiplayer_auth_title': 'Anonymous Auth',
      'multiplayer_auth_desc':
          'Ensure "Anonymous" authentication is enabled in your Firebase Console.',
      'multiplayer_adblock_title': 'AdBlockers / VPN',
      'multiplayer_adblock_desc':
          'Disable AdBlockers or VPNs that might block "firestore.googleapis.com".',
      'multiplayer_domains_title': 'Authorized Domains',
      'multiplayer_domains_desc':
          'Ensure your current domain is added to Firebase Authorized Domains.',
      'multiplayer_diagnostics_timeout': '• Connection timed out (10s)',
      'multiplayer_lobby_closed': 'Lobby closed.',
      'multiplayer_error_host': 'Error hosting lobby: {0}',

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
      'wizard_total': 'Total',
      'wizard_scoring_lenient': 'Lenient – tricks offset against bids',
      'wizard_scoring_extreme': 'Extreme – correct = +30, wrong = ‒2× penalty',
      'wizard_rule_stiche': 'Stiche dürfen nicht aufgehen',
      'wizard_rule_uneven_error':
          'Tricks cannot exactly match the round count for {0}.',
      'wizard_rule_stiche_desc': 'Last player cannot force a tie.',
      'wizard_2player_warning':
          'Note: Amigo does not officially support Wizard with only 2 players.',
      'game_no_players': 'No players selected.',
      'game_setup_title': 'Game Setup',
      'game_setup_start': 'Start Game',
      'game_setup_choose_players': 'Choose players for {0}',
      'game_setup_min_players': 'Please select at least {0} players.',
      'add_round': 'Add Round',
      'clear': 'Clear',

      // ── Qwixx
      'qwixx_title': 'Qwixx',
      'qwixx_score_label': 'Total Score: {0}',
      'qwixx_red': 'Red',
      'qwixx_yellow': 'Yellow',
      'qwixx_green': 'Green',
      'qwixx_blue': 'Blue',
      'qwixx_penalties': 'Penalties',

      // ── WayQuest
      'game_wayquest': 'WayQuest',
      'wayquest_title': 'WayQuest',
      'wayquest_categories': 'Select Categories',
      'wayquest_cat_deepTalks': 'Deep Talks',
      'wayquest_cat_wouldYouRather': 'Would You Rather',
      'wayquest_cat_roadChallenges': 'Road Challenges',
      'wayquest_cat_hypotheticals': 'Hypotheticals',
      'wayquest_cat_storyStarters': 'Story Starters',
      'wayquest_start': 'START VOYAGE',
      'wayquest_tap_continue': 'Tap for next quest',
      'desc_wayquest':
          'Entertaining questions and challenges for long car rides.',

      // Deep Talks (WQ)
      'wq_card_dt001':
          'If you could go back in time, which moment would you relive?',
      'wq_card_dt002': 'What is a piece of advice that changed your life?',
      'wq_card_dt003': 'What are you most grateful for right now?',
      'wq_card_dt004':
          'If you could have dinner with any historical figure, who would it be?',
      'wq_card_dt005': 'What is your proudest accomplishment so far?',
      'wq_card_dt006': 'What does your "perfect day" look like?',
      'wq_card_dt007':
          'If you could master any skill overnight, what would it be?',
      'wq_card_dt008': 'What is one thing you want to be remembered for?',
      'wq_card_dt009': 'What is the most beautiful place you have ever been?',
      'wq_card_dt010': 'What is a "small thing" that always makes you happy?',

      // Would You Rather (WQ)
      'wq_card_wyr001':
          'Would you rather always have to sing instead of speaking or always have to dance instead of walking?',
      'wq_card_wyr002': 'Would you rather be able to fly or be invisible?',
      'wq_card_wyr003':
          'Would you rather live 100 years in the past or 100 years in the future?',
      'wq_card_wyr004':
          'Would you rather always be 10 minutes late or 20 minutes early?',
      'wq_card_wyr005':
          'Would you rather be the smartest person in the world or the funniest?',
      'wq_card_wyr006':
          'Would you rather explore the deep ocean or outer space?',
      'wq_card_wyr007': 'Would you rather have a giant nose or giant ears?',
      'wq_card_wyr008':
          'Would you rather speak all human languages or speak to animals?',
      'wq_card_wyr009':
          'Would you rather never eat chocolate again or never eat pizza again?',
      'wq_card_wyr010':
          'Would you rather be a famous actor or a famous scientist?',

      // Road Challenges (WQ)
      'wq_card_rc001':
          'First one to spot a yellow car gets to pick the next song!',
      'wq_card_rc002':
          'Everyone: find a license plate that starts with the same letter as your name.',
      'wq_card_rc003':
          'Count how many wind turbines we pass in the next 5 minutes.',
      'wq_card_rc004': 'The next person to see a cow gets to tell a joke.',
      'wq_card_rc005':
          'Alphabet Game! Find words on road signs starting with A, then B, and so on.',
      'wq_card_rc006':
          'Spot a car from a different country/state. Bonus points for far-away ones!',
      'wq_card_rc007': 'First one to see a red bridge wins 10 virtual points.',
      'wq_card_rc008':
          'Everyone: guess how many minutes until the next gas station.',
      'wq_card_rc009':
          'Point out the most interesting-looking tree in the next minute.',
      'wq_card_rc010': 'See if you can spot a cloud that looks like an animal.',

      // Hypotheticals (WQ)
      'wq_card_hyp001':
          'If we were stranded on a desert island, what is the one object we would wish we had brought?',
      'wq_card_hyp002':
          'If you could have any superpower for just one hour, which one would it be?',
      'wq_card_hyp003':
          'If you won the lottery tomorrow, what is the first thing you would buy?',
      'wq_card_hyp004':
          'If you could live in any fictional world (book/movie), which would it be?',
      'wq_card_hyp005':
          'If you could swap lives with anyone for a day, who would it be?',
      'wq_card_hyp006':
          'If you could talk to your 8-year-old self, what would you say?',
      'wq_card_hyp007':
          'If you found a magic lamp, what would be your three wishes?',
      'wq_card_hyp008':
          'If you could invent a new holiday, what would it celebrate?',
      'wq_card_hyp009': 'If animals could talk, which one would be the rudest?',
      'wq_card_hyp010':
          'If you could build a house anywhere, where would it be?',

      // Story Starters (WQ)
      'wq_card_ss001':
          'Once upon a time, in a car driving through a mysterious forest...',
      'wq_card_ss002':
          'Imagine we find a hidden door in the trunk of this car. Where does it lead?',
      'wq_card_ss003':
          'A giant bird suddenly lands on the roof of the car. What happens next?',
      'wq_card_ss004':
          'The radio starts playing a song from the year 3000. What is it about?',
      'wq_card_ss005':
          'We realize that we are actually in a movie. What is the title of our movie?',
      'wq_card_ss006':
          'The car starts talking back to us. What is the first thing it says?',
      'wq_card_ss007':
          'Every time we cross a bridge, we enter a different dimension. Where are we now?',
      'wq_card_ss008':
          'We find a map in the glovebox that leads to a secret treasure. What is it?',
      'wq_card_ss009':
          'A squirrel is following our car on a tiny motorcycle. Why?',
      'wq_card_ss010':
          'Suddenly, everybody in the world can only speak in rhymes. Start!',

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
      'arschloch_min_3_players': 'At least 2 players required (3+ recommended)',
      'arschloch_goal': 'Goal',
      'arschloch_goal_desc':
          'Be the first to shed all cards → President. Last with cards = Asshole.',
      'arschloch_ranks_desc':
          '1. President | 2. Vice-President | Mid: Citizen | 2nd-to-last: Vice-Asshole | Last: Asshole',
      'arschloch_no_rank': 'No Rank',
      'arschloch_rules_exchange_p':
          'Asshole gives 2 best cards to President. President gives 2 cards back.',
      'arschloch_rules_exchange_vp':
          'Vice-Asshole gives 1 best card to Vice-President (≥5 players).',
      'arschloch_rules_special': 'Special Rules',
      'arschloch_rules_2_high': '• 2 is the highest card.',
      'arschloch_rules_bomb': '• Bomb: 4 of a kind beats everything.',
      'arschloch_rules_passing': '• Passing is allowed.',
      'arschloch_2player_warning':
          'Arschloch is best enjoyed with 3 or more players!',

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
      'kniffel_multiple_yahtzee': 'Multiple Yahtzees Bonus (+50)',
      'kniffel_yahtzee_joker': 'Yahtzee Joker used',
      'kniffel_enter_score': 'Enter score for {0}',
      'kniffel_yahtzee_bonus': 'Yahtzee Bonus',
      'kniffel_yahtzee_bonus_desc': '+50 points for multiple Yahtzees',

      // ── Darts
      'darts_title': 'Darts (X01)',
      'darts_target': 'Darts ({0})',
      'darts_avg': 'Avg: {0}',
      'darts_thrown': 'Darts thrown: {0}',
      'darts_bust': 'Bust',
      'darts_enter_score': 'Score for {0}',
      'darts_input_desc': 'Enter each throw (Value & Multiplier)',
      'darts_remaining': 'Remaining',
      'darts_remove_last': 'Remove last throw',
      'darts_checkout_possible': 'Checkout possible!',
      'darts_finish_type': 'Finish Type',
      'darts_start_type': 'Start Type',
      'darts_finish_single': 'Single Out',
      'darts_finish_double': 'Double Out',
      'darts_finish_master': 'Master Out (Double/Treble)',
      'darts_start_straight': 'Straight Start',
      'darts_start_double': 'Double In',
      'darts_start_master': 'Master In',
      'darts_settings': 'Darts Settings',

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
      'phase10_p1_title': 'Phase 1\', \'phase10_p1_desc\': \'2 sets of 3',
      'phase10_p2_title': 'Phase 2',
      'phase10_p2_desc': '1 set of 3 + 1 run of 4',
      'phase10_p3_title': 'Phase 3',
      'phase10_p3_desc': '1 set of 4 + 1 run of 4',
      'phase10_p4_title': 'Phase 4\', \'phase10_p4_desc\': \'1 run of 7',
      'phase10_p5_title': 'Phase 5\', \'phase10_p5_desc\': \'1 run of 8',
      'phase10_p6_title': 'Phase 6\', \'phase10_p6_desc\': \'1 run of 9',
      'phase10_p7_title': 'Phase 7\', \'phase10_p7_desc\': \'2 sets of 4',
      'phase10_p8_title':
          'Phase 8\', \'phase10_p8_desc\': \'7 cards of 1 color',
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
      'romme_breakdown': 'Score Breakdown',
      'romme_total_points': 'Total Points',
      'romme_first_meld': 'First Meld Requirement',
      'romme_hand_romme': 'Hand-Rommé (Finish in one go)',
      'romme_joker_points': 'Joker Points',
      'romme_settings': 'Rommé Settings',
      'romme_hand_romme_desc':
          'Points are doubled when finishing without previous melds.',

      // ── History
      'game_generic': 'Generic Scoreboard',
      'desc_generic': 'A flexible round-based table for any game.',
      'pwa_update_available': 'Update available!',
      'refresh': 'REFRESH',
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
      'sipdeck_tap_continue': 'Tap anywhere for the next card',
      'sipdeck_sips': '{0} Sips',
      'sipdeck_categories': 'Categories',
      'sipdeck_select_modes': 'Which modes do you want to play?',
      'sipdeck_optimize_2players': '2-Player Optimization',
      'sipdeck_optimize_2players_desc':
          'Hide cards that make little sense with only two players.',
      'sipdeck_no_players': 'Add players first to play SipDeck.',
      'sipdeck_filters': 'Task Filters',
      'sipdeck_tag_dare': 'Dares',
      'sipdeck_tag_social': 'Social Interaction',
      'sipdeck_tag_messaging': 'Messaging People',
      'sipdeck_tag_physical': 'Physical Activity',
      'sipdeck_tag_help_title': 'Task Filter Details',
      'sipdeck_tag_help_dare':
          'Dares: Activities where you have to prove yourself or perform specific actions.',
      'sipdeck_tag_help_social':
          'Social: Challenges involving interaction with the group or strangers.',
      'sipdeck_tag_help_messaging':
          'Messaging: Tasks requiring you to send texts or social media messages.',
      'sipdeck_tag_help_physical':
          'Physical: Activities that require physical movement like pushups or jumping.',

      'sipdeck_settings': 'SipDeck Settings',
      'sipdeck_enable_hydration': 'Hydration Cards',
      'sipdeck_enable_hydration_desc':
          'Occasionally inject water breaks into the game.',
      'sipdeck_hydration_card_text':
          '💧 Stay Hydrated! Everyone drinks a big sip of water.',

      // ── BuzzTap
      'buzztap_title': 'BuzzTap',
      'buzztap_cat_warmup': 'Warmup',
      'buzztap_cat_party': 'Party',
      'buzztap_cat_hot': 'Hot',
      'buzztap_cat_extreme': 'Extreme',
      'buzztap_start': 'Let\'s Buzz!',
      'sip_tracker': 'Sips Tracker',
      'sipdeck_18_warning': 'Must be 18+ to play.',
      'sipdeck_2player_warning':
          'SipDeck is best enjoyed with 3 or more players!',
      'buzztap_2player_warning':
          'BuzzTap is best enjoyed with 3 or more players!',
      'sipdeck_cat_warmUp': 'Warm Up',
      'sipdeck_cat_wildCards': 'Wild Cards',
      'sipdeck_cat_flirty': 'Flirty (18+)',
      'sipdeck_cat_barNight': 'Bar Night',
      'sipdeck_cat_laughs': 'Laughs',
      'category_help_title': 'Category Descriptions',
      'buzztap_help_warmup': 'Light icebreakers to get everyone in the mood.',
      'buzztap_help_party': 'General party challenges for everyone.',
      'buzztap_help_hot': 'Daring and flirty tasks (18+).',
      'buzztap_help_extreme': 'Extreme and crazy challenges! Brace yourselves.',
      'sipdeck_help_warmup': 'Easy icebreaker challenges, fun for everyone.',
      'sipdeck_help_wildcards': 'Advanced dares and creative rules.',
      'sipdeck_help_flirty': 'Playful, flirty challenges (18+).',
      'sipdeck_help_barnight': 'Suitable for any public bar setting.',
      'sipdeck_help_laughs': 'Silly and absurd things to do or say.',

      // ── BuzzTap Cards (EN)
      'bt_card_w001':
          '👋 {0}, introduce yourself with a fake stage name. The group chooses if it fits.',
      'bt_card_w002':
          '🍹 Everyone who has a drink in their hand right now takes a sip.',
      'bt_card_w003':
          '📱 {0}, show the group your last saved photo. Embarrassing? 2 sips.',
      'bt_card_w004':
          '👂 {0}, tell a secret about {1}. If {1} denies it, you drink 3.',
      'bt_card_w005': '🕒 Last person to arrive at this party takes 2 sips.',
      'bt_card_p001':
          '🔥 Hot Seat! {0} has 30 seconds to answer any questions from the group. One skip = 1 sip.',
      'bt_card_p002':
          '💃 {0}, show us your best dance move. If nobody joins in, take 3 sips.',
      'bt_card_p003':
          '🎤 Karaoke Time! {0} must sing the chorus of a popular song. Group votes on the quality.',
      'bt_card_p004': '🤫 Quiet Game: The next person to speak takes 3 sips.',
      'bt_card_p005':
          '🍻 Cheers! Everyone chooses a partner and toasts to something they like about them.',
      'bt_card_h001':
          '👀 {0}, who here is the most attractive? That person gives out 3 sips.',
      'bt_card_h002':
          '💋 {0} and {1}, 10 seconds of intense eye contact. First to look away drinks 3.',
      'bt_card_h003':
          '🔞 {0}, what is your weirdest turn-on? Don\'t want to say? Drink 5.',
      'bt_card_h004':
          '💘 {0}, text your ex "I miss you". Refuse? Finish your drink.',
      'bt_card_h005':
          '🖤 Truth or Drink: {0} asks {1} a spicy question. Either {1} answers or drinks 4.',
      'bt_card_e001': '🧨 Shot Time! {0} chooses someone to take a shot with.',
      'bt_card_e002':
          '💀 {0}, let {1} post anything they want on your social media story.',
      'bt_card_e003':
          '🌪️ Swapped! {0} and {1} must swap an item of clothing for the next 3 rounds.',
      'bt_card_e004':
          '🤡 {0}, let the group draw a small mustache on you with a marker.',

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
      'account_guest': 'Guest',
      'account_guest_status': 'Guest Session',
      'account_guest_sync_label': 'Sync inactive (Local only)',
      'account_sign_out': 'Sign Out',
      'account_default_name': 'NexScore User',
      'account_gist_backup_title': 'GitHub Gist Backup',
      'account_gist_backup_desc': 'Backup your data to a private Gist',
      'account_gist_restore_title': 'Restore from Gist',
      'account_gist_restore_desc': 'Download your data from GitHub',
      'account_sign_in_error': 'Sign-in failed: {0}',
      'account_data_stay_note':
          'Your local data remains on this device when you sign out.',
      'account_privacy_info':
          'NexScore is serverless. Data is stored locally or in your private cloud (Firestore/Gist).',
      'account_privacy_link': 'Privacy & Permissions Documentation',
      'error_name_taken': 'A player with this name already exists.',

      'privacy_title': 'Privacy & Permissions',
      'privacy_no_server_title': 'Serverless Architecture',
      'privacy_no_server_body':
          'NexScore does not have a central server. All your data is processed locally on your device or synchronized directly to your authorized cloud providers (Google/GitHub). We never see, sell, or share your data.',
      'privacy_google_title': 'Google Permissions (Firestore)',
      'privacy_google_body':
          'Requested: Basic profile (Email/Name). Used to identify your account and sync your players and game history to Google Cloud Firestore, enabling multi-device support.',
      'privacy_github_title': 'GitHub Permissions (Gists)',
      'privacy_github_body':
          'Requested: Gist scope. Used to create a private backup of your data on your GitHub account. Only Gists created by NexScore are accessed.',

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
      'sd_card_w100': 'Name 3 capital cities in 5 seconds. Fail? 2 sips.',
      'sd_card_w101':
          'Sing the chorus of the last song you listened to, or take 3 sips.',
      'sd_card_w102': 'Anyone wearing something red takes 1 sip(s).',
      'sd_card_w103':
          'Never have I ever lied about my age. If you have, drink.',
      'sd_card_w104':
          'Name 3 car brands before the next person can say "beep". Fail = drink 2.',
      'sd_card_w105': 'If you like pineapple on pizza, take 2 sips proudly.',
      'sd_card_w106': 'Person with the most pets gives out 2 sips.',
      'sd_card_w107':
          'If your hands are cold right now, take a sip to warm up.',
      'sd_card_w108': 'If your phone battery is below 20%, take 2 sips.',
      'sd_card_w109': 'Everyone strictly wearing sneakers, take 1 sip.',
      'sd_card_w110':
          'Point to the person who has traveled the most. They drink 2.',
      'sd_card_w111': 'If you have headphones in your pocket/bag, take a sip.',
      'sd_card_w112': 'Coffee addicts, take 2 sips right now.',
      'sd_card_w113':
          'Name a Netflix show you binged in 2 days. Can\'t? Drink 2.',
      'sd_card_w114': 'The youngest player takes 2 sips.',
      'sd_card_w115': 'The oldest player takes 2 sips.',
      'sd_card_w116': 'Anyone born in an odd-numbered month takes a sip.',
      'sd_card_w117': 'Jump 3 times. If you refuse, drink 2.',
      'sd_card_w118': 'Air guitar for 10 seconds or take 3 sips.',
      'sd_card_w119': 'Clap your hands. Last person to clap takes 2 sips.',
      'sd_card_wc100':
          'Swap drinks with the person to your left until the next round.',
      'sd_card_wc101':
          'You are a ghost! Nobody can talk to you. If they do, they drink 2.',
      'sd_card_wc102': 'Rule: Anyone who points a finger must take 1 sips.',
      'sd_card_wc103':
          'Rule: T-Rex Arms! You cannot fully extend your arms. Break it? Drink 2.',
      'sd_card_wc104': 'Talk like a robot for your next 3 turns, or drink 3.',
      'sd_card_wc105':
          'Rule: Call everyone by their middle name or last name. Fail = drink.',
      'sd_card_wc106': 'Unicorn! The next person to say "yes" drinks 2 sips.',
      'sd_card_wc107':
          'Take a selfie and make it your profile picture for a day. Or drink 5.',
      'sd_card_wc108':
          'Aliens abducted your memory. Ask "Who am I?" exactly 5 times. Fail = drink 3.',
      'sd_card_wc109':
          'Call a random contact and ask for a good joke. Refuse? Drink 4.',
      'sd_card_wc110':
          'Act like a dinosaur until it is your turn again. Or drink 3.',
      'sd_card_wc111': 'Flip a coin. Heads = Give 2 sips, Tails = Take 2 sips.',
      'sd_card_wc112':
          'Everyone must spin around 3 times and sit down. Last one drinks 2.',
      'sd_card_wc113': 'Hold an ice cube until it melts, or take 4 sips.',
      'sd_card_wc114': 'Make up a haiku (5-7-5 syllables). Fail? Drink 3.',
      'sd_card_wc115':
          'Recreate a famous movie scene. If nobody guesses, drink 2.',
      'sd_card_wc116':
          'You can only use your non-dominant hand for drinking. Fail = 1 sip penalty.',
      'sd_card_wc117': 'You are the general. Order 2 people to take 2 sips.',
      'sd_card_wc118':
          'Silent mode. Nobody can speak until someone finishes their current drink.',
      'sd_card_wc119':
          'Free pass! Save this card to skip any future dare or penalty.',
      'sd_card_f100':
          'Who is the best kisser here? If you refuse to guess, drink 4.',
      'sd_card_f101':
          'Stare into the eyes of the person opposite you for 15s. Laugh? Drink 3.',
      'sd_card_f102':
          'Demonstrate your best pickup line. If people cringe, take 3.',
      'sd_card_f103':
          'Tell the group your most embarrassing romantic encounter, or drink 4.',
      'sd_card_f104':
          'Give someone a shoulder massage for 30 seconds. Or drink 3.',
      'sd_card_f105':
          'Let someone else sit on your lap for native 2 turns. Refuse? Drink 4.',
      'sd_card_f106': 'Share your weirdest turn-on. Chicken out? Drink 5.',
      'sd_card_f107': 'Blow a kiss to the cutest person. They give out 2 sips.',
      'sd_card_f108':
          'Never have I ever had a crush on someone in this room. Drink if true.',
      'sd_card_f109':
          'Take a seductive photo. Keep it as wallpaper for 1 hour. Or drink 5.',
      'sd_card_f110':
          'Who is the most likely to have a wild secret life? Point. Majority drinks 2.',
      'sd_card_f111':
          'Show your best modeling face. Group rates 1-10. Less than 5? Drink 3.',
      'sd_card_f112':
          'Eat an imaginary strawberry as suggestively as possible. Or drink 4.',
      'sd_card_f113':
          'Link arms with the person to your left and drink your next drink together.',
      'sd_card_f114':
          'Let the person on your right send a flirty text to someone in your contacts. Or drink 5.',
      'sd_card_f115':
          'Whisper something naughty into the ear of the person on your left.',
      'sd_card_f116':
          'Name one physical trait you find extremely attractive. Or drink 2.',
      'sd_card_f117': 'Do a 10 second sexy dance. Or drink 4.',
      'sd_card_f118': 'Tell us about your best kiss ever. Refuse? Drink 3.',
      'sd_card_f119': 'Confess a minor crush you had in school. Or drink 2.',
      'sd_card_b100': 'Cheers to the bartender! Everyone clinks glasses.',
      'sd_card_b101': 'Whoever went to the bathroom most recently drinks 2.',
      'sd_card_b102': 'Guess the song playing right now. Wrong? Drink 2.',
      'sd_card_b103': 'Anyone who has ice in their drink takes 1 sips.',
      'sd_card_b104': 'If your drink has fruit in it, enjoy 2 bonus sips.',
      'sd_card_b105':
          'Beer drinkers take 2 sips. Cocktail/Wine drinkers take 2.',
      'sd_card_b106': 'Person with the highest tab right now gives out 3 sips.',
      'sd_card_b107': 'Yell "BARTENDER" into your hand. Refuse? Drink 2.',
      'sd_card_b108': 'Anyone wearing a hat/cap drinks 2.',
      'sd_card_b109':
          'If you brought a jacket but aren\'t wearing it, drink 1.',
      'sd_card_b110': 'Name 3 ride-sharing apps. Too slow? Drink 2.',
      'sd_card_b111': 'Last person to eat fast food drinks 2.',
      'sd_card_b112': 'Hold your breath for 15s. Fail = drink 3.',
      'sd_card_b113': 'Everyone drink a sip of water. Hydrate!',
      'sd_card_b114':
          'High-five the person next to you. Slowest pair drinks 2.',
      'sd_card_b115': 'Take a group photo right now! Blurry? Drink 1.',
      'sd_card_b116':
          'Celebrate someone taking a sip loudly. If you don\'t, you drink 2.',
      'sd_card_b117': 'Cash or Card? Minority drinks 2 sips.',
      'sd_card_b118': 'If your drink is almost empty, finish it!',
      'sd_card_b119':
          'Roll an imaginary dice. Everyone except you drinks 2 sips.',
      'sd_card_l100': 'Try to lick your elbow. Fail? That equals 2 sips.',
      'sd_card_l101': 'Talk like Yoda until your next turn. Or drink 3.',
      'sd_card_l102': 'Act like a monkey for 10 seconds. Refuse? Drink 4.',
      'sd_card_l103': 'Balance a spoon on your nose for 5s. Drop it = drink 2.',
      'sd_card_l104':
          'Moo loudly every time someone says your name. Drink 1 if you forget.',
      'sd_card_l105':
          'Describe a shopping trip dramatically. Bore the group = drink 2.',
      'sd_card_l106':
          'Argue passionately about why pizza is awful. Or drink 3.',
      'sd_card_l107': 'Cast a Harry Potter spell on someone. They drink 1.',
      'sd_card_l108':
          'Speak entirely in whispers for 2 rounds. Forget = 2 sips.',
      'sd_card_l109': 'Tell the worst Dad joke you know. No laughs? Drink 2.',
      'sd_card_l110': 'Gently pat the head of the person to your left.',
      'sd_card_l111': 'Read the next card in a dramatic opera voice.',
      'sd_card_l112': 'Crawl on the floor for 10 seconds. Refuse? Drink 4.',
      'sd_card_l113': 'Caw like an eagle before you drink next.',
      'sd_card_l114': 'Make car engine noises for 5 seconds.',
      'sd_card_l115': 'Do the robot dance for 5 seconds. Fail = drink 2.',
      'sd_card_l116': 'Beatbox while someone else drinks their penalty.',
      'sd_card_l117': 'Sit under the table for 1 round. Refuse = drink 3.',
      'sd_card_l118':
          'Pretend to cry intensely about your drink. Group rates. Fail = 3 sips.',
      'sd_card_l119':
          'Strike a superhero pose for exactly 1 minute. Break it = drink 2 sips.',
      'bt_card_w100':
          'Stand up and formally introduce yourself to your beverage. Or drink 2.',
      'bt_card_w101':
          'Roll an imaginary dice. Odd numbers drink 1, Even drink 1.',
      'bt_card_w102': 'Anyone wearing white socks takes 2 sips.',
      'bt_card_w103': 'Name 3 things that are yellow. Fail = 2 sips.',
      'bt_card_w104': 'Cheers! Everyone clinks glasses and takes a sip.',
      'bt_card_w105': 'If your phone is an iPhone, take 1. Androids take 1.',
      'bt_card_w106':
          'Hum a familiar song. If they guess it, they give away 2 sips.',
      'bt_card_w107': 'Whose birthday is next? They drink 3 sips.',
      'bt_card_w108': 'Anyone older than 25 takes 2 sips.',
      'bt_card_w109':
          'Take off one shoe and keep it off for 5 rounds. Refuse = 3 sips.',
      'bt_card_w110': 'Whoever brought a bag/purse tonight drinks 2.',
      'bt_card_w111': 'Anyone wearing glasses or contacts takes 2 sips.',
      'bt_card_w112':
          'Yawn as widely as possible. Anyone who yawns back drinks 2.',
      'bt_card_w113': 'Person with the coldest drink gives out 2 sips.',
      'bt_card_w114': 'Person with the warmest drink takes 2 sips out of pity.',
      'bt_card_w115': 'High five someone. Slowest to react drinks 2.',
      'bt_card_w116':
          'Say "NexScore is the best app" 5 times fast. Stumble = drink 2.',
      'bt_card_w117': 'Point to north. Those who are completely wrong take 2.',
      'bt_card_w118':
          'If you prefer dogs over cats, take 1 sip. Cat lovers take 1.',
      'bt_card_w119': 'Name 3 animated movies. Fail? 2 sips.',
      'bt_card_w120': 'Whoever slept the most tonight takes 2 sips.',
      'bt_card_w121': 'Jog in place for 10 seconds or take 3 sips.',
      'bt_card_w122': 'Name 3 fruits. Hesitate = drink 2.',
      'bt_card_w123': 'Anyone with cash in their wallet takes 2.',
      'bt_card_w124': 'If you drink out of a can, take 2 sips.',
      'bt_card_p100':
          'Group cheers! Everyone stands up, cheers, and takes 1 sips.',
      'bt_card_p101': 'Do a cartwheel (or attempt one). Refuse? Drink 4.',
      'bt_card_p102': 'Start a conga line! Whoever doesn\'t join drinks 3.',
      'bt_card_p103': 'You are the Party King/Queen. Assign 4 sips to anyone.',
      'bt_card_p104':
          'Pretend to inflate a huge balloon until it pops. Or drink 3.',
      'bt_card_p105': 'Everyone poses for a crazy photo. Worst pose drinks 3.',
      'bt_card_p106': 'Rap 4 lines. If they don\'t rhyme, drink 4.',
      'bt_card_p107': 'Name 3 drinking games. Too slow? Take 3 sips.',
      'bt_card_p108': 'Air guitar solo! Best performance gives 3 sips.',
      'bt_card_p109': 'Act out a wildly inappropriate scene. Cringe? Take 4.',
      'bt_card_p110': 'Swap seats with the person to your left.',
      'bt_card_p111':
          'Finish whatever is left in your glass! Or take 5 penalty sips.',
      'bt_card_p112':
          'Roar like a lion at the person opposite you. Laugh? Drink 2.',
      'bt_card_p113': 'Silent library! The loudest breather drinks 2.',
      'bt_card_p114': 'Do 5 push-ups. Can\'t? Drink 3.',
      'bt_card_p115': 'Take off a piece of clothing or drink 4.',
      'bt_card_p116': 'Throw imaginary confetti and yell woo! Drink 1 anyway.',
      'bt_card_p117': 'Anyone who hasn\'t eaten in the last 3 hours drinks 2.',
      'bt_card_p118':
          'The person with the most empty bottles near them drinks 3.',
      'bt_card_p119': 'Chug for 5 seconds!',
      'bt_card_p120': 'Juggle 3 items. Fail immediately = drink 3.',
      'bt_card_p121': 'If you have a band-aid on right now, take 2 sips.',
      'bt_card_p122':
          'You are the hero! Prevent someone from taking their next penalty.',
      'bt_card_p123': 'Talk in a whisper for the next 2 rounds.',
      'bt_card_p124': 'Laugh maniacally for 10 seconds. Refuse = 3 sips.',
      'bt_card_h100':
          'Demonstrate how to kiss on your hand. Boring? Drink 4 sips.',
      'bt_card_h101': 'Show the group your most provocative photo. Or drink 5.',
      'bt_card_h102':
          'Make eye contact with someone and slowly bite your lip. Break? Drink 3.',
      'bt_card_h103': 'Describe your ultimate fantasy in 3 words. Or drink 4.',
      'bt_card_h104': 'Twerk for 10 seconds. If you refuse, finish your drink.',
      'bt_card_h105':
          'Take an ice cube and rub it on your neck. Or take 3 sips.',
      'bt_card_h106':
          'Whisper something incredibly dirty to the person adjacent. Or drink 4.',
      'bt_card_h107':
          'Seductively eat a piece of fruit or air. Fail = drink 3.',
      'bt_card_h108':
          'Give someone a lap dance for 15 seconds. Refuse = 6 sips.',
      'bt_card_h109': 'Name one thing you love in bed. Too silent = drink 5.',
      'bt_card_h110': 'Unbutton an item of clothing. If impossible, drink 4.',
      'bt_card_h111': 'Drink the next 3 sips from the glass of someone else.',
      'bt_card_h112':
          'Lick your lips provocatively every time you hear your name for 2 rounds.',
      'bt_card_h113':
          'Confess who you would hook up with strictly based on looks.',
      'bt_card_h114': 'If you shower naked (obviously), everyone drinks 2.',
      'bt_card_h115': 'Pretend to put lotion on yourself. Awkward? Drink 3.',
      'bt_card_h116': 'Let someone reapply your lipbalm/lipstick. Or drink 3.',
      'bt_card_h117': 'Crawl like a cat for 10 seconds. Refuse = 5 sips.',
      'bt_card_h118':
          'Never have I ever sent a nude. If you have, drink proudly.',
      'bt_card_h119':
          'Take a hot photo of the person opposite you. Or drink 4.',
      'bt_card_h120':
          'Name synonymous words for boobs in 10s. Loser takes 3 sips.',
      'bt_card_h121':
          'Spill a tiny bit of drink on yourself and wipe it seductively. Or drink 3.',
      'bt_card_h122':
          'Show the group your tinder/dating app profile. Or drink 5.',
      'bt_card_h123':
          'Leave a kiss mark on a napkin or back of your hand. Or drink 2.',
      'bt_card_h124':
          'Flash your best seductive smile. Everyone else drinks 1.',
      'bt_card_e100': 'You are cursed! Finish your drink!',
      'bt_card_e101':
          'Spin around 10 times and try to walk in a straight line. Fail = 4 sips.',
      'bt_card_e102': 'Take a shot. Yes, right now.',
      'bt_card_e103':
          'Let the group shave a tiny patch of your hair. Refuse = finish drink.',
      'bt_card_e104':
          'Call your parents and say you are quitting your job/school. Or drink 8.',
      'bt_card_e105':
          'Mix 3 different drinks and take a sip. Or take 6 penalty sips.',
      'bt_card_e106':
          'Everyone votes. The person they hate the most right now drinks 5.',
      'bt_card_e107':
          'Let someone draw on your face with a sharpie. Or drink 8.',
      'bt_card_e108':
          'Put someone else\'s sock in your pocket for the rest of the game.',
      'bt_card_e109': 'Throw your drink in the sink. Refuse? Drink 10.',
      'bt_card_e110': 'Put an ice cube down your pants. Or finish your drink.',
      'bt_card_e111': 'Eat a raw egg. Or drink 8 sips.',
      'bt_card_e112': 'Lick the floor. Yes, the floor. Refuse = 10 sips.',
      'bt_card_e113': 'Venmo/PayPal someone €5. Or drink 5 sips.',
      'bt_card_e114':
          'Delete an app from your phone chosen by the group. Or drink 6.',
      'bt_card_e115': 'Drop your phone on the carpet from 1 meter. Or drink 3.',
      'bt_card_e116': 'Eat a spoonful of hot sauce. Or finish your drink.',
      'bt_card_e117':
          'Arm wrestle the strongest looking person. Loser drinks 5.',
      'bt_card_e118': 'Let someone slap you lightly. Or take 5 sips.',
      'bt_card_e119': 'Wear your shirt backwards for the rest of the game.',
      'bt_card_e120': 'Run outside and yell "I LOVE NEXSCORE". Or drink 7.',
      'bt_card_e121':
          'Stick your head under the faucet/shower. Or finish your drink.',
      'bt_card_e122':
          'Drink water out of your own shoe. Disgusting? Then drink 10.',
      'bt_card_e123':
          'Roast every single person in the room brutally. Fail = drink 5.',
      'bt_card_e124': 'Everyone finish their drinks immediately!!',

      // ── Resume
      'resume_game_title': 'Resume Game',
      'resume_game_desc': 'Would you like to resume your unfinished {0} game?',
      'resume': 'Resume',
      'discard': 'Discard',
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

      // ── Drink Intensity
      'drink_intensity_title': 'Trink-Intensität',
      'drink_intensity_chill': 'Gemütlich',
      'drink_intensity_normal': 'Normal',
      'drink_intensity_extreme': 'Extrem',
      'drink_intensity_custom': 'Benutzerdefiniert',
      'drink_intensity_subtitle': 'Multiplikator für Trink-Aufgaben anpassen',
      'drink_intensity_custom_slider': '{0}x',
      'mode_sips_adjusted': '[{0}-Modus: {1} Schlücke]',
      'mode_sips_adjusted_1': '[{0}-Modus: {1} Schluck]',

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
      'game_reset': 'Spiel zurücksetzen',
      'game_reset_confirm':
          'Bist du sicher, dass du das aktuelle Spiel zurücksetzen möchtest? Alle Fortschritte gehen verloren.',
      'game_drink_single': '{0} trinkt',
      'game_drink_everyone': 'Alle trinken!',
      'game_skip': 'Überspringen',
      'game_show_winner': 'Gewinner anzeigen',
      'game_undo': 'Rückgängig',
      'settings_language': 'Sprache',
      'settings_language_en': 'Englisch',
      'settings_language_de': 'Deutsch',
      'settings_tts': 'Vorlesen (TTS)',
      'settings_tts_desc': 'Audio für Karten in SipDeck und BuzzTap abspielen.',
      'settings_sfx': 'Soundeffekte',
      'settings_sfx_desc': 'Töne für Klicks, Swipes und Siege abspielen.',
      'settings_host_name': 'Hostname',
      'tts_toggle': 'Vorlesen umschalten',
      'tts_active': 'Vorlesen aktiv',
      'tts_inactive': 'Vorlesen inaktiv',
      'settings_data': 'Datenverwaltung',
      'settings_db_reset': 'Datenbank zurücksetzen',
      'settings_db_reset_confirm':
          'Bist du sicher? Alle Spieler, der Verlauf und die Ranglisten werden permanent gelöscht.',
      'settings_db_reset_success': 'Datenbank wurde zurückgesetzt.',
      'back': 'Zurück',
      'qwixx_variant_original': 'Original',

      // ── Home / Games List
      'home_choose_game': 'Wähle ein Spiel zum Punkte-Tracking',
      'home_search_games': 'Spiele suchen...',
      'home_filter_all': 'Alle',
      'home_tag_card': 'Kartenspiel',
      'home_tag_dice': 'Würfelspiel',
      'home_tag_board': 'Brettspiel',
      'home_tag_sport': 'Sport',
      'home_tag_party': 'Trinkspiel',

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
      'game_no_players': 'Keine Spieler ausgewählt.',
      'game_setup_title': 'Spiel-Setup',
      'game_setup_start': 'Spiel starten',
      'game_setup_choose_players': 'Wähle Spieler für {0}',
      'game_setup_min_players': 'Bitte wähle mindestens {0} Spieler aus.',
      'add_round': 'Runde hinzufügen',
      'clear': 'Leeren',
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
      'game_buzztap': 'BuzzTap',
      'game_settings': 'Spiel-Einstellungen',
      'winner': 'Gewinner',
      'home_tag_ext': 'Extra',
      'desc_buzztap':
          'Dynamische challenges und Trinkaufgaben für deine Party.',

      // ── BuzzTap
      'buzztap_title': 'BuzzTap',
      'buzztap_cat_warmup': 'Aufwärmen',
      'buzztap_cat_party': 'Party',
      'buzztap_cat_hot': 'Heiß',
      'buzztap_cat_extreme': 'Extrem',
      'buzztap_start': 'Los geht\'s!',
      'sip_tracker': 'Schluckzähler',
      'category_help_title': 'Kategoriebeschreibungen',
      'buzztap_help_warmup':
          'Leichte Icebreaker, um alle in Stimmung zu bringen.',
      'buzztap_help_party': 'Allgemeine Party-Herausforderungen für alle.',
      'buzztap_help_hot': 'Gewagte und flirty Aufgaben (18+).',
      'buzztap_help_extreme':
          'Extreme und verrückte Herausforderungen! Macht euch auf was gefasst.',
      'sipdeck_help_warmup':
          'Leichte Icebreaker-Herausforderungen, Spaß für jeden.',
      'sipdeck_help_wildcards': 'Anspruchsvolle Mutproben und kreative Regeln.',
      'sipdeck_help_flirty': 'Verspielte, flirty Herausforderungen (18+).',
      'sipdeck_help_barnight': 'Geeignet für jede Bar.',
      'sipdeck_help_laughs':
          'Alberne und absurde Dinge, die man tun oder sagen muss.',

      // ── BuzzTap Cards (DE)
      'bt_card_w001':
          '👋 {0}, stelle dich mit einem falschen Künstlernamen vor. Die Gruppe entscheidet, ob er passt.',
      'bt_card_w002':
          '🍹 Jeder, der gerade ein Getränk in der Hand hat, nimmt einen Schluck.',
      'bt_card_w003':
          '📱 {0}, zeige der Gruppe dein zuletzt gespeichertes Foto. Peinlich? 2 Schlücke.',
      'bt_card_w004':
          '👂 {0}, erzähle ein Geheimnis über {1}. Wenn {1} es leugnet, trinkst du 3.',
      'bt_card_w005':
          '🕒 Die letzte Person, die auf dieser Party angekommen ist, nimmt 2 Schlücke.',
      'bt_card_p001':
          '🔥 Heißer Stuhl! {0} hat 30 Sekunden Zeit, um alle Fragen der Gruppe zu beantworten. Einmal passen = 1 Schluck.',
      'bt_card_p002':
          '💃 {0}, zeig uns deinen besten Tanzmove. Wenn niemand mitmacht, nimm 3 Schlücke.',
      'bt_card_p003':
          '🎤 Karaoke-Zeit! {0} muss den Refrain eines bekannten Liedes singen. Die Gruppe bewertet.',
      'bt_card_p004':
          '🤫 Schweige-Spiel: Die nächste Person, die spricht, nimmt 3 Schlücke.',
      'bt_card_p005':
          '🍻 Prost! Jeder wählt einen Partner und stößt auf etwas an, das er an ihm mag.',
      'bt_card_h001':
          '👀 {0}, wer hier ist am attraktivsten? Diese Person verteilt 3 Schlücke.',
      'bt_card_h002':
          '💋 {0} und {1}, 10 Sekunden intensiver Augenkontakt. Wer zuerst wegschaut, trinkt 3.',
      'bt_card_h003':
          '🔞 {0}, was macht dich auf seltsame Weise an? Willst du es nicht sagen? Trink 5.',
      'bt_card_h004':
          '💘 {0}, schreibe deinem Ex "Ich vermisse dich". Du weigerst dich? Ex dein Getränk.',
      'bt_card_h005':
          '🖤 Wahrheit oder Trinken: {0} stellt {1} eine pikante Frage. Entweder {1} antwortet oder trinkt 4.',
      'bt_card_e001':
          '🧨 Shot-Zeit! {0} wählt jemanden aus, um gemeinsam einen Shot zu trinken.',
      'bt_card_e002':
          '💀 {0}, lass {1} posten was er will in deiner Social-Media-Story.',
      'bt_card_e003':
          '🌪️ Getauscht! {0} und {1} müssen für die nächsten 3 Runden ein Kleidungsstück tauschen.',
      'bt_card_e004':
          '🤡 {0}, lass die Gruppe dir mit einem Edding einen kleinen Schnurrbart malen.',

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
      'help_multiplayer': 'Multiplayer-Anleitung',
      'help_multiplayer_desc':
          'Erfahre, wie du Spiele hostest und ihnen beitrittst.',
      'settings_pwa_install': 'NexScore installieren',
      'settings_pwa_install_desc':
          'Installiere NexScore auf deinem Startbildschirm für eine bessere Erfahrung und Offline-Zugriff.',
      'settings_pwa_guide_title': 'Installations-Anleitung',
      'settings_pwa_guide_msg':
          'Dein Gerät oder Browser unterstützt keine automatische Installation. Du kannst NexScore manuell zum Startbildschirm hinzufügen:',
      'settings_pwa_guide_ios':
          'Safari: Tippe auf den Teilen-Button [icon] und wähle "Zum Home-Bildschirm".',
      'settings_pwa_guide_android':
          'Chrome: Tippe auf das Drei-Punkte-Menü und wähle "App installieren".',
      'settings_pwa_guide_windows':
          'Edge/Chrome: Klicke auf das Installations-Symbol in der Adressleiste oder wähle "App installieren" im Menü.',
      'multiplayer_firebase_missing': 'Firebase nicht konfiguriert',
      'multiplayer_firebase_missing_desc':
          'Multiplayer erfordert Firebase. Bitte konfiguriere Umgebungsvariablen oder Secrets.',
      'multiplayer': 'Multiplayer',
      'multiplayer_hub': 'Multiplayer Hub',
      'multiplayer_host': 'Raum erstellen',
      'multiplayer_join': 'Raum beitreten',
      'multiplayer_room_code': 'Raum-Code',
      'multiplayer_diagnostics': 'Multiplayer Diagnose',
      'settings_presets': 'Spieler-Gruppen',
      'presets_save': 'Als Gruppe speichern',
      'presets_load': 'Gruppe laden',
      'presets_name': 'Gruppen-Name',
      'presets_delete': 'Gruppe löschen',
      'presets_empty': 'Noch keine Gruppen gespeichert.',
      'presets_save_success': 'Gruppe erfolgreich gespeichert.',
      'presets_save_error': 'Fehler beim Speichern der Gruppe.',
      'presets_load_confirm':
          'Diese Gruppe laden? (Aktuelle Spieler werden ersetzt)',
      'multiplayer_diagnostics_desc':
          'Falls du Verbindungsprobleme hast, prüfe Folgendes:',
      'multiplayer_auth_title': 'Anonymer Login',
      'multiplayer_auth_desc':
          'Stelle sicher, dass "Anonymous" Authentifizierung in der Firebase Console aktiviert ist.',
      'multiplayer_adblock_title': 'AdBlocker / VPN',
      'multiplayer_adblock_desc':
          'Deaktiviere AdBlocker oder VPNs, die "firestore.googleapis.com" blockieren könnten.',
      'multiplayer_domains_title': 'Autorisierte Domains',
      'multiplayer_domains_desc':
          'Stelle sicher, dass deine aktuelle Domain in der Firebase Console unter "Authorized Domains" hinterlegt ist.',
      'multiplayer_diagnostics_timeout': '• Zeitüberschreitung (10s)',
      'multiplayer_lobby_closed': 'Lobby geschlossen.',
      'multiplayer_error_host': 'Fehler beim Erstellen der Lobby: {0}',

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
      'wizard_total': 'Gesamt',
      'wizard_scoring_lenient':
          'Lenient – Stiche werden mit Geboten verrechnet',
      'wizard_scoring_extreme':
          'Extreme – richtig = +30, falsch = doppelte Strafe',
      'wizard_rule_stiche': 'Stiche dürfen nicht aufgehen',
      'wizard_rule_uneven_error':
          'Die Stiche dürfen für {0} nicht genau aufgehen.',
      'wizard_rule_stiche_desc':
          'Der letzte Spieler kann keinen Gleichstand erzwingen.',
      'wizard_2player_warning':
          'Hinweis: Amigo unterstützt Wizard mit nur 2 Spielern offiziell nicht.',

      // ── Qwixx
      'qwixx_title': 'Qwixx',
      'qwixx_score_label': 'Gesamtpunktzahl: {0}',
      'qwixx_red': 'Rot',
      'qwixx_yellow': 'Gelb',
      'qwixx_green': 'Grün',
      'qwixx_blue': 'Blau',
      'qwixx_penalties': 'Fehlwürfe',

      // ── WayQuest
      'game_wayquest': 'WayQuest',
      'wayquest_title': 'WayQuest',
      'wayquest_categories': 'Kategorien wählen',
      'wayquest_cat_deepTalks': 'Deep Talks',
      'wayquest_cat_wouldYouRather': 'Würdest du eher',
      'wayquest_cat_roadChallenges': 'Auto-Challenges',
      'wayquest_cat_hypotheticals': 'Hypothetisch',
      'wayquest_cat_storyStarters': 'Geschichten-Starter',
      'wayquest_start': 'REISE STARTEN',
      'wayquest_tap_continue': 'Tippen für die nächste Quest',
      'desc_wayquest':
          'Unterhaltsame Fragen und Challenges für lange Autofahrten.',

      // Deep Talks (DE)
      'wq_card_dt001':
          'Wenn du in der Zeit zurückreisen könntest, welchen Moment würdest du noch mal erleben?',
      'wq_card_dt002': 'Was war ein Ratschlag, der dein Leben verändert hat?',
      'wq_card_dt003': 'Wofür bist du gerade in diesem Moment am dankbarsten?',
      'wq_card_dt004':
          'Wenn du mit einer historischen Figur Abendessen könntest, wer wäre das?',
      'wq_card_dt005':
          'Auf welche Leistung in deinem Leben bist du besonders stolz?',
      'wq_card_dt006': 'Wie sieht dein "perfekter Tag" aus?',
      'wq_card_dt007':
          'Wenn du über Nacht eine Fähigkeit meistern könntest, welche wäre das?',
      'wq_card_dt008': 'Wofür möchtest du einmal in Erinnerung bleiben?',
      'wq_card_dt009': 'Was ist der schönste Ort, an dem du jemals warst?',
      'wq_card_dt010':
          'Was ist eine "Kleinigkeit", die dich immer glücklich macht?',

      // Would You Rather (DE)
      'wq_card_wyr001':
          'Würdest du eher immer singen müssen statt zu reden, oder immer tanzen statt zu gehen?',
      'wq_card_wyr002': 'Würdest du eher fliegen können oder unsichtbar sein?',
      'wq_card_wyr003':
          'Würdest du eher 100 Jahre in der Vergangenheit oder 100 Jahre in der Zukunft leben?',
      'wq_card_wyr004':
          'Wärst du lieber immer 10 Minuten zu spät oder immer 20 Minuten zu früh?',
      'wq_card_wyr005':
          'Wärst du lieber der klügste Mensch der Welt oder der lustigste?',
      'wq_card_wyr006':
          'Würdest du lieber die Tiefsee erforschen oder das Weltall?',
      'wq_card_wyr007':
          'Hättest du lieber eine riesige Nase oder riesige Ohren?',
      'wq_card_wyr008':
          'Würdest du lieber alle Sprachen der Welt sprechen oder mit Tieren reden können?',
      'wq_card_wyr009':
          'Würdest du eher nie wieder Schokolade essen oder nie wieder Pizza?',
      'wq_card_wyr010':
          'Wärst du lieber ein berühmter Schauspieler oder ein berühmter Wissenschaftler?',

      // Road Challenges (DE)
      'wq_card_rc001':
          'Wer zuerst ein gelbes Auto sieht, darf das nächste Lied wählen!',
      'wq_card_rc002':
          'Alle: Findet ein Nummernschild, das mit dem gleichen Buchstaben wie euer Name beginnt.',
      'wq_card_rc003':
          'Zählt, wie viele Windräder wir in den nächsten 5 Minuten passieren.',
      'wq_card_rc004':
          'Die nächste Person, die eine Kuh sieht, darf einen Witz erzählen.',
      'wq_card_rc005':
          'Alphabet-Spiel! Findet Wörter auf Schildern von A bis Z.',
      'wq_card_rc006':
          'Entdecke ein Auto aus einem anderen Bundesland/Land. Extrapunkte für weite Distanzen!',
      'wq_card_rc007':
          'Wer zuerst eine rote Brücke sieht, gewinnt 10 virtuelle Punkte.',
      'wq_card_rc008':
          'Alle: Ratet, wie viele Minuten es bis zur nächsten Tankstelle dauert.',
      'wq_card_rc009':
          'Zeig auf den interessantesten Baum in der nächsten Minute.',
      'wq_card_rc010':
          'Schaut, ob ihr eine Wolke findet, die wie ein Tier aussieht.',

      // Hypotheticals (DE)
      'wq_card_hyp001':
          'Wenn wir auf einer einsamen Insel stranden würden, welchen Gegenstand hätten wir gerne dabei?',
      'wq_card_hyp002':
          'Wenn du für eine Stunde eine Superkraft hättest, welche wäre das?',
      'wq_card_hyp003':
          'Wenn du morgen im Lotto gewinnen würdest, was wäre das Erste, was du kaufst?',
      'wq_card_hyp004':
          'In welcher fiktiven Welt (Buch/Film) würdest du gerne leben?',
      'wq_card_hyp005': 'Mit wem würdest du für einen Tag das Leben tauschen?',
      'wq_card_hyp006':
          'Wenn du mit deinem 8-jährigen Ich sprechen könntest, was würdest du sagen?',
      'wq_card_hyp007':
          'Wenn du eine Wunderlampe fändest, was wären deine drei Wünsche?',
      'wq_card_hyp008':
          'Wenn du einen neuen Feiertag erfinden könntest, was würde man feiern?',
      'wq_card_hyp009':
          'Wenn Tiere sprechen könnten, welches wäre am unhöflichsten?',
      'wq_card_hyp010':
          'Wenn du überall auf der Welt ein Haus bauen könntest, wo wäre das?',

      // Story Starters (DE)
      'wq_card_ss001':
          'Es war einmal, in einem Auto, das durch einen geheimnisvollen Wald fuhr...',
      'wq_card_ss002':
          'Stell dir vor, wir finden eine versteckte Tür im Kofferraum. Wohin führt sie?',
      'wq_card_ss003':
          'Ein riesiger Vogel landet plötzlich auf dem Dach des Autos. Was passiert als Nächstes?',
      'wq_card_ss004':
          'Das Radio spielt plötzlich ein Lied aus dem Jahr 3000. Wovon handelt es?',
      'wq_card_ss005':
          'Wir merken, dass wir eigentlich in einem Film sind. Wie heißt unser Film?',
      'wq_card_ss006':
          'Das Auto fängt plötzlich an, mit uns zu sprechen. Was ist das Erste, was es sagt?',
      'wq_card_ss007':
          'Jedes Mal, wenn wir eine Brücke überqueren, landen wir in einer anderen Dimension. Wo sind wir?',
      'wq_card_ss008':
          'Wir finden eine Karte im Handschuhfach, die zu einem Piratenschatz führt. Was ist das für ein Schatz?',
      'wq_card_ss009':
          'Ein Eichhörnchen verfolgt unser Auto auf einem winzigen Motorrad. Warum?',
      'wq_card_ss010':
          'Plötzlich kann jeder auf der Welt nur noch in Reimen sprechen. Los geht\'s!',

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
      'arschloch_no_rank': 'Kein Rang',
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
      'arschloch_min_3_players':
          'Mindestens 2 Spieler erforderlich (3+ empfohlen)',
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
      'arschloch_rules_passing': '• Niemand MUSS legen. Aussetzen ist erlaubt.',
      'arschloch_2player_warning':
          'Arschloch macht mit 3 oder mehr Spielern am meisten Spaß!',

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
      'kniffel_multiple_yahtzee': 'Mehrfach-Kniffel Bonus (+50)',
      'kniffel_yahtzee_joker': 'Kniffel-Joker genutzt',
      'kniffel_yahtzee_bonus': 'Kniffel Bonus',
      'kniffel_yahtzee_bonus_desc': '+50 Punkte für weitere Kniffel',
      'kniffel_enter_score': 'Punkte eingeben für {0}',

      // ── Darts
      'darts_title': 'Darts (X01)',
      'darts_target': 'Darts ({0})',
      'darts_avg': 'Schnitt: {0}',
      'darts_thrown': 'Darts geworfen: {0}',
      'darts_bust': 'Bust',
      'darts_enter_score': 'Score für {0}',
      'darts_input_desc': 'Einzelne Würfe eingeben (Wert & Multiplikator)',
      'darts_remaining': 'Restlich',
      'darts_remove_last': 'Letzten Wurf entfernen',
      'darts_checkout_possible': 'Checkout möglich!',
      'darts_finish_type': 'Finish-Typ',
      'darts_start_type': 'Start-Typ',
      'darts_finish_single': 'Single Out',
      'darts_finish_double': 'Double Out',
      'darts_finish_master': 'Master Out (Double/Triple)',
      'darts_start_straight': 'Direkter Start',
      'darts_start_double': 'Double In',
      'darts_start_master': 'Master In',
      'darts_settings': 'Darts Einstellungen',

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
      'phase10_p1_title': 'Phase 1\', \'phase10_p1_desc\': \'2 Drillinge',
      'phase10_p2_title': 'Phase 2',
      'phase10_p2_desc': '1 Drilling + 1 Viererfolge',
      'phase10_p3_title': 'Phase 3',
      'phase10_p3_desc': '1 Vierling + 1 Viererfolge',
      'phase10_p4_title': 'Phase 4\', \'phase10_p4_desc\': \'1 Siebenerfolge',
      'phase10_p5_title': 'Phase 5\', \'phase10_p5_desc\': \'1 Achterfolge',
      'phase10_p6_title': 'Phase 6\', \'phase10_p6_desc\': \'1 Neunerfolge',
      'phase10_p7_title': 'Phase 7\', \'phase10_p7_desc\': \'2 Vierlinge',
      'phase10_p8_title':
          'Phase 8\', \'phase10_p8_desc\': \'7 Karten einer Farbe',
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
      'romme_breakdown': 'Punktübersicht',
      'romme_total_points': 'Gesamtpunkte',
      'romme_first_meld': 'Erstmeldung (Punkte)',
      'romme_hand_romme': 'Hand-Rommé (In einem Zug)',
      'romme_joker_points': 'Joker Punkte',
      'romme_settings': 'Rommé Einstellungen',
      'romme_hand_romme_desc':
          'Punkte werden verdoppelt, wenn ohne vorherige Meldung beendet wird.',

      // ── History
      'game_generic': 'Punkteliste (Generisch)',
      'desc_generic': 'Eine flexible Runden-Tabelle für jedes Spiel.',
      'pwa_update_available': 'Update verfügbar!',
      'refresh': 'AKTUALISIEREN',
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
      'sipdeck_optimize_2players': '2-Spieler Optimierung',
      'sipdeck_optimize_2players_desc':
          'Blende Karten aus, die zu zweit wenig Sinn machen.',
      'sipdeck_no_players': 'Füge zuerst Spieler hinzu, um SipDeck zu spielen.',
      'sipdeck_filters': 'Aufgaben-Filter',
      'sipdeck_tag_dare': 'Pflichtaufgaben',
      'sipdeck_tag_social': 'Soziale Interaktion',
      'sipdeck_tag_messaging': 'Personen anschreiben',
      'sipdeck_tag_physical': 'Körperliches',
      'sipdeck_tag_help_title': 'Filter-Details',
      'sipdeck_tag_help_dare':
          'Pflichtaufgaben: Aufgaben, bei denen du dich beweisen oder bestimmte Aktionen ausführen musst.',
      'sipdeck_tag_help_social':
          'Soziale Interaktion: Herausforderungen, die Interaktion mit der Gruppe oder Fremden erfordern.',
      'sipdeck_tag_help_messaging':
          'Messaging: Aufgaben, bei denen du Nachrichten verschicken oder Postings machen musst.',
      'sipdeck_tag_help_physical':
          'Körperliches: Aktivitäten, die körperlichen Einsatz erfordern, wie Liegestütze oder Springen.',

      'sipdeck_settings': 'SipDeck Einstellungen',
      'sipdeck_enable_hydration': 'Hydratisierungs-Karten',
      'sipdeck_enable_hydration_desc':
          'Streut gelegentlich Wasserpausen in das Spiel ein.',
      'sipdeck_hydration_card_text':
          '💧 Hydratisieren! Alle trinken einen großen Schluck Wasser.',

      'sipdeck_18_warning': 'Ab 18 Jahren freigegeben.',
      'sipdeck_2player_warning':
          'SipDeck macht am meisten Spaß mit 3 oder mehr Spielern!',
      'buzztap_2player_warning':
          'BuzzTap macht am meisten Spaß mit 3 oder mehr Spielern!',
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
      'account_guest': 'Gast',
      'account_guest_status': 'Gast-Sitzung',
      'account_guest_sync_label': 'Sync inaktiv (Nur lokal)',
      'account_sign_out': 'Abmelden',
      'account_default_name': 'NexScore Nutzer',
      'account_gist_backup_title': 'GitHub Gist Backup',
      'account_gist_backup_desc': 'Sichere deine Daten in einem privaten Gist',
      'account_gist_restore_title': 'Wiederherstellen von Gist',
      'account_gist_restore_desc': 'Lade deine Daten von GitHub herunter',
      'account_sign_in_error': 'Anmeldung fehlgeschlagen: {0}',
      'account_data_stay_note':
          'Deine lokalen Daten bleiben beim Abmelden auf diesem Gerät erhalten.',
      'account_privacy_info':
          'NexScore ist serverlos. Daten werden lokal oder in deiner privaten Cloud (Firestore/Gist) gespeichert.',
      'account_privacy_link': 'Datenschutz & Berechtigungen Dokumentation',
      'error_name_taken': 'Ein Spieler mit diesem Namen existiert bereits.',

      'privacy_title': 'Datenschutz & Berechtigungen',
      'privacy_no_server_title': 'Serverlose Architektur',
      'privacy_no_server_body':
          'NexScore hat keinen zentralen Server. Alle Daten werden lokal auf deinem Gerät verarbeitet oder direkt mit deinen autorisierten Cloud-Anbietern (Google/GitHub) synchronisiert. Wir sehen, verkaufen oder teilen deine Daten niemals.',
      'privacy_google_title': 'Google Berechtigungen (Firestore)',
      'privacy_google_body':
          'Angefragt: Basis-Profil (E-Mail/Name). Wird verwendet, um dein Konto zu identifizieren und deine Spieler sowie den Spielverlauf mit Google Cloud Firestore zu synchronisieren für Multi-Geräte-Unterstützung.',
      'privacy_github_title': 'GitHub Berechtigungen (Gists)',
      'privacy_github_body':
          'Angefragt: Gist-Berechtigung. Wird verwendet, um ein privates Backup deiner Daten in deinem GitHub-Konto zu erstellen. Es wird nur auf von NexScore erstellte Gists zugegriffen.',

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
          '💖 {0}, mache {1} ein echtes Kompliment über den Style. Wenn du rot wirst, trinke 2 Schlücke.',
      'sd_card_f001_expl':
          'Wähle etwas Spezifisches aus (Haare, Outfit, Augen) und sei ehrlich. Wenn du dabei errötest, musst du 2 Schlücke trinken.',
      'sd_card_f002':
          '🤝 {0} und {1} haben 30 Sekunden Zeit, eine Gemeinsamkeit zu finden. Scheitern? Beide 3 Schlücke.',
      'sd_card_f002_expl':
          'Redet! Findet ein gemeinsames Hobby, ein Lieblingsessen oder ein Erlebnis. Wenn nach 30s nichts gefunden wurde, trinken beide.',
      'sd_card_f003':
          '💌 {0}, schreibe dem letzten Kontakt ein Herz-Emoji. Verweigern? Trinke 2 Schlücke.',
      'sd_card_f003_expl':
          'Öffne deine Messenger-App und sende ein "❤️" an die erste Person in deiner Liste. Keine Lust? Dann trinke 2.',
      'sd_card_f004':
          '😁 Abstimmung: Schönstes Lächeln im Raum. Diese Person darf 3 Schlücke verteilen.',
      'sd_card_f004_expl':
          'Zeigt eure Zähne! Die Gruppe zeigt auf ihren Favoriten. Der Gewinner bestimmt, wer 3 Schlücke trinken muss.',
      'sd_card_f005':
          '🤐 {0}, beschreibe deinen Schwarm, ohne den Namen zu nennen. Die Gruppe rät.',
      'sd_card_f005_expl':
          'Gib Hinweise zu Aussehen oder Charakter. Wenn nach einer Minute niemand darauf kommt, solltest du bessere Tipps geben!',
      'sd_card_f006':
          '📊 Wahrheit: {0}, bewerte jede Person von 1–10. Verweigern? Trinke 4 Schlucke.',
      'sd_card_f006_expl':
          'Sei ehrlich, aber charmant! Bewerte alle im Raum auf einer Skala von 1 bis 10. Zu feige? Dann trinke 4 Schlücke.',
      'sd_card_f007':
          '📝 Jeder schreibt ein Ein-Wort-Kompliment für {0}. {0} rät, von wem es ist. Falsch? 1 Schluck jeweils.',
      'sd_card_f007_expl':
          'Jeder (außer {0}) schreibt ein nettes Wort auf sein Handy. {0} versucht, das Wort dem Schreiber zuzuordnen. Trinke für jeden falschen Tipp.',
      'sd_card_b001':
          '🥂 {0} beginnt einen Trinkspruch. Jeder fügt einen Satz hinzu. Fehler? Trinke 2 Schlücke.',
      'sd_card_b001_expl':
          'Starte eine Rede. Jeder in der Runde setzt die Geschichte mit einem Satz fort. Wenn jemand stockt oder den Faden verliert: Trinken!',
      'sd_card_b002':
          '💰 Rate den Preis des teuersten Getränks hier. Am weitesten weg? Trinke 2 Schlücke.',
      'sd_card_b002_expl':
          'Schaut in die Karte! Jeder nennt einen Preis. Wer am weitesten vom tatsächlichen Preis entfernt liegt, trinkt 2.',
      'sd_card_b003':
          '🍹 Alle bestellen etwas, das sie noch nie probiert haben, oder trinken 2 Schlücke.',
      'sd_card_b003_expl':
          'Nächste Runde Pflicht! Wenn du dein Standard-Getränk bestellst, nimmst du 2 Schlücke als Strafe. Probiere was Neues!',
      'sd_card_b004':
          '🍻 {0} muss diese Runde "Prost" in 3 Sprachen sagen. Pro fehlender Sprache 1 Schluck.',
      'sd_card_b004_expl':
          'Zeig wie international du bist. "Prost", "Salute", "Cheers"... du brauchst 3. Trinke für jede Sprache, die dir fehlt.',
      'sd_card_b005':
          '🪑 Alle stehen auf und tauschen Sitzplätze. Der Letzte trinkt 2 Schlücke.',
      'sd_card_b005_expl':
          'Reise nach Jerusalem ohne Musik! Jeder muss sich einen neuen Platz suchen. Der langsamste Teilnehmer trinkt 2.',
      'sd_card_b006':
          '🤝 {0}, rede für mindestens 1 Minute mit einem Fremden. Scheitern? Trinke 4 Schlucke.',
      'sd_card_b006_expl':
          'Soziale Challenge! Geh auf jemanden zu, den du nicht kennst, und halte das Gespräch für 60s am Laufen. Oder trinke 4.',
      'sd_card_l001':
          '🐧 {0}, watschele wie ein Pinguin ans andere Ende des Raums und zurück.',
      'sd_card_l001_expl':
          'Arme eng an den Körper und watscheln! Wenn du aus der Rolle fällst, kann die Gruppe eine Strafe verlangen.',
      'sd_card_l002':
          '☕ VIRUS: {0} muss die nächsten 5 Karten jeden Satz mit "und das ist Tee-Zeit" beenden. Vergessen? 2 Schlücke.',
      'sd_card_l002_expl':
          'Die nächsten 5 Runden lang musst du nach jedem Mal Sprechen "und das ist Tee-Zeit" sagen. Wenn du es vergisst, trinke 2.',
      'sd_card_l003':
          '🦒 {0}, kommentiere das aktuelle Geschehen für 60s wie eine Naturdokumentation.',
      'sd_card_l003_expl':
          'Spiele den Tierfilmer. Beschreibe das Verhalten deiner "wilden" Freunde an der Bar oder auf der Party.',
      'sd_card_l004':
          '🤣 Alle sagen gleichzeitig das lustigste Wort, das sie kennen. Bestes Wort darf 2 Schlucke verteilen.',
      'sd_card_l004_expl':
          'Auf drei rufen alle! Das lustigste Wort (Abstimmung der Gruppe) gewinnt und darf 2 Schlücke verteilen.',
      'sd_card_l005':
          '❓ {0} darf für die nächsten 2 Minuten nur Fragen stellen. Aussage getätigt? 1 Schluck.',
      'sd_card_l005_expl':
          'Keine Fakten nennen! Jedes Mal, wenn du sprichst, muss es eine Frage sein? Wenn du etwas behauptest: Trinken!',
      'sd_card_l006':
          '🖐️ {0}, erkläre deinen Job nur mit Handbewegungen. Keiner rät nach 30s? Trinke 3 Schlucke.',
      'sd_card_l006_expl':
          'Pantomime! Erkläre deine Arbeit ohne ein Wort zu sagen. Wenn deine Freunde zu ahnungslos sind, musst du trinken.',
      'sd_card_l007':
          '🆕 {0}, erfinde ein neues Wort und nutze es überzeugend. Die Gruppe stimmt ab.',
      'sd_card_l007_expl':
          'Denk dir ein Wort und eine Definition aus. Wenn die Gruppe findet, dass es echt klingt, bist du sicher.',
      'sd_card_l008':
          '🏙️ Schnellrunde: Nenne einen Film, ein Lied und eine Stadt mit dem Anfangsbuchstaben, den die Person links wählt.',
      'sd_card_l008_expl':
          'Dein linker Nachbar gibt dir einen Buchstaben (z.B. "B"). Du hast 10 Sekunden für alle drei Dinge. Sonst trinke 2.',
      'sd_card_l009':
          '🐢 {0}, sprich für die nächsten 3 Runden in Zeitlupe oder trinke 3 Schlucke.',
      'sd_card_l009_expl':
          'Jedes... einzelne... Wort... extra... lang... ziehen... Wenn du normal sprichst, bevor die 3 Runden um sind: Trinke 3.',
      'sd_card_w100':
          'Nenne 3 Hauptstädte in 5 Sekunden. Zu langsam? 2 Schlücke.',
      'sd_card_w101':
          'Singe den Refrain des letzten Liedes, das du gehört hast, oder trinke 3.',
      'sd_card_w102': 'Jeder, der etwas Rotes trägt, trinkt 1 Schluck(e).',
      'sd_card_w103':
          'Ich habe noch nie über mein Alter gelogen. Wer doch, trinkt.',
      'sd_card_w104':
          'Nenne 3 Automarken, bevor der nächste "Beep" sagt. Sonst 2 Schlücke.',
      'sd_card_w105': 'Wer Ananas auf Pizza mag, trinkt stolz 2 Schlücke.',
      'sd_card_w106':
          'Die Person mit den meisten Haustieren verteilt 2 Schlücke.',
      'sd_card_w107':
          'Wessen Hände jetzt gerade kalt sind, trinkt zum Aufwärmen.',
      'sd_card_w108': 'Wenn dein Handyakku unter 20% ist, trinke 2 Schlücke.',
      'sd_card_w109': 'Jeder, der Sneaker trägt, trinkt 1 Schluck.',
      'sd_card_w110':
          'Zeige auf die Person, die am meisten gereist ist. Sie trinkt 2.',
      'sd_card_w111': 'Wer Kopfhörer in der Tasche hat, trinkt einen Schluck.',
      'sd_card_w112': 'Kaffee-Süchtige, trinkt sofort 2 Schlücke.',
      'sd_card_w113':
          'Nenne eine Netflix-Serie, die du in 2 Tagen durchgeschaut hast. Keine? Trinke 2.',
      'sd_card_w114': 'Der jüngste Spieler trinkt 2 Schlücke.',
      'sd_card_w115': 'Der älteste Spieler trinkt 2 Schlücke.',
      'sd_card_w116':
          'Jeder, der in einem ungeraden Monat geboren wurde, trinkt.',
      'sd_card_w117': 'Hüpfe 3 Mal. Wenn du dich weigerst, trinke 2.',
      'sd_card_w118': 'Spiele 10 Sekunden Luftgitarre oder trinke 3.',
      'sd_card_w119':
          'Klatsche in die Hände. Der Letzte, der klatscht, trinkt 2.',
      'sd_card_wc100':
          'Tausche dein Getränk mit der Person links bis zur nächsten Runde.',
      'sd_card_wc101':
          'Du bist ein Geist! Niemand darf mit dir reden. Wer es tut, trinkt 2.',
      'sd_card_wc102':
          'Regel: Jeder, der mit dem Finger auf jemanden zeigt, trinkt 1.',
      'sd_card_wc103':
          'Regel: T-Rex Arme! Du darfst deine Arme nicht ausstrecken. Bei Verstoß 2 trinken.',
      'sd_card_wc104':
          'Sprich wie ein Roboter für deine nächsten 3 Züge, oder trinke 3.',
      'sd_card_wc105':
          'Regel: Nenne jeden beim Zweit- oder Nachnamen. Vergessen = trinken.',
      'sd_card_wc106':
          'Einhorn! Die nächste Person, die "Ja" sagt, trinkt 2 Schlücke.',
      'sd_card_wc107':
          'Mache ein Selfie und nutze es für einen Tag als Profilbild. Oder trinke 5.',
      'sd_card_wc108':
          'Aliens haben dein Gedächtnis entführt. Frage 5 Mal "Wer bin ich?". Vergessen = trinke 3.',
      'sd_card_wc109':
          'Rufe einen Kontakt an und frage nach einem Witz. Keine Lust? Trinke 4.',
      'sd_card_wc110':
          'Verhalte dich wie ein Dinosaurier bis du wieder dran bist. Oder trinke 3.',
      'sd_card_wc111':
          'Wirf eine Münze. Kopf = 2 Schlücke verteilen, Zahl = 2 trinken.',
      'sd_card_wc112':
          'Jeder muss sich 3 Mal drehen und hinsetzen. Der Letzte trinkt 2.',
      'sd_card_wc113':
          'Halte einen Eiswürfel, bis er schmilzt, oder trinke 4 Schlücke.',
      'sd_card_wc114':
          'Denke dir ein Haiku aus (5-7-5 Silben). Versagt? Trinke 3.',
      'sd_card_wc115':
          'Spiele eine bekannte Filmszene nach. Wenn keiner sie errät, trinke 2.',
      'sd_card_wc116':
          'Trinke nur mit der schwachen Hand. Vergessen = 1 Strafschluck.',
      'sd_card_wc117':
          'Du bist der General. Befehle 2 Personen, 2 Schlücke zu nehmen.',
      'sd_card_wc118':
          'Stummschaltung. Niemand darf reden, bis jemand sein Glas leert.',
      'sd_card_wc119':
          'Freifahrtschein! Behalte diese Karte, um eine zukünftige Aufgabe zu überspringen.',
      'sd_card_f100':
          'Wer küsst hier am besten? Wenn du nicht raten willst, trinke 4.',
      'sd_card_f101':
          'Starre der Person gegenüber 15s in die Augen. Gelacht? Trinke 3.',
      'sd_card_f102':
          'Zeige deinen besten Anmachspruch. Wenn alle cringen, trinke 3.',
      'sd_card_f103':
          'Erzähle der Gruppe dein peinlichstes Date, oder trinke 4.',
      'sd_card_f104':
          'Gib jemandem eine Schultermassage für 30 Sekunden. Oder trinke 3.',
      'sd_card_f105':
          'Lass jemanden für 2 Runden auf deinem Schoß sitzen. Nein? Trinke 4.',
      'sd_card_f106': 'Nenne deinen komischsten Turn-On. Feige? Trinke 5.',
      'sd_card_f107':
          'Wirf der süßesten Person einen Kuss zu. Sie verteilt 2 Schlücke.',
      'sd_card_f108':
          'Ich war noch nie in jemanden in diesem Raum verknallt. Wenn doch: Trinken.',
      'sd_card_f109':
          'Mache ein verführerisches Foto. Nutze es 1 h als Hintergrund. Oder trinke 5.',
      'sd_card_f110':
          'Wer hat am ehesten ein wildes Doppelleben? Zeigt auf jemanden! Gewinner trinkt 2.',
      'sd_card_f111':
          'Zeige deinen besten Model-Blick. Gruppe bewertet 1-10. Unter 5? Trinke 3.',
      'sd_card_f112':
          'Iss eine imaginäre Erdbeere so provokant wie möglich. Oder trinke 4.',
      'sd_card_f113':
          'Hake dich bei der Person links ein und trinkt euer Getränk zusammen.',
      'sd_card_f114':
          'Lass deinen rechten Nachbarn einen Flirt-Text an einen Kontakt senden. Oder trinke 5.',
      'sd_card_f115': 'Flüstere der Person links etwas Unanständiges ins Ohr.',
      'sd_card_f116':
          'Nenne ein körperliches Merkmal, das du extrem attraktiv findest. Oder trinke 2.',
      'sd_card_f117': 'Mache einen 10 Sekunden Sexy-Tanz. Oder trinke 4.',
      'sd_card_f118': 'Erzähle von deinem besten Kuss. Keine Lust? Trinke 3.',
      'sd_card_f119':
          'Gestehe, in wen du in der Schule mal leicht verknallt warst. Oder trinke 2.',
      'sd_card_b100': 'Prost auf den Barkeeper! Alle stoßen an.',
      'sd_card_b101': 'Wer zuletzt auf der Toilette war, trinkt 2 Schlücke.',
      'sd_card_b102': 'Errate den Song, der gerade läuft. Falsch? Trinke 2.',
      'sd_card_b103':
          'Jeder, der Eis in seinem Getränk hat, trinkt 1 Schlücke.',
      'sd_card_b104':
          'Wenn dein Drink Früchte enthält, genieße 2 Extra-Schlücke.',
      'sd_card_b105': 'Biertrinker: 2 Schlücke. Cocktail/Wein: 2 Schlücke.',
      'sd_card_b106':
          'Person mit der aktuell höchsten Rechnung verteilt 3 Schlücke.',
      'sd_card_b107':
          'Rufe "BARKEEPER" leise in deine Hand. Weigerung? Trinke 2.',
      'sd_card_b108': 'Jeder mit Hut oder Cappie trinkt 2.',
      'sd_card_b109':
          'Wer eine Jacke dabei hat, sie aber nicht trägt: 1 trinken.',
      'sd_card_b110': 'Nenne 3 Ride-Sharing/Taxi Apps. Zu langsam? 2 Schlücke.',
      'sd_card_b111': 'Wer zuletzt Fast-Food gegessen hat, trinkt 2.',
      'sd_card_b112': 'Halte die Luft für 15s an. Fail = 3 trinken.',
      'sd_card_b113': 'Jeder trinkt einen Schluck Wasser. Hydratisieren!',
      'sd_card_b114':
          'High-Five mit dem Nachbarn. Das langsamste Paar trinkt 2.',
      'sd_card_b115': 'Mache sofort ein Gruppenfoto! Unscharf? Trinke 1.',
      'sd_card_b116':
          'Feiere jemanden, der gerade trinkt, sehr laut. Sonst trinkst du 2.',
      'sd_card_b117': 'Bargeld oder Karte? Die Minderheit trinkt 2.',
      'sd_card_b118': 'Wenn dein Glas fast leer ist, trinke es auf Ex aus!',
      'sd_card_b119': 'Wirf einen imaginären Würfel. Jeder außer dir trinkt 2.',
      'sd_card_l100':
          'Versuche, deinen Ellbogen zu lecken. Geht nicht? Das macht 2 Schlücke.',
      'sd_card_l101':
          'Sprich wie Yoda, bis du wieder dran bist. Oder trinke 3.',
      'sd_card_l102': 'Verhalte dich 10 Sekunden wie ein Affe. Nein? Trinke 4.',
      'sd_card_l103':
          'Balanciere einen Löffel auf der Nase. Fällt er runter = 2 trinken.',
      'sd_card_l104':
          'Muhe laut, wenn jemand deinen Namen sagt. Vergessen = 1 Schlücke.',
      'sd_card_l105':
          'Beschreibe deinen letzten Einkauf hochdramatisch. Langweilig = 2 trinken.',
      'sd_card_l106':
          'Argumentiere leidenschaftlich, warum Pizza furchtbar ist. Oder trinke 3.',
      'sd_card_l107':
          'Verwende einen Harry Potter Zauberspruch gegen jemanden. Er trinkt 1.',
      'sd_card_l108':
          'Sprich für 2 Runden nur flüsternd. Vergessen = 2 Schlücke.',
      'sd_card_l109':
          'Erzähle den schlechtesten Flachwitz. Lacht keiner? Trinke 2.',
      'sd_card_l110': 'Tätschele sanft den Kopf der Person links von dir.',
      'sd_card_l111':
          'Lies die nächste Karte mit einer dramatischen Opernstimme vor.',
      'sd_card_l112': 'Krable für 10s auf dem Boden. Weigerung? Trinke 4.',
      'sd_card_l113':
          'Krächze wie ein Adler, bevor du das nächste Mal trinkst.',
      'sd_card_l114': 'Mache 5 Sekunden lang laute Motorgeräusche.',
      'sd_card_l115': 'Mach 5 Sekunden lang den Robotertanz. Fail = 2 trinken.',
      'sd_card_l116':
          'Beatboxe, während jemand anderes seine Strafschlücke trinkt.',
      'sd_card_l117':
          'Sitz für 1 Runde unter dem Tisch. Weigerung = 3 trinken.',
      'sd_card_l118':
          'Tu so, als würdest du wegen deines Drinks heulen. Zu unauthentisch = 3 Schlücke.',
      'sd_card_l119':
          'Mache 1 Minute lang ununterbrochen eine Superheldenpose. Abbruch = 2 trinken.',
      'bt_card_w100':
          'Steh auf und stelle dich feierlich deinem Getränk vor. Oder trinke 2.',
      'bt_card_w101':
          'Wirf einen unsichtbaren Würfel. Ungerade trinkt 1, Gerade 1.',
      'bt_card_w102': 'Jeder mit weißen Socken trinkt 2 Schlücke.',
      'bt_card_w103': 'Nenne 3 gelbe Dinge. Fail = 2 Schlücke.',
      'bt_card_w104': 'Prost! Alle stoßen an und trinken einen Schluck.',
      'bt_card_w105': 'iPhones trinken 1. Androids trinken 1.',
      'bt_card_w106': 'Summe eine Melodie. Wer sie errät, darf 2 verteilen.',
      'bt_card_w107': 'Wer hat als nächstes Geburtstag? Trinke 3 Schlücke.',
      'bt_card_w108': 'Jeder über 25 trinkt 2 Schlücke.',
      'bt_card_w109':
          'Zieh einen Schuh aus und lass ihn 5 Runden aus. Nein = 3 trinken.',
      'bt_card_w110': 'Wer heute eine Tasche dabei hat, trinkt 2.',
      'bt_card_w111': 'Jeder mit Brille oder Kontaktlinsen trinkt 2.',
      'bt_card_w112':
          'Gähne intensiv. Jeder, der ansteckend mitgähnt, trinkt 2.',
      'bt_card_w113': 'Person mit dem kältesten Getränk verteilt 2 Schlücke.',
      'bt_card_w114':
          'Person mit dem wärmsten Getränk trinkt aus Mitleid 2 Schlücke.',
      'bt_card_w115':
          'Gib jemandem ein High-Five. Der Langsamste im Raum trinkt 2.',
      'bt_card_w116':
          'Sage schnell 5x "NexScore ist die beste App". Stolpern = 2 trinken.',
      'bt_card_w117': 'Zeige nach Norden. Wer völlig daneben liegt, trinkt 2.',
      'bt_card_w118': 'Hunde-Fans trinken 1 Schluck. Katzen-Fans 1.',
      'bt_card_w119': 'Nenne 3 Trickfilme. Fail = 2 Schlücke.',
      'bt_card_w120':
          'Wer heute am längsten geschlafen hat, trinkt 2 Schlücke.',
      'bt_card_w121': 'Jogge 10s auf der Stelle oder trinke 3 Schlücke.',
      'bt_card_w122': 'Nenne 3 Früchte. Zögern = 2 trinken.',
      'bt_card_w123': 'Jeder mit Bargeld im Portemonnaie trinkt 2.',
      'bt_card_w124': 'Wenn du aus einer Dose trinkst, nimm 2 Schlücke.',
      'bt_card_p100':
          'Gruppen-Cheers! Alle stehen auf, jubeln und nehmen 1 Schlücke.',
      'bt_card_p101':
          'Schlage ein Rad (oder versuche es). Weigerung = 4 trinken.',
      'bt_card_p102': 'Starte eine Polonaise! Wer nicht mitmacht, trinkt 3.',
      'bt_card_p103': 'Du bist der Party King/Queen. Verteile 4 Schlücke.',
      'bt_card_p104':
          'Tu so, als würdest du einen riesigen Ballon aufblasen, bis er platzt. Oder 3 trinken.',
      'bt_card_p105': 'Alle posieren verrückt. Die schlechteste Pose trinkt 3.',
      'bt_card_p106': 'Rappe 4 Zeilen. Reimen sie sich nicht, trinke 4.',
      'bt_card_p107': 'Nenne 3 Trinkspiele. Zu langsam? Trinke 3 Schlücke.',
      'bt_card_p108':
          'Luftgitarren-Solo! Die beste Performance verteilt 3 Schlücke.',
      'bt_card_p109': 'Spiele eine extrem unpassende Szene. Cringe? Trinke 4.',
      'bt_card_p110': 'Tausche den Platz mit der Person links von dir.',
      'bt_card_p111': 'Leere dein Glas auf Ex! Oder nimm 5 Strafschlücke.',
      'bt_card_p112':
          'Brülle wie ein Löwe die Person gegenüber an. Gelacht? 2 trinken.',
      'bt_card_p113': 'Stille Bibliothek! Der lauteste Atmer trinkt 2.',
      'bt_card_p114': 'Mache 5 Liegestütze. Geht nicht? Trinke 3.',
      'bt_card_p115': 'Zieh ein Kleidungsstück aus oder trinke 4.',
      'bt_card_p116':
          'Wirf imaginäres Konfetti und schreie Wooo! Trinke trotzdem 1.',
      'bt_card_p117': 'Jeder, der seit 3h nichts gegessen hat, trinkt 2.',
      'bt_card_p118':
          'Die Person mit den meisten leeren Flaschen in der Nähe trinkt 3.',
      'bt_card_p119': 'Trinke 5 Sekunden lang ohne Absetzen!',
      'bt_card_p120': 'Jongliere mit 3 Dingen. Sofort fail = 3 trinken.',
      'bt_card_p121': 'Wer gerade ein Pflaster trägt, nimmt 2 Schlücke.',
      'bt_card_p122':
          'Du bist der Held! Bewahre den nächsten vor seiner Strafe.',
      'bt_card_p123': 'Flüstere für die nächsten 2 Runden.',
      'bt_card_p124': 'Lache 10s lang absolut irre. Weigerung = 3 Schlücke.',
      'bt_card_h100':
          'Demonstriere einen Kuss auf deinem Handrücken. Langweilig? Trinke 4.',
      'bt_card_h101':
          'Zeige der Gruppe dein aufreizendstes Foto. Oder trinke 5.',
      'bt_card_h102':
          'Augenkontakt aufbauen und langsam auf die Lippe beißen. Fehler? 3 trinken.',
      'bt_card_h103':
          'Beschreibe deine ultimative Fantasie in 3 Worten. Oder trinke 4.',
      'bt_card_h104':
          'Twerke 10 Sekunden lang. Wenn du lachst oder weigerst, Glas exen.',
      'bt_card_h105':
          'Nimm einen Eiswürfel und reibe ihn über deinen Hals. Oder trinke 3.',
      'bt_card_h106':
          'Flüstere deinem Nachbarn etwas extrem Schmutziges. Oder trinke 4.',
      'bt_card_h107':
          'Iss verführerisch ein Stück Obst oder Luft. Fail = 3 trinken.',
      'bt_card_h108':
          'Spende jemandem einen kurzen Lapdance. Weigerung = 6 Schlücke.',
      'bt_card_h109':
          'Nenne eine Sache, die du im Bett liebst. Zu still = trinke 5.',
      'bt_card_h110':
          'Knöpfe ein Kleidungsstück auf. Falls unmöglich, trinke 4.',
      'bt_card_h111':
          'Trinke die nächsten 3 Schlücke aus dem Glas von jemand anderem.',
      'bt_card_h112':
          'Lecke provokant deine Lippen, wenn jemand 2 Runden lang deinen Namen sagt.',
      'bt_card_h113':
          'Gestehe, mit wem du dich nur basierend auf dem Aussehen einlassen würdest.',
      'bt_card_h114': 'Jeder, der nackt duscht (offensichtlich), trinkt 2.',
      'bt_card_h115':
          'Tu so, als würdest du dich eincremen. Peinlich? Trinke 3.',
      'bt_card_h116':
          'Lass dir von jemandem Lippenbalsam/stift auftragen. Oder trinke 3.',
      'bt_card_h117':
          'Krable 10s wie eine rollige Katze. Weigerung = 5 Schlücke.',
      'bt_card_h118':
          'Ich habe noch nie ein Nude verschickt. Wenn doch, stolz trinken.',
      'bt_card_h119':
          'Mache ein heißes Foto von der Person gegenüber. Oder trinke 4.',
      'bt_card_h120': 'Nenne in 10s Synonyme für Brüste. Wer zögert, trinkt 3.',
      'bt_card_h121':
          'Klecker minimal und wisch es verführerisch weg. Oder trinke 3.',
      'bt_card_h122': 'Zeige der Gruppe dein Dating-App Profil. Oder trinke 5.',
      'bt_card_h123':
          'Hinterlasse einen Kussmund auf einer Serviette/Handrücken. Oder trinke 2.',
      'bt_card_h124':
          'Zeige dein verführerischstes Lächeln. Alle anderen trinken 1.',
      'bt_card_e100': 'Du bist verflucht! Ex dein Glas!',
      'bt_card_e101': 'Dreh dich 10x und gehe geradeaus. Fail = 4 Schlücke.',
      'bt_card_e102': 'Nimm einen Shot. Ja, sofort.',
      'bt_card_e103':
          'Lass dir eine winzige Stelle rasieren. Oder ex dein Glas!',
      'bt_card_e104':
          'Ruf deine Eltern an und sage, du schmeißt hin. Oder trinke 8.',
      'bt_card_e105':
          'Mixe 3 Getränke und probiere. Oder nimm 6 Strafschlücke.',
      'bt_card_e106': 'Abstimmung. Die nervigste Person gerade trinkt 5.',
      'bt_card_e107': 'Lass dir mit Edding ins Gesicht malen. Oder trinke 8.',
      'bt_card_e108':
          'Steck dir die Socke von jemand anderem in die Tasche für den Rest des Spiels.',
      'bt_card_e109': 'Kipp dein Getränk in den Ausguss. Nein? Trinke 10.',
      'bt_card_e110': 'Eiswürfel in die Hose. Oder Glas exen.',
      'bt_card_e111': 'Esse ein rohes Ei. Oder trinke 8.',
      'bt_card_e112': 'Lecke den Boden ab. Weigerung = 10 Schlücke.',
      'bt_card_e113': 'Sende jemandem 5€ per PayPal. Oder trinke 5.',
      'bt_card_e114': 'Lösche eine App, die die Gruppe wählt. Oder trinke 6.',
      'bt_card_e115': 'Lass dein Handy aus 1m aufs Sofa fallen. Oder trinke 3.',
      'bt_card_e116': 'Esse einen Löffel scharfe Soße. Oder Glas exen.',
      'bt_card_e117': 'Armdrücken gegen den Stärksten. Verlierer trinkt 5.',
      'bt_card_e118': 'Lass dir eine leichte Ohrfeige geben. Oder trinke 5.',
      'bt_card_e119': 'Trage dein Shirt für den Rest des Spiels falsch herum.',
      'bt_card_e120':
          'Lauf raus und brülle "IXH LIEBE NEXSCORE". Oder trinke 7.',
      'bt_card_e121': 'Kopf unter den Wasserhahn/Dusche. Oder Glas exen.',
      'bt_card_e122':
          'Trink Wasser aus deinem eigenen Schuh. Eklig? Dann trinke 10 Schlücke.',
      'bt_card_e123':
          'Brate jeden Einzelnen im Raum gnadenlos. Zu weich = 5 trinken.',
      'bt_card_e124': 'JEDER trinkt sein Getränk sofort auf Ex aus!!',

      // ── Resume
      'resume_game_title': 'Spiel fortsetzen',
      'resume_game_desc':
          'Möchtest du dein unvollendetes {0}-Spiel fortsetzen?',
      'resume': 'Fortsetzen',
      'discard': 'Verwerfen',
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
