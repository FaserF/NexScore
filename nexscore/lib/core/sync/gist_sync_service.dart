import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../error/failures.dart';
import '../error/result.dart';
import '../storage/database_service.dart';
import '../utils/logger.dart';

/// Service that backs up and restores NexScore data via a GitHub Gist.
///
/// After signing in with GitHub through Firebase Auth the OAuth access-token
/// is available on the [OAuthCredential].  We persist it in-memory for the
/// lifetime of the service and use it to call the GitHub Gist REST API.
class GistSyncService {
  static const _gistFileName = 'nexscore_backup.json';
  static const _gistDescription = 'NexScore – Score Tracker Backup';
  static const _apiBase = 'https://api.github.com';

  String? _accessToken;
  String? _gistId;

  // ──────────────────────────────────────────────────────────
  // Token management
  // ──────────────────────────────────────────────────────────

  /// Call this right after a successful GitHub sign-in to store the token.
  void setAccessToken(String token) {
    _accessToken = token;
    AppLogger.info('GitHub access-token stored', tag: 'GistSync');
  }

  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  // ──────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────

  /// Upload the current local database (players + sessions) as a Gist.
  Future<Result<void>> backup() async {
    if (!hasToken) {
      return const Result.failure(
        SyncFailure('No GitHub token. Please sign in with GitHub first.'),
      );
    }

    final stopwatch = Stopwatch()..start();
    try {
      final payload = await _buildPayload();

      // Check whether we already have a Gist
      _gistId ??= await _findExistingGist();

      if (_gistId != null) {
        await _updateGist(_gistId!, payload);
      } else {
        _gistId = await _createGist(payload);
      }

      AppLogger.info(
        'Gist backup complete',
        tag: 'GistSync',
        metadata: {'duration': '${stopwatch.elapsedMilliseconds}ms'},
      );
      return const Result.success(null);
    } catch (e, stack) {
      AppLogger.error(
        'Gist backup failed',
        tag: 'GistSync',
        error: e,
        stackTrace: stack,
      );
      return Result.failure(
        SyncFailure('Backup failed', error: e, stackTrace: stack),
      );
    }
  }

  /// Download data from the Gist and merge it into the local database.
  Future<Result<void>> restore() async {
    if (!hasToken) {
      return const Result.failure(
        SyncFailure('No GitHub token. Please sign in with GitHub first.'),
      );
    }

    final stopwatch = Stopwatch()..start();
    try {
      _gistId ??= await _findExistingGist();

      if (_gistId == null) {
        return const Result.failure(
          SyncFailure('No NexScore backup found on GitHub.'),
        );
      }

      final response = await http.get(
        Uri.parse('$_apiBase/gists/$_gistId'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        return Result.failure(
          SyncFailure('Failed to fetch Gist (${response.statusCode})'),
        );
      }

      final gist = jsonDecode(response.body) as Map<String, dynamic>;
      final files = gist['files'] as Map<String, dynamic>;
      final file = files[_gistFileName] as Map<String, dynamic>?;
      if (file == null) {
        return const Result.failure(
          SyncFailure('Gist exists but backup file not found.'),
        );
      }

      final content =
          jsonDecode(file['content'] as String) as Map<String, dynamic>;
      await _importData(content);

      AppLogger.info(
        'Gist restore complete',
        tag: 'GistSync',
        metadata: {'duration': '${stopwatch.elapsedMilliseconds}ms'},
      );
      return const Result.success(null);
    } catch (e, stack) {
      AppLogger.error(
        'Gist restore failed',
        tag: 'GistSync',
        error: e,
        stackTrace: stack,
      );
      return Result.failure(
        SyncFailure('Restore failed', error: e, stackTrace: stack),
      );
    }
  }

  // ──────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────

  Future<String> _buildPayload() async {
    final db = DatabaseService.instance;
    final players = await db.query('players');
    final sessions = await db.query('sessions');

    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'players': players,
      'sessions': sessions,
    };
    return jsonEncode(data);
  }

  Future<void> _importData(Map<String, dynamic> data) async {
    final db = DatabaseService.instance;

    final players = (data['players'] as List<dynamic>?) ?? [];
    for (final p in players) {
      final map = Map<String, dynamic>.from(p as Map);
      await db.insert('players', map);
    }

    final sessions = (data['sessions'] as List<dynamic>?) ?? [];
    for (final s in sessions) {
      final map = Map<String, dynamic>.from(s as Map);
      await db.insert('sessions', map);
    }
  }

  /// Search authenticated user's Gists for one containing our backup file.
  Future<String?> _findExistingGist() async {
    final response = await http.get(
      Uri.parse('$_apiBase/gists?per_page=100'),
      headers: _headers,
    );
    if (response.statusCode != 200) return null;

    final gists = jsonDecode(response.body) as List<dynamic>;
    for (final g in gists) {
      final files =
          (g as Map<String, dynamic>)['files'] as Map<String, dynamic>;
      if (files.containsKey(_gistFileName)) {
        return g['id'] as String;
      }
    }
    return null;
  }

  Future<String> _createGist(String payload) async {
    final body = jsonEncode({
      'description': _gistDescription,
      'public': false,
      'files': {
        _gistFileName: {'content': payload},
      },
    });
    final response = await http.post(
      Uri.parse('$_apiBase/gists'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 201) {
      throw Exception('Create Gist failed (${response.statusCode})');
    }
    final created = jsonDecode(response.body) as Map<String, dynamic>;
    return created['id'] as String;
  }

  Future<void> _updateGist(String gistId, String payload) async {
    final body = jsonEncode({
      'files': {
        _gistFileName: {'content': payload},
      },
    });
    final response = await http.patch(
      Uri.parse('$_apiBase/gists/$gistId'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 200) {
      throw Exception('Update Gist failed (${response.statusCode})');
    }
  }
}
