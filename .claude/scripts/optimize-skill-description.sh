#!/usr/bin/env bash
# ON-DEMAND description-triggering optimizer. NOT a gate — nothing in this repo
# blocks on it. It drives Anthropic's `skill-creator` eval loop against one of
# this plugin's skills and reports whether a better-triggering description exists.
#
# skill-creator is installed tooling, not vendored: this script only points at it.
# See docs/skill-description-optimization.md for the full procedure, the cost
# model, and the rule about when a proposed description may be applied.
#
# What the loop does (all of it upstream's, none of it ours): splits the eval set
# 60/40 train/test, runs every query 3x for a trigger rate, rewrites the
# description from the TRAIN failures only, and picks the winner by HELD-OUT TEST
# score.
#
# Two things this script sets up that the loop needs and does not build itself:
#   1. A neutral fixture repo. Run in this repo, a generic prompt is incoherent
#      (a plugin repo has nowhere for a Postgres decision to land) — the same
#      fixture lesson as probe-skill-triggering.sh.
#   2. An isolated CLAUDE_CONFIG_DIR. joe-bag-of-tricks is installed globally, so
#      by default the REAL skill under test is loaded alongside the probe copy
#      with a byte-identical description, and the model picks one of the two —
#      which reads as a triggering miss that is really a fixture bug.
#
# Cost: queries x runs-per-query x iterations `claude -p` calls, ~$0.036 each on
# sonnet. The 18 x 3 x 3 proving run was ~$6 and under 3 minutes. Read
# docs/skill-description-optimization.md before raising any of the three.
#
# Usage:
#   .claude/scripts/optimize-skill-description.sh record-decision
#   .claude/scripts/optimize-skill-description.sh record-decision --max-iterations 1
#   .claude/scripts/optimize-skill-description.sh record-decision --model claude-haiku-4-5-20251001

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SHIM_DIR="${SCRIPT_DIR}/skill-eval-shim"
SKILLS_DIR="${REPO_ROOT}/plugins/joe-bag-of-tricks/skills"
EVAL_SETS_DIR="${REPO_ROOT}/.claude/eval-sets"
SKILL_CREATOR="${SKILL_CREATOR:-${HOME}/.claude/plugins/marketplaces/anthropic-agent-skills/skills/skill-creator}"

MODEL="claude-sonnet-5"
MAX_ITERATIONS=3
RUNS_PER_QUERY=3
NUM_WORKERS=10
RESULTS_DIR=""
SKILL=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model)           MODEL="$2"; shift 2 ;;
        --max-iterations)  MAX_ITERATIONS="$2"; shift 2 ;;
        --runs-per-query)  RUNS_PER_QUERY="$2"; shift 2 ;;
        --num-workers)     NUM_WORKERS="$2"; shift 2 ;;
        --results-dir)     RESULTS_DIR="$2"; shift 2 ;;
        -h|--help)         sed -n '2,34p' "$0" | sed 's/^# \?//'; exit 0 ;;
        --*)               echo "unknown argument: $1" >&2; exit 1 ;;
        *)                 SKILL="$1"; shift ;;
    esac
done

[[ -n "$SKILL" ]] || { echo "usage: $(basename "$0") <skill-name> [options]" >&2; exit 1; }

SKILL_PATH="${SKILLS_DIR}/${SKILL}"
EVAL_SET="${EVAL_SETS_DIR}/${SKILL}.json"
[[ -f "${SKILL_PATH}/SKILL.md" ]] || { echo "no such skill: ${SKILL_PATH}/SKILL.md" >&2; exit 1; }
[[ -f "$EVAL_SET" ]] || { echo "no eval set: ${EVAL_SET} — write one first (see docs/skill-description-optimization.md)" >&2; exit 1; }
[[ -d "$SKILL_CREATOR" ]] || { echo "skill-creator not installed at ${SKILL_CREATOR}; /plugin install example-skills@anthropic-agent-skills" >&2; exit 1; }
[[ -f "${HOME}/.claude/.credentials.json" ]] || { echo "no ~/.claude/.credentials.json to seed the isolated config dir with" >&2; exit 1; }

command -v python3 >/dev/null || { echo "required tool not found: python3" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
CONFIG_DIR="${WORK}/config"
FIXTURE="${WORK}/fixture"

mkdir -p "$CONFIG_DIR" "${FIXTURE}/src" "${FIXTURE}/.claude"
cp -f "${HOME}/.claude/.credentials.json" "${CONFIG_DIR}/"
cat >"${FIXTURE}/package.json" <<'JSON'
{ "name": "fixture", "version": "1.0.0", "scripts": { "test": "node --test" } }
JSON
cat >"${FIXTURE}/src/utils.js" <<'JS'
export function slugify(input) {
  return String(input).toLowerCase().trim().replace(/[^a-z0-9]+/g, '-');
}
JS

# Results outlive $WORK on purpose — results.json and report.html are the record
# of the run, and nothing about them belongs in the repo.
if [[ -z "$RESULTS_DIR" ]]; then
    RESULTS_DIR="${TMPDIR:-/tmp}/skill-description-eval/${SKILL}"
fi
mkdir -p "$RESULTS_DIR"

echo "Optimizing description for: ${SKILL}"
echo "  eval set:   ${EVAL_SET} ($(python3 -c "import json,sys; print(len(json.load(open(sys.argv[1]))))" "$EVAL_SET") queries)"
echo "  model:      ${MODEL}"
echo "  budget:     ${MAX_ITERATIONS} iterations x ${RUNS_PER_QUERY} runs/query"
echo "  results:    ${RESULTS_DIR}"
echo

cd "$FIXTURE"
PYTHONPATH="${SKILL_CREATOR}:${SHIM_DIR}" \
SKILL_EVAL_SHIM=1 \
SKILL_EVAL_WORKROOT="${WORK}/probes" \
CLAUDE_CONFIG_DIR="$CONFIG_DIR" \
BROWSER=/bin/true \
    python3 -m scripts.run_loop \
        --eval-set "$EVAL_SET" \
        --skill-path "$SKILL_PATH" \
        --model "$MODEL" \
        --max-iterations "$MAX_ITERATIONS" \
        --runs-per-query "$RUNS_PER_QUERY" \
        --num-workers "$NUM_WORKERS" \
        --results-dir "$RESULTS_DIR" \
        --verbose

echo
echo "Results (results.json, report.html, logs/): ${RESULTS_DIR}"
echo "Spend is NOT locally measurable: a probe session is killed the moment the"
echo "model reaches for a tool, so it never writes a transcript for ccusage to"
echo "read. See docs/skill-description-optimization.md for the per-call estimate."
echo "A winning description is applied ONLY if it beats the current one on the"
echo "HELD-OUT TEST score. Equal or worse means keep what you have."
