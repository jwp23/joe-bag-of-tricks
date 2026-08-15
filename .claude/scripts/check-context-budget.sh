#!/usr/bin/env bash
# Context-budget gate: measures the plugin surface that is loaded into EVERY
# session and fails when it exceeds the committed budget.
#
# Four tiers, measured separately because only the first three are the recurring
# per-session tax:
#   1. descriptions — the skill descriptions in the available-skills list
#   2. agents       — the plugin's lines in the Agent tool's roster
#   3. hook         — what the SessionStart hook injects (using-skills, verbatim)
#   4. bodies       — every SKILL.md body, loaded on demand only
#
# Tiers 1-3 are gated. Tier 4 is reported for information and never fails.
#
# Counting runs through count-tokens.py (the Anthropic count_tokens endpoint).
# Counts are model-specific; chars/4 and tiktoken are OpenAI heuristics and
# undercount Claude markdown, so they are never acceptable here.
#
# Cost: four count_tokens calls. The endpoint is not billed as inference.
#
# Usage:
#   .claude/scripts/check-context-budget.sh
#   .claude/scripts/check-context-budget.sh --budget 3000 --model claude-opus-5

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PLUGIN_DIR="${REPO_ROOT}/plugins/joe-bag-of-tricks"
SKILLS_DIR="${PLUGIN_DIR}/skills"
AGENTS_DIR="${PLUGIN_DIR}/agents"
NAMESPACE="joe-bag-of-tricks"

MODEL="claude-opus-5"

# Committed budget for tiers 1-3, in claude-opus-5 tokens. First set at 3,900
# from the measured surface at the time — 1,284 descriptions + 1,939 hook = 3,223
# — plus ~20% headroom, which is room for two or three more skills before anyone
# has to think about it. Raising this is a decision, not a formality: every token
# here is paid on every session, before the user has said anything.
#
# Raised to 4,771 when the agents tier was added: 3,900 + the 871 tokens the
# seven agent roster lines were already costing every session unmeasured. That
# recognises surface that existed before the tier did, so headroom is unchanged
# at 423 — it does not buy room for anything new.
BUDGET=4771

usage() {
    sed -n '2,22p' "$0" | sed 's/^# \?//'
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

python3 -c 'import anthropic' 2>/dev/null \
    || { echo "the anthropic Python SDK is not importable: pip install anthropic" >&2; exit 1; }

# A set-but-empty ANTHROPIC_API_KEY shadows the `ant auth login` profile and the
# SDK then fails deep in a request with an opaque TypeError.
if [[ -n "${ANTHROPIC_API_KEY+set}" && -z "${ANTHROPIC_API_KEY}" ]]; then
    echo "ANTHROPIC_API_KEY is set but empty; it shadows the ant auth profile — unset it or give it a value" >&2
    exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# One frontmatter scalar as the injected listings render it: single-line YAML,
# optionally double-quoted, read from the frontmatter block only.
#
# Returns 2 when the key is absent — the caller decides whether that is an error
# — and 1 when the key is there but its value is not a single-line scalar. A
# folded or block scalar (`description: >-`), or a nested list, leaves nothing
# usable on the key's line; measuring that as empty would silently under-report
# the entry's entire per-session cost, so refuse to measure it at all.
frontmatter_scalar() {
    local file="$1" key="$2" line status
    line="$(awk -v key="$key" '
        NR == 1 && $0 !~ /^---/ { exit }
        NR == 1 { next }
        /^---/ { exit }
        $0 ~ "^" key ":([[:space:]]|$)" { found = 1; sub(/^[^:]*:[[:space:]]*/, ""); print; exit }
        END { if (!found) exit 2 }
    ' "$file")" && status=0 || status=$?
    [[ "$status" -eq 0 ]] || return "$status"
    if [[ -z "$line" || "$line" =~ ^[\>\|][0-9]*[-+]?$ ]]; then
        return 1
    fi
    if [[ "$line" == \"*\" ]]; then
        line="${line#\"}"
        line="${line%\"}"
        line="${line//\\\"/\"}"
        line="${line//\\\\/\\}"
    fi
    printf '%s' "$line"
}

# The roster's parenthesised tool phrase. An agent with no `tools:` key inherits
# every tool and the roster says so. `disallowedTools` renders differently again
# ("All tools except …", and a set difference when combined with `tools:`); no
# agent here uses it, so it is refused rather than modelled wrong.
tools_for() {
    local file="$1" tools status
    frontmatter_scalar "$file" disallowedTools >/dev/null 2>&1 && status=0 || status=$?
    if [[ "$status" -ne 2 ]]; then
        echo "disallowedTools in ${file} is not modelled by this gate; extend tools_for" >&2
        return 1
    fi
    tools="$(frontmatter_scalar "$file" tools)" && status=0 || status=$?
    case "$status" in
        0) printf '%s' "$tools" ;;
        2) printf 'All tools' ;;
        *) echo "no single-line tools scalar in ${file}" >&2; return 1 ;;
    esac
}

# Tier 1. A skill with `disable-model-invocation: true` is kept out of the
# available-skills list on purpose, so its description costs nothing per session.
listed=0
for dir in "${SKILLS_DIR}"/*/; do
    skill="$(basename "$dir")"
    [[ -f "${dir}SKILL.md" ]] || continue
    cat "${dir}SKILL.md" >>"${WORK}/bodies.txt"
    grep -qE '^disable-model-invocation:[[:space:]]*true' "${dir}SKILL.md" && continue
    description="$(frontmatter_scalar "${dir}SKILL.md" description)" \
        || { echo "no single-line description scalar in ${dir}SKILL.md" >&2; exit 1; }
    printf -- '- %s:%s: %s\n' "$NAMESPACE" "$skill" "$description" \
        >>"${WORK}/descriptions.txt"
    listed=$((listed + 1))
done

[[ -s "${WORK}/descriptions.txt" ]] || { echo "no skill descriptions found in ${SKILLS_DIR}" >&2; exit 1; }

# Tier 2. The Agent tool's roster, one line per agent, injected as a
# <system-reminder> at the top of every session. The line format is the harness's
# — `- <type>: <description> (Tools: <list>)`, namespaced for a plugin agent —
# and only the plugin's own lines are counted: the header, the built-in agents,
# and the concurrency note are there whether this plugin is installed or not.
agent_count=0
for file in "${AGENTS_DIR}"/*.md; do
    [[ -f "$file" ]] || continue
    name="$(frontmatter_scalar "$file" name)" \
        || { echo "no single-line name scalar in ${file}" >&2; exit 1; }
    description="$(frontmatter_scalar "$file" description)" \
        || { echo "no single-line description scalar in ${file}" >&2; exit 1; }
    tools="$(tools_for "$file")" || exit 1
    printf -- '- %s:%s: %s (Tools: %s)\n' "$NAMESPACE" "$name" "$description" "$tools" \
        >>"${WORK}/agents.txt"
    agent_count=$((agent_count + 1))
done

[[ -s "${WORK}/agents.txt" ]] || { echo "no agent definitions found in ${AGENTS_DIR}" >&2; exit 1; }

# Tier 3. Run the hook and decode what it actually injects, rather than
# reassembling the wrapper text here and drifting from it.
"${PLUGIN_DIR}/hooks/session-start" \
    | jq -r '.hookSpecificOutput.additionalContext' >"${WORK}/hook.txt"

[[ -s "${WORK}/hook.txt" ]] || { echo "SessionStart hook injected nothing" >&2; exit 1; }

counts="$(jq -n \
    --rawfile descriptions "${WORK}/descriptions.txt" \
    --rawfile agents "${WORK}/agents.txt" \
    --rawfile hook "${WORK}/hook.txt" \
    --rawfile bodies "${WORK}/bodies.txt" \
    '{descriptions: $descriptions, agents: $agents, hook: $hook, bodies: $bodies}' \
    | "${SCRIPT_DIR}/count-tokens.py" "$MODEL")"

read -r descriptions agents hook bodies \
    < <(jq -r '"\(.descriptions) \(.agents) \(.hook) \(.bodies)"' <<<"$counts")
always=$((descriptions + agents + hook))

echo "Context budget for ${PLUGIN_DIR} (model=${MODEL})"
echo
printf '%-14s %-11s %8s  %s\n' "TIER" "WHEN" "TOKENS" "WHAT"
printf '%-14s %-11s %8s  %s\n' "descriptions" "per-session" "$descriptions" \
    "${listed} skill descriptions in the available-skills list"
printf '%-14s %-11s %8s  %s\n' "agents" "per-session" "$agents" \
    "${agent_count} agent lines in the Agent tool's roster"
printf '%-14s %-11s %8s  %s\n' "hook" "per-session" "$hook" \
    "SessionStart injection of ${NAMESPACE}:using-skills"
printf '%-14s %-11s %8s  %s\n' "bodies" "on-demand" "$bodies" \
    "all SKILL.md bodies (not gated)"
echo
printf 'always-loaded total: %s / %s budget\n' "$always" "$BUDGET"

if [[ "$always" -gt "$BUDGET" ]]; then
    echo
    echo "FAIL: always-loaded surface exceeds the budget by $((always - BUDGET)) token(s)."
    echo "Shrink a skill or agent description or the using-skills injection, or raise BUDGET in $0 deliberately."
    exit 1
fi

printf 'PASS: %s token(s) of headroom.\n' "$((BUDGET - always))"
