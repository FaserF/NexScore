# AI Agent Reference for NexScore

---

## Token Efficiency Rules (CRITICAL — Read First)

These rules apply to **every response** without exception:

1. **Output minimal prose.** Bullet points only. No introductory sentences, no filler, no "Great question!", no "As requested".
2. **No walkthrough unless explicitly asked.** Never create or update `walkthrough.md` unless the user writes "walkthrough" or "summary" in their request.
3. **No implementation plan unless complex.** Skip planning artifacts for simple tweaks, single-file edits, bug fixes, or minor features. Plan only for major architectural changes.
4. **Short change summaries only.** After making changes, output ≤5 bullet points describing *what* changed and *why* — never a line-by-line description.
5. **No repeating file content.** Never echo back code you just wrote or edited. Reference filenames with links instead.
6. **No tool-call narration.** Do not describe what tool you are about to call. Just call it.
7. **Targeted file reads only.** Use `grep_search` or `view_file` with `StartLine`/`EndLine` to read only the relevant section. Never view an entire large file unless strictly necessary.
8. **Use the manifest first.** Before exploring the codebase, read `project_manifest.json` and `project_connections.json`. Do not walk directories recursively.
9. **Parallel tool calls.** Fire all independent tool calls in a single block. Never sequence calls that can run simultaneously.
10. **No re-summarizing artifacts.** After creating or updating an artifact, do NOT restate its contents — just link to it and note any open questions.
11. **Skip trivial confirmations.** Do not ask "Would you like me to proceed?" for obvious next steps. Just do them.
12. **No closing pleasantries.** End your response after the change summary. No "Let me know if you have questions!" etc.
13. **Omit unchanged layers.** If a change only affects a local database helper, do not mention firebase or UI layers unless they are also modified.
14. **Reuse subagents.** Send follow-up tasks to an existing idle subagent instead of spawning a new one.
15. **Suppress test output noise.** When running `flutter test`, only report failures. Do not paste successful test output unless the user asks.
16. **Delegate with subagents.** For any research-heavy, multi-file, or parallelizable task, spin up a subagent instead of doing it inline. This keeps your own context lean and reduces token usage for the main conversation.
17. **Reuse idle subagents.** Send follow-up instructions to an already-running subagent via `send_message` — never spawn a new one for the same task thread.
18. **Don't poll subagents.** After launching a subagent, stop calling tools. The system wakes you automatically when the subagent replies.
19. **Subagent scope = minimal.** Give each subagent one focused goal. Never dump the entire task into a single subagent prompt.
20. **Prefer `research` subagent for read-only work.** Codebase exploration, grep searches, file reads, and web lookups should go to the `research` subagent so the main agent stays focused on writing code.
21. **Prefer `self` subagent for isolated execution.** Use the `self` subagent for tasks that need write access in a separate context (e.g. branch workspace edits, test runs, parallel fixes on different modules).

---

## Subagent Strategy (Antigravity 2.0)

Use subagents proactively whenever a task has independent subtasks, requires heavy research, or would bloat the main context:

| Scenario | Action |
|---|---|
| Reading/searching codebase before coding | Delegate to `research` subagent |
| Parallel bug fixes across multiple games/features | Spawn one `self` subagent per feature with `branch` workspace |
| Exploring docs / web while coding continues | Delegate to `research` subagent, continue main task |
| Running tests after a fix | Delegate to `self` subagent, await result |
| Long GitHub API analysis + code fix | Research subagent reads issues; main agent applies fix |

**Workspace modes:**

- `inherit` — shares parent workspace (default, for read or simple edits)
- `branch` — isolated copy (for concurrent writes to same files)
- `share` — shared repo, independent branch (for parallel feature work)

**Never** do sequential research → code → test all inline in the main agent when any step can be offloaded.

---

## Project Manifest & Connection Map (Single Source of Truth)

Read these before exploring the codebase — they cover the entire file tree, features, models, and feature flows:

- **Manifest**: `project_manifest.json` — dependencies, core services, features, routes, shared widgets, and file tree.
- **Connections**: `project_connections.json` — file-level mapping for specific cross-module feature flows (e.g., multiplayer, game creation, settings).

---

## Codebase Architecture

The app is built using Flutter/Dart with Riverpod for state management.

### Lib Path (`/nexscore/lib`)

| Area | Path | Description |
|---|---|---|
| App entry | `nexscore/lib/main.dart` | Initializes routing, firebase, local DB, settings, etc. |
| Router | `nexscore/lib/core/router/` | `app_router.dart` controls screen transitions & path navigation. |
| Storage | `nexscore/lib/core/storage/` | SQLite / State Persistence services. |
| Services | `nexscore/lib/core/services/` | Audio, Notifications, TTS, and Share services. |
| Core Firebase | `nexscore/lib/core/firebase/` | Firebase configuration and Firestore wrappers. |
| Sync Engine | `nexscore/lib/core/sync/` | Sync logic for online/offline play states. |
| Features | `nexscore/lib/features/` | Game modules, settings page, and multiplayer setup. |
| Shared Widgets | `nexscore/lib/shared/widgets/` | Custom UI components reused across pages. |

---

## CLI Commands

All commands should run in the appropriate directories.

| Task | Command | Dir |
|---|---|---|
| Run app (Desktop/Web/Device) | `flutter run` | `/nexscore` |
| Run build runner (gen providers) | `dart run build_runner build --delete-conflicting-outputs` | `/nexscore` |
| Run all unit tests | `flutter test` | `/nexscore` |
| Run specific test file | `flutter test test/<path_to_test>_test.dart` | `/nexscore` |
| Flutter formatting | `flutter format .` | `/nexscore` |
| Flutter analyzer / linter | `flutter analyze` | `/nexscore` |
| Regenerate project manifest | `python scripts/generate_manifest.py` | Root |

---

## Coding Rules

### State Management (Riverpod)

- **Prefer Generators**: Write Riverpod providers using `@riverpod` annotations and the `riverpod_generator`.
- **Ref Avoidance**: Keep UI builds lean. Read states using `ref.watch` in build methods and `ref.read` in event handlers.

### Clean Data Modeling

- All database models (SQL or Firestore) must include proper serialization (`fromJson` and `toJson`).
- Ensure null safety is properly handled in mapping, especially for legacy multiplayer databases.

### Quality & Code Hygiene

- **Traceback Preservation**: NEVER use `raise e` in Python scripts or `throw e` in Dart if it discards the original stack trace. Always throw with context or rethrow.
- **Silent Failure Prohibition**: Catch blocks must not be empty. Log errors or report them gracefully to the user using the snackbar/notification framework.
- **Async Safety**: Always await Futures when executing asynchronous operations. Especially critical for `Database` writes and `SharedPreferences` writes.

### Testing

- **Local Scope**: Always target only the relevant test file for the feature you modified. Do not execute the entire suite (`flutter test`) unless requested.
- If a test fails, run the build runner first to see if generated files need updating.

---

## Communication Rules (Summary)

| Rule | Behavior |
|---|---|
| Response length | Bullet points, ≤5 items per change |
| Walkthrough artifact | Only if user explicitly requests it |
| Implementation plan | Only for major architectural changes |
| Asking for confirmation | Never for obvious steps |
| Test output | Failures only |
| Repeating written code | Never |
| Closing remarks | None |
| Language defaults | Code, docs, comments, and AI responses must default to English (EN) unless requested otherwise |

---

## Script Rules

- **Temporary scripts & files** (one-off, session-only use): place in `/scratch/` at repo root. Never commit these. They will not be tracked or reviewed.
- **Reusable scripts**: place in `/scripts/` — never in the repo root directory.
- **No credentials in reusable scripts**: read credentials and environments from environment variables.
