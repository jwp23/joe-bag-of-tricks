#!/usr/bin/env bash
# ADVISORY triggering probe. Sends a natural prompt that names no skill and
# reports which skill, if any, the agent reached for first.
#
# This ALWAYS exits 0. Triggering is model-dependent and will flip between runs;
# a flaky blocking gate is worse than none, and this project requires pristine
# output to pass. Read the report, don't gate on it.
#
# It is also not an eval — it is one turn, with no QA agent and no grading of
# what the agent did after loading. See docs/adr/006-defer-behavioral-evals.md.
#
# Run it after an upstream sync, where skill-description drift is the real risk.
# `.claude/scripts/verify-skills-load.sh` is the actual gate.
#
# Prompts live in triggering-prompts/<skill>.txt — the filename is the skill the
# prompt is expected to trigger. They are authored from this fork's own skill
# descriptions.
#
# Cost: one model call per prompt. Roughly $0.14-0.18 each, so a full sweep at
# --repeat 5 is real money. --changed-since is the cheap post-sync default:
# triggering depends on the `description:` frontmatter, and detecting a change
# there costs nothing, so only the drifted skills need probing.
#
# Usage:
#   .claude/scripts/probe-skill-triggering.sh                  # every prompt
#   .claude/scripts/probe-skill-triggering.sh --only brainstorming
#   .claude/scripts/probe-skill-triggering.sh --repeat 3       # check stability
#   .claude/scripts/probe-skill-triggering.sh --changed-since v1.2.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PLUGIN_DIR="${REPO_ROOT}/plugins/joe-bag-of-tricks"
PROMPTS_DIR="${SCRIPT_DIR}/triggering-prompts"
NAMESPACE="joe-bag-of-tricks"

MODEL="sonnet"
TIMEOUT=180
REPEAT=1
ONLY=()
CHANGED_SINCE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model)   MODEL="$2"; shift 2 ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        --repeat)  REPEAT="$2"; shift 2 ;;
        --changed-since) CHANGED_SINCE="$2"; shift 2 ;;
        --only)
            shift
            while [[ $# -gt 0 && "$1" != --* ]]; do ONLY+=("$1"); shift; done
            ;;
        -h|--help) sed -n '2,29p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *) echo "unknown argument: $1" >&2; exit 1 ;;
    esac
done

for tool in claude jq timeout; do
    command -v "$tool" >/dev/null || { echo "required tool not found: $tool" >&2; exit 1; }
done

# The `description:` value of a SKILL.md blob at a ref, empty when the path does
# not exist there. Reads the whole frontmatter entry, not just the first line, so
# an edit inside a `description: |` block scalar is not silently missed — and so
# a rename reads as a change, because the skill's name is triggering surface too.
description_at() {
    git -C "$REPO_ROOT" show "$1:$2" 2>/dev/null | awk '
        NR == 1 && $0 != "---" { exit }
        NR > 1 {
            if ($0 == "---") exit
            if (/^description:/) { grab = 1; print; next }
            if (grab && /^[A-Za-z_-]+:/) exit
            if (grab) print
        }'
}

# Skills whose triggering surface moved since a ref. Free to compute; it is what
# turns a full post-sync sweep into a handful of probes.
changed_skills() {
    git -C "$REPO_ROOT" diff --name-only -M "$1"..HEAD -- '*/SKILL.md' | while read -r path; do
        [[ -f "${REPO_ROOT}/${path}" ]] || continue   # deleted skills cannot be probed
        [[ "$(description_at "$1" "$path")" != "$(description_at HEAD "$path")" ]] || continue
        basename "$(dirname "$path")"
    done | sort -u
}

if [[ -n "$CHANGED_SINCE" ]]; then
    git -C "$REPO_ROOT" rev-parse --verify -q "${CHANGED_SINCE}^{commit}" >/dev/null \
        || { echo "not a commit: ${CHANGED_SINCE}" >&2; exit 1; }
    mapfile -t DRIFTED < <(changed_skills "$CHANGED_SINCE")
    if [[ ${#DRIFTED[@]} -eq 0 ]]; then
        echo "No skill description changed since ${CHANGED_SINCE} — nothing to probe."
        exit 0
    fi
    echo "Descriptions changed since ${CHANGED_SINCE}: ${DRIFTED[*]}"
    probeable=0
    for skill in "${DRIFTED[@]}"; do
        if [[ -f "${PROMPTS_DIR}/${skill}.txt" ]]; then
            probeable=$((probeable + 1))
        else
            echo "  no prompt for drifted skill: ${skill} (add ${skill}.txt to probe it)"
        fi
    done
    if [[ $probeable -eq 0 ]]; then
        echo "None of the drifted skills has a prompt — nothing to probe."
        exit 0
    fi
    ONLY+=("${DRIFTED[@]}")
fi

EXPECTED=()
for f in "${PROMPTS_DIR}"/*.txt; do
    [[ -f "$f" ]] || { echo "no prompts in ${PROMPTS_DIR}" >&2; exit 1; }
    skill="$(basename "$f" .txt)"
    if [[ ${#ONLY[@]} -gt 0 ]]; then
        for want in "${ONLY[@]}"; do
            [[ "$want" == "$skill" ]] && EXPECTED+=("$skill")
        done
    else
        EXPECTED+=("$skill")
    fi
done

[[ ${#EXPECTED[@]} -gt 0 ]] || { echo "no prompts selected" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The probe MUST run in a neutral repo, not this one. Run it here and the
# project's own CLAUDE.md makes a generic coding prompt incoherent — the agent
# correctly asks "where would this even live in a plugin repo?" and never needs
# a skill, which reads as a triggering miss that is really a fixture bug. This
# is a minimal stand-in for the fixture repos a real eval harness builds.
FIXTURE="${WORK}/fixture"
mkdir -p "${FIXTURE}/src"
cat >"${FIXTURE}/package.json" <<'JSON'
{ "name": "fixture", "version": "1.0.0", "scripts": { "test": "node --test" } }
JSON
cat >"${FIXTURE}/src/utils.js" <<'JS'
export function slugify(input) {
  return String(input).toLowerCase().trim().replace(/[^a-z0-9]+/g, '-');
}
JS
git -C "$FIXTURE" init -q
git -C "$FIXTURE" add -A
git -C "$FIXTURE" -c user.email=probe@local -c user.name=probe commit -qm "initial"

echo "Advisory triggering probe — ${#EXPECTED[@]} prompt(s) x ${REPEAT} run(s), model=${MODEL}"
echo "Not a gate: this always exits 0. See docs/adr/006-defer-behavioral-evals.md"
echo

printf '%-30s %-8s %s\n' "EXPECTED SKILL" "RUNS HIT" "SKILLS ACTUALLY LOADED"
for skill in "${EXPECTED[@]}"; do
    hits=0
    seen=""
    for ((i = 1; i <= REPEAT; i++)); do
        stream="${WORK}/${skill}.${i}.jsonl"
        timeout "$TIMEOUT" env -C "$FIXTURE" claude \
            --plugin-dir "$PLUGIN_DIR" \
            --model "$MODEL" \
            --allowedTools Skill \
            --output-format stream-json --verbose \
            -p "$(cat "${PROMPTS_DIR}/${skill}.txt")" \
            >"$stream" 2>/dev/null || true

        loaded="$(jq -rs '
            [ .[] | select(.type=="assistant") | .message.content[]?
              | select(.type=="tool_use" and .name=="Skill") | .input.skill ] | unique | join(",")
        ' "$stream" 2>/dev/null || echo "")"

        [[ "$loaded" == *"${NAMESPACE}:${skill}"* ]] && hits=$((hits + 1))
        seen="${seen}${loaded:-(none)} "
    done
    printf '%-30s %-8s %s\n' "$skill" "${hits}/${REPEAT}" "$(tr ' ' '\n' <<<"$seen" | sort -u | tr '\n' ' ')"
done

echo
echo "A miss is a signal to read the skill's description, not an automatic failure."
