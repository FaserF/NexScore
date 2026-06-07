import argparse
import re
import subprocess
import sys

# Noise filter patterns
NOISE_PATTERNS = [
    r'^\s*$',
    r'^(Update|Aktualisier[et]?|Add|Adds|Adde|Delete|Deletes|Remove|Removes|Rename|Renames|Move|Moves|Fix|Edit|Change|Modify)\s+[\w\-\.\/]+\.\w{1,10}\s*$',
    r'^Merge (pull request|branch|remote-tracking branch)\b',
    r'^Merge from\b',
    r'^(chore|build)(\([^)]*\))?:\s*(bump|release|version)\b',
    r'^(bump|release)(\s+version)?\s+v?\d',
    r'^v?\d+\.\d+\.\d+\s*$',
    r'^\[skip[- ]ci\]',
    r'^chore: regenerate (manifest|connections|changelog)\b',
    r'^chore: update (project_manifest|project_connections)\b',
    r'^(auto.?generated?|automated?|bot:)\b',
    r'^Revert "Revert',
    r'^Initial commit\s*$',
    r'^WIP\b',
    r'^wip\b',
    r'^.{1,3}$',
    r'\[skip[- ]ci\]\s*$'
]

CATEGORY_ORDER = ['breaking', 'feat', 'fix', 'security', 'perf', 'refactor', 'api', 'db', 'ui', 'docs', 'test', 'ci', 'chore', 'other']

CATEGORY_EMOJI = {
    'breaking': '💥 Breaking Changes',
    'feat': '✨ New Features',
    'fix': '🐛 Bug Fixes',
    'security': '🔒 Security',
    'perf': '⚡ Performance',
    'refactor': '♻️ Code Improvements',
    'api': '🔌 API Changes',
    'db': '🗄️ Database',
    'ui': '🎨 UI / UX',
    'docs': '📚 Documentation',
    'test': '🧪 Tests',
    'ci': '🔄 CI / CD',
    'chore': '🔧 Maintenance',
    'other': '📦 Other Changes'
}

TYPE_MAP = {
    'feat': 'feat',
    'feature': 'feat',
    'fix': 'fix',
    'bugfix': 'fix',
    'hotfix': 'fix',
    'security': 'security',
    'sec': 'security',
    'perf': 'perf',
    'optim': 'perf',
    'refactor': 'refactor',
    'refact': 'refactor',
    'api': 'api',
    'db': 'db',
    'migration': 'db',
    'migrate': 'db',
    'schema': 'db',
    'ui': 'ui',
    'style': 'ui',
    'ux': 'ui',
    'docs': 'docs',
    'doc': 'docs',
    'test': 'test',
    'tests': 'test',
    'ci': 'ci',
    'cd': 'ci',
    'build': 'ci',
    'chore': 'chore',
    'maint': 'chore',
    'infra': 'chore',
    'deps': 'chore',
    'dep': 'chore',
    'bump': 'chore',
    'revert': 'fix'
}

SCOPE_MAP = {
    'api': 'api',
    'endpoint': 'api',
    'router': 'api',
    'route': 'api',
    'db': 'db',
    'database': 'db',
    'migration': 'db',
    'schema': 'db',
    'model': 'db',
    'ui': 'ui',
    'frontend': 'ui',
    'fe': 'ui',
    'component': 'ui',
    'modal': 'ui',
    'dashboard': 'ui',
    'security': 'security',
    'auth': 'security',
    'authz': 'security',
    'authn': 'security',
    'jwt': 'security',
    'rbac': 'security',
    'ci': 'ci',
    'cd': 'ci',
    'workflow': 'ci',
    'docker': 'ci',
    'dockerfile': 'ci',
    'actions': 'ci'
}

MAX_PER_SECTION = 15
NEVER_COLLAPSE = {'breaking', 'security'}

def get_tags():
    try:
        result = subprocess.run(
            ['git', 'tag', '--sort=-v:refname'],
            capture_output=True,
            text=True,
            check=True
        )
        tags = [t.strip() for t in result.stdout.split('\n') if t.strip()]
        return tags
    except Exception:
        return []

def get_start_tag(tags, release_type):
    if not tags:
        return None
    
    # regex matches:
    # Stable: v1.2.3 (only numbers)
    # Beta: v1.2.3b1 (includes b suffix)
    # Dev: v1.2.3-dev4 (any suffix)
    stable_pattern = r'^v?\d+\.\d+\.\d+$'
    beta_pattern = r'^v?\d+\.\d+\.\d+(-beta\.\d+)?$'
    
    if release_type == 'stable':
        for t in tags:
            if re.match(stable_pattern, t):
                return t
    elif release_type == 'beta':
        for t in tags:
            if re.match(beta_pattern, t):
                return t
    else:
        # dev or any other: return most recent tag of any format
        for t in tags:
            if re.match(r'^v?\d+\.\d+\.\d+', t):
                return t
    return None

def normalize_key(msg):
    n = msg.lower()
    # Strip conventional commit prefix
    n = re.sub(r'^(feat|fix|docs|style|refactor|perf|test|chore|ci|security|build|api|db|ui|ux|revert)(\([^)]*\))?(!)?:\s*', '', n)
    # Strip punctuation
    n = re.sub(r'[\.\!\?\,\;\:\"\'`]', '', n)
    # Strip common articles / prepositions
    n = re.sub(r'\b(the|a|an|for|of|in|to|with|from|on|at|by)\b', '', n)
    # Normalize whitespaces
    n = re.sub(r'\s+', ' ', n)
    return n.strip()

def format_item(display, hashes, repo):
    if hashes:
        links = []
        for h in hashes:
            if repo:
                links.append(f"[{h}](https://github.com/{repo}/commit/{h})")
            else:
                links.append(f"`{h}`")
        return f"{display} ({', '.join(links)})"
    return display

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--release-type', choices=['stable', 'beta', 'dev'], required=True)
    parser.add_argument('--repo', default='')
    parser.add_argument('--output-file', default='')
    args = parser.parse_args()

    tags = get_tags()
    start_tag = get_start_tag(tags, args.release_type)

    if start_tag:
        git_cmd = ['git', 'log', f"{start_tag}..HEAD", '--pretty=format:%h %s']
    else:
        git_cmd = ['git', 'log', '--pretty=format:%h %s', '--max-count=200']

    try:
        result = subprocess.run(git_cmd, capture_output=True, text=True, check=True)
        commit_lines = [line.strip() for line in result.stdout.split('\n') if line.strip()]
    except Exception as e:
        commit_lines = []

    buckets = {k: [] for k in CATEGORY_ORDER}
    seen_items = {}
    total_raw = len(commit_lines)

    for line in commit_lines:
        match = re.match(r'^([0-9a-fA-F]+)\s+(.*)$', line)
        if match:
            commit_hash = match.group(1)
            msg = match.group(2).strip()
        else:
            commit_hash = ""
            msg = line.strip()

        if not msg:
            continue

        # Noise filter
        skip = False
        for pattern in NOISE_PATTERNS:
            if re.search(pattern, msg):
                skip = True
                break
        if skip:
            continue

        # Parse conventional commit
        bucket = 'other'
        display = msg
        is_break = False

        # Pattern: type[(scope)][!]: description
        conv_match = re.match(r'^([A-Za-z][A-Za-z0-9_-]*)(\([^)]*\))?(!)?:\s*(.+)$', msg)
        if conv_match:
            raw_type = conv_match.group(1).lower()
            raw_scope = conv_match.group(2).replace('(', '').replace(')', '').lower().strip() if conv_match.group(2) else ''
            is_break = bool(conv_match.group(3))
            desc = conv_match.group(4).strip()

            # Scope override wins over type map
            if raw_scope and raw_scope in SCOPE_MAP:
                bucket = SCOPE_MAP[raw_scope]
            elif raw_type in TYPE_MAP:
                bucket = TYPE_MAP[raw_type]

            # Capitalize first letter of description
            desc_cap = desc[0].upper() + desc[1:] if desc else desc
            if raw_scope:
                display = f"**{raw_scope}:** {desc_cap}"
            else:
                display = desc_cap
        else:
            display = msg[0].upper() + msg[1:] if msg else msg

        norm_key = normalize_key(display)

        if is_break:
            break_display = f"**{display}**"
            break_key = f"breaking:{norm_key}"
            if break_key in seen_items:
                if commit_hash and commit_hash not in seen_items[break_key]['hashes']:
                    seen_items[break_key]['hashes'].append(commit_hash)
            else:
                break_item = {'display': break_display, 'hashes': [commit_hash] if commit_hash else []}
                seen_items[break_key] = break_item
                buckets['breaking'].append(break_item)

        if norm_key in seen_items:
            if commit_hash and commit_hash not in seen_items[norm_key]['hashes']:
                seen_items[norm_key]['hashes'].append(commit_hash)
            continue

        item = {'display': display, 'hashes': [commit_hash] if commit_hash else []}
        seen_items[norm_key] = item
        buckets[bucket].append(item)

    # Build output
    out = []
    has_any = False
    filtered_count = sum(len(buckets[k]) for k in CATEGORY_ORDER)

    # Breaking changes callout
    if buckets['breaking']:
        has_any = True
        out.append('> [!CAUTION]')
        out.append('> **This release contains breaking changes. Please review before updating.**')
        out.append('>')
        for item in buckets['breaking']:
            formatted = format_item(item['display'], item['hashes'], args.repo)
            out.append(f"> - {formatted}")
        out.append('')

    # Per-category sections
    for key in CATEGORY_ORDER:
        if key == 'breaking':
            continue
        bucket_items = buckets[key]
        if not bucket_items:
            continue
        has_any = True

        out.append(f"### {CATEGORY_EMOJI[key]}")
        out.append('')

        collapse = len(bucket_items) > MAX_PER_SECTION and key not in NEVER_COLLAPSE

        if collapse:
            for i in range(MAX_PER_SECTION):
                formatted = format_item(bucket_items[i]['display'], bucket_items[i]['hashes'], args.repo)
                out.append(f"- {formatted}")
            remaining = len(bucket_items) - MAX_PER_SECTION
            out.append('')
            out.append("<details>")
            out.append(f"<summary>Show {remaining} more changes…</summary>")
            out.append('')
            for i in range(MAX_PER_SECTION, len(bucket_items)):
                formatted = format_item(bucket_items[i]['display'], bucket_items[i]['hashes'], args.repo)
                out.append(f"- {formatted}")
            out.append('')
            out.append("</details>")
        else:
            for item in bucket_items:
                formatted = format_item(item['display'], item['hashes'], args.repo)
                out.append(f"- {formatted}")
        out.append('')

    if not has_any:
        out.append('> *No categorised changes found in this release.*')
        out.append('> Most commits were maintenance, dependency updates, or automated changes.')
        out.append('')

    # Footer
    range_str = f"{start_tag}..HEAD" if start_tag else "all history"
    out.append('---')
    if total_raw > 0:
        out.append(f"*{filtered_count} significant changes from {total_raw} total commits since `{start_tag}`.*")
    else:
        out.append(f"*Changelog generated from `{range_str}`.*")

    output_content = '\n'.join(out)

    if args.output_file:
        with open(args.output_file, 'w', encoding='utf-8') as f:
            f.write(output_content)
    else:
        print(output_content)

if __name__ == '__main__':
    main()
