#!/usr/bin/env bash
# Per-edit token diff: did this edit actually shrink the file?
#
# count_tokens is stateless, so measuring an edit means counting both versions
# and subtracting. This counts the committed version and the working-tree
# version of each path and prints the delta.
#
# Counting shares check-context-budget.sh's core, count-tokens.py.
#
# Usage:
#   .claude/scripts/token-diff.sh plugins/joe-bag-of-tricks/skills/writing-skills/SKILL.md
#   .claude/scripts/token-diff.sh --rev main --model claude-opus-5 PATH...
#   .claude/scripts/token-diff.sh          # every path changed vs HEAD

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

MODEL="claude-opus-5"
REV="HEAD"
PATHS=()

usage() {
    sed -n '2,14p' "$0" | sed 's/^# \?//'
    exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model) MODEL="$2"; shift 2 ;;
        --rev)   REV="$2"; shift 2 ;;
        -h|--help) usage 0 ;;
        -*) echo "unknown argument: $1" >&2; usage 1 ;;
        *) PATHS+=("$1"); shift ;;
    esac
done

for tool in jq git python3; do
    command -v "$tool" >/dev/null || { echo "required tool not found: $tool" >&2; exit 1; }
done

# Arguments are relative to the caller's directory, but everything below runs
# from the repo root, so rewrite them before the cd. Without this, running from
# inside a skill directory silently reads as "nothing on either side" — +0.
if [[ ${#PATHS[@]} -gt 0 ]]; then
    relative=()
    for path in "${PATHS[@]}"; do
        absolute="$(realpath -m -- "$path")"
        case "$absolute" in
            "$REPO_ROOT"/*) relative+=("${absolute#"$REPO_ROOT"/}") ;;
            *) echo "path is outside ${REPO_ROOT}: $path" >&2; exit 1 ;;
        esac
    done
    PATHS=("${relative[@]}")
fi

cd "$REPO_ROOT"

if [[ ${#PATHS[@]} -eq 0 ]]; then
    mapfile -t PATHS < <(git diff --name-only "$REV")
    [[ ${#PATHS[@]} -gt 0 ]] || { echo "no paths changed vs ${REV}"; exit 0; }
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Two blobs per path, in one request: "<rev>:path" and "worktree:path". A path
# missing on one side counts as empty, so an add or a delete reads as the whole
# file gained or lost. Missing on both sides is a bad path, not a zero delta.
blobs="{}"
for path in "${PATHS[@]}"; do
    if ! git show "${REV}:${path}" >"${WORK}/before" 2>/dev/null; then
        : >"${WORK}/before"
        [[ -f "$path" ]] || { echo "path is in neither ${REV} nor the working tree: $path" >&2; exit 1; }
    fi
    if [[ -f "$path" ]]; then
        cp -f "$path" "${WORK}/after"
    else
        : >"${WORK}/after"
    fi
    blobs="$(jq -n \
        --argjson acc "$blobs" \
        --arg path "$path" \
        --rawfile before "${WORK}/before" \
        --rawfile after "${WORK}/after" \
        '$acc + {"before:\($path)": $before, "after:\($path)": $after}')"
done

counts="$(printf '%s' "$blobs" | "${SCRIPT_DIR}/count-tokens.py" "$MODEL")"

echo "Token delta vs ${REV} (model=${MODEL})"
echo
printf '%8s %8s %8s  %s\n' "$REV" "WORKTREE" "DELTA" "PATH"
total=0
for path in "${PATHS[@]}"; do
    read -r before after < <(jq -r --arg p "$path" '"\(.["before:" + $p]) \(.["after:" + $p])"' <<<"$counts")
    delta=$((after - before))
    total=$((total + delta))
    printf '%8s %8s %+8d  %s\n' "$before" "$after" "$delta" "$path"
done

echo
printf 'net: %+d token(s)\n' "$total"
