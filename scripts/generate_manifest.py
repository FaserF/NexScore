import os
import json
import re
import yaml

def scan_dart_files(lib_path):
    file_tree = []
    features = {}
    core = {}
    shared_widgets = []
    models = []
    routes = []
    services = []
    providers = []

    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, start=os.path.dirname(lib_path)).replace('\\', '/')
                file_tree.append(rel_path)

                # Read file to extract classes/providers/routes
                try:
                    with open(full_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                except Exception:
                    content = ""

                # Extract class names
                class_matches = re.findall(r'\bclass\s+(\w+)', content)
                # Extract provider names (riverpod annotations or custom providers)
                provider_matches = re.findall(r'\b(?:final|const)?\s*(\w+Provider)\b', content)
                # Extract Riverpod @riverpod generators
                riverpod_matches = re.findall(r'@riverpod\s+(?:class|Raw<[^>]+>|AutoDispose|FutureOr)?\s*(\w+)', content)
                all_providers = list(set(provider_matches + [f"{r}Provider" for r in riverpod_matches]))

                file_info = {
                    "path": rel_path,
                    "classes": class_matches,
                    "providers": all_providers
                }

                # Categorize based on path
                parts = rel_path.split('/')
                if len(parts) > 2 and parts[1] == 'features':
                    feature_name = parts[2]
                    if feature_name not in features:
                        features[feature_name] = []
                    features[feature_name].append(file_info)
                elif len(parts) > 2 and parts[1] == 'core':
                    core_module = parts[2]
                    if core_module not in core:
                        core[core_module] = []
                    core[core_module].append(file_info)
                    
                    if core_module == 'services':
                        services.append(file_info)
                    elif core_module == 'providers':
                        providers.append(file_info)
                    elif core_module == 'models':
                        models.append(file_info)
                    elif core_module == 'router':
                        routes.append(file_info)
                elif len(parts) > 2 and parts[1] == 'shared':
                    shared_widgets.append(file_info)

    return {
        "file_tree": file_tree,
        "features": features,
        "core": core,
        "shared_widgets": shared_widgets,
        "models": models,
        "routes": routes,
        "services": services,
        "providers": providers
    }

def main():
    root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    lib_path = os.path.join(root_dir, 'nexscore', 'lib')
    pubspec_path = os.path.join(root_dir, 'nexscore', 'pubspec.yaml')

    print(f"Scanning library at: {lib_path}")
    scan_results = scan_dart_files(lib_path)

    # Read pubspec dependencies
    dependencies = {}
    dev_dependencies = {}
    if os.path.exists(pubspec_path):
        try:
            with open(pubspec_path, 'r', encoding='utf-8') as f:
                pubspec_data = yaml.safe_load(f)
                dependencies = pubspec_data.get('dependencies', {})
                dev_dependencies = pubspec_data.get('dev_dependencies', {})
        except Exception as e:
            print(f"Error reading pubspec.yaml: {e}")

    # Generate project_manifest.json
    manifest = {
        "project": "NexScore",
        "description": "Cross-platform score tracker and interactive engine for games like Sudoku (Campaign, Creator, Sync & Multiplayer), Wizard, Qwixx, Schafkopf, Kniffel, Phase 10, Rommé, Arschloch/President, SipDeck, BuzzTap, WayQuest, FactQuest, Volleyball, Darts, and Generic Score Tracking.",
        "dependencies": dependencies,
        "dev_dependencies": dev_dependencies,
        "features": scan_results["features"],
        "core_services": scan_results["services"],
        "core_providers": scan_results["providers"],
        "models": scan_results["models"],
        "routes": scan_results["routes"],
        "shared_widgets": scan_results["shared_widgets"],
        "file_tree": scan_results["file_tree"]
    }

    manifest_path = os.path.join(root_dir, 'project_manifest.json')
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2)
    print(f"Manifest written to: {manifest_path}")

    # Generate project_connections.json (key full-stack/cross-module feature flows)
    # Define primary game modes & their connections
    connections = {
        "multiplayer_flow": {
            "description": "Multiplayer gameplay sync & state management",
            "entry_point": "nexscore/lib/features/multiplayer/presentation/multiplayer_hub_screen.dart",
            "state_management": "nexscore/lib/core/multiplayer/providers/multiplayer_provider.dart",
            "core_services": [
                "nexscore/lib/core/multiplayer/multiplayer_service.dart",
                "nexscore/lib/core/multiplayer/firestore_multiplayer_impl.dart",
                "nexscore/lib/core/multiplayer/sync_engine.dart"
            ],
            "database_models": [
                "nexscore/lib/core/models/session_model.dart",
                "nexscore/lib/core/models/player_model.dart"
            ]
        },
        "game_creation_flow": {
            "description": "Creating and saving games (both local and multiplayer)",
            "entry_point": "nexscore/lib/features/games/presentation/game_setup_screen.dart",
            "state_management": "nexscore/lib/core/providers/active_players_provider.dart",
            "storage": "nexscore/lib/core/storage/database_service.dart",
            "database_models": [
                "nexscore/lib/core/models/session_model.dart",
                "nexscore/lib/core/models/player_model.dart"
            ]
        },
        "settings_sync_flow": {
            "description": "User preferences and settings synchronization",
            "entry_point": "nexscore/lib/features/settings/presentation/settings_screen.dart",
            "storage": "nexscore/lib/core/storage/state_persistence_service.dart",
            "services": [
                "nexscore/lib/core/theme/app_theme.dart",
                "nexscore/lib/core/i18n/app_localizations.dart"
            ]
        }
    }

    connections_path = os.path.join(root_dir, 'project_connections.json')
    with open(connections_path, 'w', encoding='utf-8') as f:
        json.dump(connections, f, indent=2)
    print(f"Connections written to: {connections_path}")

if __name__ == "__main__":
    main()
