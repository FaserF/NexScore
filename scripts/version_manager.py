import argparse
import re
import sys
import subprocess

def get_latest_tag():
    try:
        result = subprocess.run(
            ['git', 'tag', '--sort=-v:refname'],
            capture_output=True,
            text=True,
            check=True
        )
        tags = result.stdout.strip().split('\n')
        # Filter for version-like tags
        version_tags = [t for t in tags if re.match(r'^v?\d+\.\d+\.\d+', t)]
        return version_tags[0] if version_tags else "v0.0.0"
    except Exception:
        return "v0.0.0"

def parse_version(tag):
    # Matches v1.2.3, v1.2.3b1, v1.2.3-dev4-sha
    pattern = r'^v?(\d+)\.(\d+)\.(\d+)(?:(b|[-+]dev|[-+]rc)(\d+))?(?:-([a-z0-9]+))?$'
    match = re.match(pattern, tag)
    if not match:
        return [0, 0, 0, None, -1, None] # -1 means no suffix

    major = int(match.group(1))
    minor = int(match.group(2))
    patch = int(match.group(3))
    prefix = match.group(4)
    suffix_num = int(match.group(5)) if match.group(5) is not None else -1
    commit_sha = match.group(6)

    return [major, minor, patch, prefix, suffix_num, commit_sha]

def format_version(major, minor, patch, prefix, suffix_num, commit_sha=None):
    base = f"{major}.{minor}.{patch}"
    if prefix:
        if "dev" in prefix:
            ver = f"{base}-dev{suffix_num}"
            if commit_sha:
                ver += f"-{commit_sha}"
            return ver
        elif prefix == "b":
            return f"{base}b{suffix_num}"
    return base

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--release-type', choices=['stable', 'beta', 'dev'], required=True)
    parser.add_argument('--bump-type', choices=['major', 'minor', 'patch', 'none'], required=True)
    parser.add_argument('--commit-sha', default='')
    args = parser.parse_args()

    current_tag = get_latest_tag()
    major, minor, patch, prefix, suffix_num, _ = parse_version(current_tag)

    current_is_beta = (prefix == 'b')
    current_is_dev = (prefix and 'dev' in prefix)
    current_is_stable = not prefix

    # 1. Version Part Bumps
    if args.bump_type == 'major':
        major += 1
        minor = 0
        patch = 0
        suffix_num = -1
    elif args.bump_type == 'minor':
        minor += 1
        patch = 0
        suffix_num = -1
    elif args.bump_type == 'patch':
        # Special case: if already in pre-release, 'patch' bumps suffix (user example)
        if not current_is_stable:
            suffix_num += 1
        else:
            patch += 1
            suffix_num = -1
    elif args.bump_type == 'none':
        if not current_is_stable:
            suffix_num += 1
        else:
            # stable -> something else on 'none'?
            # User example: 1.0.0 -> Dev None -> 1.0.1-dev0
            patch += 1
            suffix_num = -1

    # 2. Type Transition and Suffix management
    target_prefix = None
    if args.release_type == 'beta':
        target_prefix = 'b'
    elif args.release_type == 'dev':
        target_prefix = '-dev'

    # If transitioning type OR if we just bumped version part and need fresh suffix
    if args.release_type == 'stable':
        target_prefix = None
        suffix_num = -1
    else:
        # We are targetting a pre-release
        if suffix_num == -1:
            suffix_num = 0
        # If type changed (e.g. beta -> dev), suffix stays or resets?
        # Usually resets if version part changed, stays if just type swap on same version.
        # But we'll follow simple: if suffix_num was -1, it's 0.

    # Forced beta if < 1.0.0
    if major == 0 and args.release_type == 'stable':
        target_prefix = 'b'
        if suffix_num == -1: suffix_num = 0

    # Shorten SHA if provided
    short_sha = args.commit_sha[:7] if args.commit_sha else None

    version_name = format_version(major, minor, patch, target_prefix, suffix_num, short_sha if args.release_type == 'dev' else None)
    tag_name = f"v{version_name}"

    # Check for pre-release status for GitHub
    is_prerelease = "true" if (target_prefix or major == 0) else "false"

    # Docker tag must be lowercase and not contain '+'
    docker_tag = version_name.lower().replace('+', '-')
    # Further sanitize for Docker (only alpha, num, '.', '-', '_')
    docker_tag = re.sub(r'[^a-z0-9._-]', '-', docker_tag)

    # Print for GitHub Actions
    print(f"VERSION_NAME={version_name}")
    print(f"TAG_NAME={tag_name}")
    print(f"DOCKER_TAG={docker_tag}")
    print(f"IS_PRERELEASE={is_prerelease}")

if __name__ == "__main__":
    main()
