#!/usr/bin/env bash
# Load-and-observe gate: proves every skill in the plugin actually resolves and
# loads, and that the SessionStart hook injects using-skills.
#
# This is NOT an eval. It proves a skill loads when explicitly named; it says
# nothing about whether the skill TRIGGERS from a natural prompt. Behavioral
# evals are deferred — see docs/adr/006-defer-behavioral-evals.md.
#
# A skill with `disable-model-invocation: true` is deliberately hidden from the
# model and can only be reached as /namespace:name, so it is probed that way and
# reported in the VIA column as "slash" rather than "skill".
#
# --plugin-dir targets any plugin root — the dir holding .claude-plugin/plugin.json
# — and the namespace is read from that manifest's `name`. docs/customizations.md
# describes plugins/joe-bag-of-tricks and no other plugin, so for any other plugin
# the divergence ordering does not exist: skills run alphabetically and
# --tier diverged is rejected rather than silently mis-ordered. The using-skills
# hook assertion likewise applies only to a plugin that ships that skill.
#
# Cost: one model call per skill. Runs are billed; the summary prints the total.
#
# Usage:
#   .claude/scripts/verify-skills-load.sh                 # every skill
#   .claude/scripts/verify-skills-load.sh --tier diverged # replaced + patched only
#   .claude/scripts/verify-skills-load.sh --only brainstorming writing-plans
#   .claude/scripts/verify-skills-load.sh --plugin-dir plugins/joe-magic-bootstrap
#   .claude/scripts/verify-skills-load.sh --jobs 1 --model opus --timeout 300

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
MANIFEST="${REPO_ROOT}/docs/customizations.md"
# The manifest's skills/ rows classify this plugin's skills and no other's.
MANIFEST_PLUGIN="${REPO_ROOT}/plugins/joe-bag-of-tricks"

PLUGIN_DIR="$MANIFEST_PLUGIN"
MODEL="sonnet"
TIMEOUT=180
JOBS=3
TIER="all"
ONLY=()

usage() {
    sed -n '2,26p' "$0" | sed 's/^# \?//'
    exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model)   MODEL="$2"; shift 2 ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        --jobs)    JOBS="$2"; shift 2 ;;
        --tier)    TIER="$2"; shift 2 ;;
        --plugin-dir) PLUGIN_DIR="$2"; shift 2 ;;
        --only)
            shift
            while [[ $# -gt 0 && "$1" != --* ]]; do ONLY+=("$1"); shift; done
            ;;
        -h|--help) usage 0 ;;
        *) echo "unknown argument: $1" >&2; usage 1 ;;
    esac
done

case "$TIER" in
    all|diverged) ;;
    *) echo "--tier must be 'all' or 'diverged', got: $TIER" >&2; exit 1 ;;
esac

for tool in claude jq timeout; do
    command -v "$tool" >/dev/null || { echo "required tool not found: $tool" >&2; exit 1; }
done

# The plugin root is the dir holding .claude-plugin/plugin.json. A marketplace
# root (the repo root) silently loads no skills, so reject anything else here
# rather than reporting an empty, passing run.
PLUGIN_ARG="$PLUGIN_DIR"
PLUGIN_DIR="$(cd "$PLUGIN_ARG" 2>/dev/null && pwd)" || true
if [[ -z "$PLUGIN_DIR" || ! -f "${PLUGIN_DIR}/.claude-plugin/plugin.json" ]]; then
    echo "--plugin-dir must be a plugin root holding .claude-plugin/plugin.json, got: ${PLUGIN_ARG}" >&2
    exit 1
fi

SKILLS_DIR="${PLUGIN_DIR}/skills"
[[ -d "$SKILLS_DIR" ]] || { echo "no skills/ directory in ${PLUGIN_DIR}" >&2; exit 1; }

# The namespace skills resolve under is the plugin's own manifest name.
NAMESPACE="$(jq -r '.name // empty' "${PLUGIN_DIR}/.claude-plugin/plugin.json")"
[[ -n "$NAMESPACE" ]] ||
    { echo "no \"name\" in ${PLUGIN_DIR}/.claude-plugin/plugin.json" >&2; exit 1; }

# docs/customizations.md classifies one plugin's skills. Against any other plugin
# there is no divergence data, so ordering degrades to alphabetical and the
# diverged tier — which would otherwise select nothing — is refused.
MANIFEST_COVERED=0
[[ "$PLUGIN_DIR" == "$MANIFEST_PLUGIN" ]] && MANIFEST_COVERED=1
if [[ "$TIER" == "diverged" && "$MANIFEST_COVERED" -eq 0 ]]; then
    echo "--tier diverged needs docs/customizations.md coverage, which exists only for ${MANIFEST_PLUGIN}" >&2
    exit 1
fi

# Only the plugin that ships using-skills can have injected it at SessionStart.
EXPECT_HOOK=0
[[ -d "${SKILLS_DIR}/using-skills" ]] && EXPECT_HOOK=1

# Divergence rank from the State column of docs/customizations.md, so the skills
# this fork owns fail first. The manifest is the source of truth; a skill with no
# row there (vendored or fork-original) sorts last, as does every skill of a
# plugin the manifest does not cover.
rank_for() {
    local skill="$1" state
    [[ "$MANIFEST_COVERED" -eq 1 ]] || { echo 3; return; }
    state="$(awk -F'|' -v s=" skills/${skill} " '
        $0 ~ /^\| skills\// && $2 == s { gsub(/ /, "", $3); print $3; exit }
    ' "$MANIFEST")"
    case "$state" in
        replaced) echo 1 ;;
        patched)  echo 2 ;;
        *)        echo 3 ;;
    esac
}

# Discover skills, asserting the frontmatter name matches the directory name —
# a mismatch means `Skill` cannot resolve the name the docs advertise.
#
# Problems go to $DISCOVERY_ERRORS rather than exiting: this runs in a subshell
# under mapfile, so an exit here would only kill the subshell and silently
# truncate the skill list, turning a broken skill into a smaller passing run.
DISCOVERY_ERRORS="$(mktemp)"
trap 'rm -f "$DISCOVERY_ERRORS"' EXIT

discover() {
    local dir skill fm_name
    for dir in "${SKILLS_DIR}"/*/; do
        skill="$(basename "$dir")"
        if [[ ! -f "${dir}SKILL.md" ]]; then
            echo "no SKILL.md in ${dir}" >>"$DISCOVERY_ERRORS"
            continue
        fi
        fm_name="$(awk '/^name:[[:space:]]/ { print $2; exit }' "${dir}SKILL.md")"
        if [[ "$fm_name" != "$skill" ]]; then
            echo "frontmatter name '${fm_name}' != directory '${skill}' in ${dir}SKILL.md" \
                >>"$DISCOVERY_ERRORS"
            continue
        fi
        # `disable-model-invocation: true` keeps a skill out of the model's skill
        # list on purpose — the Skill tool CANNOT load it, and the user must type
        # /name. Probing it the normal way reports a false failure, so record the
        # invocation mechanism and assert against the one that actually applies.
        if grep -qE '^disable-model-invocation:[[:space:]]*true' "${dir}SKILL.md"; then
            echo "$(rank_for "$skill") ${skill} slash"
        else
            echo "$(rank_for "$skill") ${skill} skill"
        fi
    done
}

mapfile -t RANKED < <(discover | sort -k1,1n -k2,2)

if [[ -s "$DISCOVERY_ERRORS" ]]; then
    echo "skill discovery failed:" >&2
    cat "$DISCOVERY_ERRORS" >&2
    exit 1
fi

SKILLS=()
declare -A MODE=()
for entry in "${RANKED[@]}"; do
    read -r rank skill mode <<<"$entry"
    MODE["$skill"]="$mode"
    if [[ ${#ONLY[@]} -gt 0 ]]; then
        for want in "${ONLY[@]}"; do
            [[ "$want" == "$skill" ]] && SKILLS+=("$skill")
        done
    elif [[ "$TIER" == "diverged" && "$rank" == 3 ]]; then
        continue
    else
        SKILLS+=("$skill")
    fi
done

if [[ ${#ONLY[@]} -gt 0 ]]; then
    for want in "${ONLY[@]}"; do
        printf '%s\n' "${SKILLS[@]:-}" | grep -qx "$want" \
            || { echo "no such skill: ${want}" >&2; exit 1; }
    done
fi

[[ ${#SKILLS[@]} -gt 0 ]] || { echo "no skills selected" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK" "$DISCOVERY_ERRORS"' EXIT

# One session per skill. Asserts, from the structured stream:
#   1. the skill loaded, by whichever mechanism applies to it:
#      - "skill" mode: a Skill tool_use carrying the fully namespaced name
#      - "slash"  mode: a /namespace:name command that resolved (an unresolvable
#        one returns the literal "Unknown command: /..." without a model turn)
#   2. a terminal result with subtype=success and is_error=false
#   3. a SessionStart hook_response carrying the using-skills injection
probe() {
    local skill="$1"
    local stream="${WORK}/${skill}.jsonl"
    local status_file="${WORK}/${skill}.status"
    local rc=0 prompt

    # "Do not follow it" is load-bearing, not politeness. A skill like
    # requesting-code-review acts the moment it loads — it dispatched a reviewer
    # subagent and ran the session into the timeout at $0.86 a probe. The gate
    # only needs the skill to LOAD; everything after is cost and false failures.
    if [[ "${MODE[$skill]}" == "slash" ]]; then
        prompt="/${NAMESPACE}:${skill}"
    else
        prompt="Load the ${NAMESPACE}:${skill} skill with the Skill tool. If this skill's content already appears in your context (e.g. injected by a SessionStart hook), that does NOT count — the Skill tool call itself is what is being verified, so make it anyway. Do NOT follow the skill's instructions, do NOT dispatch a subagent, and do NOT take any other action. Once it has loaded, reply with exactly: DONE"
    fi

    timeout "$TIMEOUT" claude \
        --plugin-dir "$PLUGIN_DIR" \
        --model "$MODEL" \
        --allowedTools Skill \
        --output-format stream-json --verbose \
        -p "$prompt" \
        >"$stream" 2>"${WORK}/${skill}.err" || rc=$?

    # A timeout or non-zero exit is NOT decided here: the stream captured so far
    # may already show the skill loading, and "did it load" is the only thing
    # this gate claims to answer. Record how the session ended and let the
    # assertions below rule.
    local ending=""
    if [[ $rc -eq 124 ]]; then
        ending="session hit the ${TIMEOUT}s timeout"
    elif [[ $rc -ne 0 ]]; then
        ending="claude exited ${rc}"
    fi

    if [[ ! -s "$stream" ]]; then
        echo "${ending:-no output}; empty stream" >"$status_file"
        return
    fi

    local loaded result hook
    if [[ "${MODE[$skill]}" == "slash" ]]; then
        # An unknown command short-circuits to a literal result and never reaches
        # the model, so "no Unknown command" IS the resolution signal.
        loaded="$(jq -s --arg cmd "/${NAMESPACE}:${skill}" '
            if [ .[] | select(.type=="result")
                 | select((.result // "") | startswith("Unknown command: " + $cmd)) ] | length > 0
            then 0 else 1 end
        ' "$stream")"
    else
        loaded="$(jq -s --arg s "${NAMESPACE}:${skill}" '
            [ .[] | select(.type=="assistant") | .message.content[]?
              | select(.type=="tool_use" and .name=="Skill" and .input.skill==$s) ] | length
        ' "$stream")"
    fi
    result="$(jq -rs '
        [ .[] | select(.type=="result") ] | last
        | if . == null then "no result event"
          elif .subtype=="success" and .is_error==false then "ok"
          else "result \(.subtype) is_error=\(.is_error)" end
    ' "$stream")"
    hook=1
    if [[ "$EXPECT_HOOK" -eq 1 ]]; then
        hook="$(jq -s --arg ns "$NAMESPACE" '
            [ .[] | select(.subtype=="hook_response" and .hook_event=="SessionStart")
              | select(.output | contains("\($ns):using-skills")) ] | length
        ' "$stream")"
    fi

    jq -rs '[ .[] | select(.type=="result") ] | last | .total_cost_usd // 0' \
        "$stream" >"${WORK}/${skill}.cost"

    if [[ "$loaded" -eq 0 ]]; then
        if [[ "${MODE[$skill]}" == "slash" ]]; then
            echo "/${NAMESPACE}:${skill} did not resolve${ending:+ (${ending})}" >"$status_file"
        else
            echo "never loaded (no Skill tool_use)${ending:+; ${ending}}" >"$status_file"
        fi
    elif [[ "$hook" -eq 0 ]]; then
        echo "SessionStart hook did not inject ${NAMESPACE}:using-skills" >"$status_file"
    elif [[ -n "$ending" ]]; then
        # Loaded, then the session ran on and was cut off. The gate's claim is
        # satisfied; note it so a chronically slow skill is still visible.
        echo "PASS (loaded, but ${ending})" >"$status_file"
    elif [[ "$result" != "ok" ]]; then
        echo "loaded, but ${result}" >"$status_file"
    else
        echo "PASS" >"$status_file"
    fi
}

echo "Loading ${#SKILLS[@]} skill(s) from ${PLUGIN_DIR} as ${NAMESPACE}: (model=${MODEL}, jobs=${JOBS})"
[[ "$MANIFEST_COVERED" -eq 1 ]] ||
    echo "no docs/customizations.md coverage for this plugin: order is alphabetical, not divergence-first"
[[ "$EXPECT_HOOK" -eq 1 ]] ||
    echo "this plugin does not ship using-skills: the SessionStart injection is not asserted"
echo

for skill in "${SKILLS[@]}"; do
    while [[ "$(jobs -rp | wc -l)" -ge "$JOBS" ]]; do wait -n; done
    probe "$skill" &
done
wait

failed=0
total_cost=0
printf '%-34s %-7s %s\n' "SKILL" "VIA" "RESULT"
for skill in "${SKILLS[@]}"; do
    status="$(cat "${WORK}/${skill}.status" 2>/dev/null || echo "no status recorded")"
    printf '%-34s %-7s %s\n' "$skill" "${MODE[$skill]}" "$status"
    [[ -f "${WORK}/${skill}.cost" ]] &&
        total_cost="$(jq -n --argjson a "$total_cost" \
            --argjson b "$(cat "${WORK}/${skill}.cost")" '$a + $b')"
    [[ "$status" == PASS* ]] || failed=$((failed + 1))
done

echo
printf 'total cost: $%s\n' "$(jq -n --argjson c "$total_cost" '$c | .*10000 | round / 10000')"

if [[ $failed -gt 0 ]]; then
    echo
    echo "=== ${failed} failure(s); stream tail for each ==="
    for skill in "${SKILLS[@]}"; do
        status="$(cat "${WORK}/${skill}.status" 2>/dev/null || echo "no status recorded")"
        [[ "$status" == PASS* ]] && continue
        echo
        echo "--- ${skill}: ${status}"
        [[ -s "${WORK}/${skill}.err" ]] && { echo "stderr:"; tail -n 20 "${WORK}/${skill}.err"; }
        [[ -s "${WORK}/${skill}.jsonl" ]] && { echo "stream tail:"; tail -n 5 "${WORK}/${skill}.jsonl" | cut -c1-800; }
    done
    exit 1
fi

echo "All ${#SKILLS[@]} skill(s) loaded."
