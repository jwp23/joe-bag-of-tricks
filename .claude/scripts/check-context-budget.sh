#!/usr/bin/env bash
# Context-budget gate: measures the plugin surface that is loaded into EVERY
# session and fails when it exceeds the committed budget.
#
# Three tiers, measured separately because only the first two are the recurring
# per-session tax:
#   1. descriptions — the skill descriptions in the available-skills list
#   2. hook         — what the SessionStart hook injects (using-skills, verbatim)
#   3. bodies       — every SKILL.md body, loaded on demand only
#
# Tiers 1+2 are gated. Tier 3 is reported for information and never fails.
#
# Counting runs through count-tokens.py (the Anthropic count_tokens endpoint).
# Counts are model-specific; chars/4 and tiktoken are OpenAI heuristics and
# undercount Claude markdown, so they are never acceptable here.
#
# Cost: three count_tokens calls. The endpoint is not billed as inference.
#
# Usage:
#   .claude/scripts/check-context-budget.sh
#   .claude/scripts/check-context-budget.sh --budget 3000 --model claude-opus-5

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PLUGIN_DIR="${REPO_ROOT}/plugins/joe-bag-of-tricks"
SKILLS_DIR="${PLUGIN_DIR}/skills"
NAMESPACE="joe-bag-of-tricks"

MODEL="claude-opus-5"

# Committed budget for tiers 1+2, in claude-opus-5 tokens. Set from the measured
# surface at the time it was committed — 1,284 descriptions + 2,132 hook = 3,416
# — plus ~20% headroom, which is room for two or three more skills before anyone
# has to think about it. Raising this is a decision, not a formality: every token
# here is paid on every session, before the user has said anything.
BUDGET=4100

usage() {
    sed -n '2,21p' "$0" | sed 's/^# \?//'
    exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --budget) BUDGET="$2"; shift 2 ;;
        --model)  MODEL="$2"; shift 2 ;;
        -h|--help) usage 0 ;;
        *) echo "unknown argument: $1" >&2; usage 1 ;;
    esac
done

for tool in jq python3; do
    command -v "$tool" >/dev/null || { echo "required tool not found: $tool" >&2; exit 1; }
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The description as the available-skills list renders it: single-line YAML,
# optionally double-quoted, read from the frontmatter block only.
description_for() {
    local file="$1" line
    line="$(awk '
        NR == 1 && $0 !~ /^---/ { exit }
        NR == 1 { next }
        /^---/ { exit }
        /^description:[[:space:]]/ { sub(/^description:[[:space:]]*/, ""); print; exit }
    ' "$file")"
    if [[ "$line" == \"*\" ]]; then
        line="${line#\"}"
        line="${line%\"}"
        line="${line//\\\"/\"}"
        line="${line//\\\\/\\}"
    fi
    printf '%s' "$line"
}

# Tier 1. A skill with `disable-model-invocation: true` is kept out of the
# available-skills list on purpose, so its description costs nothing per session.
listed=0
for dir in "${SKILLS_DIR}"/*/; do
    skill="$(basename "$dir")"
    [[ -f "${dir}SKILL.md" ]] || continue
    cat "${dir}SKILL.md" >>"${WORK}/bodies.txt"
    grep -qE '^disable-model-invocation:[[:space:]]*true' "${dir}SKILL.md" && continue
    printf -- '- %s:%s: %s\n' "$NAMESPACE" "$skill" "$(description_for "${dir}SKILL.md")" \
        >>"${WORK}/descriptions.txt"
    listed=$((listed + 1))
done

[[ -s "${WORK}/descriptions.txt" ]] || { echo "no skill descriptions found in ${SKILLS_DIR}" >&2; exit 1; }

# Tier 2. Run the hook and decode what it actually injects, rather than
# reassembling the wrapper text here and drifting from it.
"${PLUGIN_DIR}/hooks/session-start" \
    | jq -r '.hookSpecificOutput.additionalContext' >"${WORK}/hook.txt"

[[ -s "${WORK}/hook.txt" ]] || { echo "SessionStart hook injected nothing" >&2; exit 1; }

counts="$(jq -n \
    --rawfile descriptions "${WORK}/descriptions.txt" \
    --rawfile hook "${WORK}/hook.txt" \
    --rawfile bodies "${WORK}/bodies.txt" \
    '{descriptions: $descriptions, hook: $hook, bodies: $bodies}' \
    | "${SCRIPT_DIR}/count-tokens.py" "$MODEL")"

read -r descriptions hook bodies < <(jq -r '"\(.descriptions) \(.hook) \(.bodies)"' <<<"$counts")
always=$((descriptions + hook))

echo "Context budget for ${PLUGIN_DIR} (model=${MODEL})"
echo
printf '%-14s %-11s %8s  %s\n' "TIER" "WHEN" "TOKENS" "WHAT"
printf '%-14s %-11s %8s  %s\n' "descriptions" "per-session" "$descriptions" \
    "${listed} skill descriptions in the available-skills list"
printf '%-14s %-11s %8s  %s\n' "hook" "per-session" "$hook" \
    "SessionStart injection of ${NAMESPACE}:using-skills"
printf '%-14s %-11s %8s  %s\n' "bodies" "on-demand" "$bodies" \
    "all SKILL.md bodies (not gated)"
echo
printf 'always-loaded total: %s / %s budget\n' "$always" "$BUDGET"

if [[ "$always" -gt "$BUDGET" ]]; then
    echo
    echo "FAIL: always-loaded surface exceeds the budget by $((always - BUDGET)) token(s)."
    echo "Shrink a description or the using-skills injection, or raise BUDGET in $0 deliberately."
    exit 1
fi

printf 'PASS: %s token(s) of headroom.\n' "$((BUDGET - always))"
