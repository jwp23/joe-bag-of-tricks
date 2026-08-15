#!/usr/bin/env bash
# Vendored-drift gate: proves every skill classified `vendored` in
# docs/customizations.md is still byte-identical to obra/superpowers at the
# recorded Last-synced tag.
#
# Why: a `vendored` file is taken to upstream head wholesale on the next sync.
# A file that quietly diverges while still marked vendored gets its fork content
# silently wiped. That already happened once (dispatching-parallel-agents/SKILL.md,
# caught by hand). The plugin is dogfooded from other repos where sessions never
# load the manifest, so manifest-less edits are the default outcome — only a
# mechanical check closes this.
#
# This does NOT judge whether a drift is intentional. It reports "marked vendored
# but differs from <ref>" and exits non-zero; a human decides reclassify-vs-revert.
#
# Scope: skill DIRECTORIES, derived from docs/customizations.md — the `skills/`
# table rows plus the catch-all ("skills not listed above are vendored"). Adding a
# vendored skill needs no edit here. Individually-vendored FILES inside an otherwise
# `patched`/`replaced` skill directory are covered too, via their own
# `| skills/<name>/<path> | vendored |` row in the manifest's "Individually-vendored
# files" table — give the file a row and it's checked, independent of the
# containing directory's own state.
#
# Cost: no model calls. One GitHub API call for the upstream tree, plus one per
# drifted file when a diff is shown. Requires an authenticated `gh`.
#
# Usage:
#   .claude/scripts/check-vendored-drift.sh                     # all vendored skills
#   .claude/scripts/check-vendored-drift.sh --only using-git-worktrees
#   .claude/scripts/check-vendored-drift.sh --ref v6.2.0        # override the anchor
#   .claude/scripts/check-vendored-drift.sh --diff              # full unified diff
#   .claude/scripts/check-vendored-drift.sh --list              # classification only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/plugins/joe-bag-of-tricks/skills"
MANIFEST="${REPO_ROOT}/docs/customizations.md"
UPSTREAM="obra/superpowers"

REF=""
SHOW_DIFF=0
LIST_ONLY=0
ONLY=()

# The whole leading comment block is the help text, found by scanning rather than
# by a hardcoded line range: a range silently truncates the last flags whenever
# the header grows (it already hid --diff and --list). Errors go to stderr.
usage() {
    local status="${1:-0}" out=1
    [[ "$status" -eq 0 ]] || out=2
    awk 'NR > 1 { if (!/^#/) exit; sub(/^# ?/, ""); print }' "$0" >&"$out"
    exit "$status"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ref)  REF="$2"; shift 2 ;;
        --diff) SHOW_DIFF=1; shift ;;
        --list) LIST_ONLY=1; shift ;;
        --only)
            shift
            while [[ $# -gt 0 && "$1" != --* ]]; do ONLY+=("$1"); shift; done
            ;;
        -h|--help) usage 0 ;;
        *) echo "unknown argument: $1" >&2; usage 1 ;;
    esac
done

for tool in gh jq git; do
    command -v "$tool" >/dev/null || { echo "required tool not found: $tool" >&2; exit 1; }
done

[[ -f "$MANIFEST" ]] || { echo "manifest not found: ${MANIFEST}" >&2; exit 1; }
[[ -d "$SKILLS_DIR" ]] || { echo "skills dir not found: ${SKILLS_DIR}" >&2; exit 1; }

# The anchor the manifest records as "already reconciled". Vendored means
# "identical to upstream AT THIS REF", so drift is measured against it, never
# against upstream's moving head.
if [[ -z "$REF" ]]; then
    REF="$(awk '/^\*\*Last synced:\*\*/ {
        if (match($0, /@ `[^`]+`/)) { print substr($0, RSTART + 3, RLENGTH - 4); exit }
    }' "$MANIFEST")"
    [[ -n "$REF" ]] || {
        echo "could not read the Last-synced ref from ${MANIFEST}; pass --ref" >&2
        exit 1
    }
fi

# Classification, derived from the manifest and never hardcoded:
#   1. an explicit `| skills/<name> | <state> |` table row wins
#   2. a skill named in the "Fork-original skills" section has no upstream file
#   3. everything else falls through the manifest's catch-all: vendored
declare -A STATE=()
while read -r name state; do
    [[ -n "$name" ]] && STATE["$name"]="$state"
done < <(awk -F'|' '
    /^\| skills\// {
        name = $2; state = $3
        gsub(/[[:space:]]/, "", name); gsub(/[[:space:]]/, "", state)
        sub(/^skills\//, "", name)
        print name, state
    }
' "$MANIFEST")

# Only a leading comma-separated backticked list of lowercase-hyphen tokens counts —
# checked on EVERY line of the section, not just the first, because the fork-original
# list wraps (e.g. "writing-agents" and "implementer-contract" sit on its second
# line). The narrative prose that follows backticks unrelated things too (`switch`,
# `merge`, `pull`, camelCase identifiers, slash-containing paths), but none of those
# match this pattern: it requires the backtick content to be lowercase/digits/hyphens
# only and to start at the line's first character, so "`git checkout`" (a space),
# "`assertPrimaryContentShare`" (uppercase), and "`docs/adr/...md`" (a slash) all
# fail to match. Verified empirically against the current manifest: this extracts
# exactly the 7 named fork-original skills and nothing else. A skill that ever
# shares a name with a stray matching token would be classified fork-original,
# dropped from the check, and wiped by the next sync — a green gate destroying
# content — so a false PASS is worse here than a false FAIL; re-verify against the
# manifest text whenever this section's prose changes.
declare -A FORK_ORIGINAL=()
while read -r name; do
    [[ -n "$name" && -d "${SKILLS_DIR}/${name}" ]] && FORK_ORIGINAL["$name"]=1
done < <(awk '
    /^## Fork-original skills/ { in_section = 1; next }
    /^## / { in_section = 0 }
    in_section && NF {
        line = $0
        while (match(line, /^`[a-z0-9][a-z0-9-]*`(,[[:space:]]*)?/)) {
            token = substr(line, 1, RLENGTH)
            gsub(/[`,[:space:]]/, "", token)
            print token
            line = substr(line, RLENGTH + 1)
        }
    }
' "$MANIFEST" | sort -u)

classify() {
    local skill="$1"
    if [[ -n "${STATE[$skill]:-}" ]]; then
        echo "${STATE[$skill]}"
    elif [[ -n "${FORK_ORIGINAL[$skill]:-}" ]]; then
        echo "fork-original"
    else
        echo "vendored"
    fi
}

ALL_SKILLS=()
VENDORED=()
for dir in "${SKILLS_DIR}"/*/; do
    skill="$(basename "$dir")"
    ALL_SKILLS+=("$skill")
    [[ "$(classify "$skill")" == "vendored" ]] && VENDORED+=("$skill")
done

# Individually-vendored files: `| skills/<name>/<path> | vendored |` rows inside an
# otherwise `patched`/`replaced` skill directory. These are a STATE-map key with a
# "/" in it (a skill dir basename never contains one), so they never collide with
# the directory-level classification above; they are checked in addition to it.
VENDORED_FILES=()
for key in "${!STATE[@]}"; do
    [[ "$key" == */* && "${STATE[$key]}" == "vendored" ]] && VENDORED_FILES+=("$key")
done
IFS=$'\n' VENDORED_FILES=($(sort <<<"${VENDORED_FILES[*]}")); unset IFS

if [[ $LIST_ONLY -eq 1 ]]; then
    printf '%-34s %s\n' "SKILL" "STATE (from ${MANIFEST#"${REPO_ROOT}/"})"
    for skill in "${ALL_SKILLS[@]}"; do
        printf '%-34s %s\n' "$skill" "$(classify "$skill")"
    done
    if [[ ${#VENDORED_FILES[@]} -gt 0 ]]; then
        echo
        printf '%-50s %s\n' "INDIVIDUALLY-VENDORED FILE" "STATE"
        for f in "${VENDORED_FILES[@]}"; do
            printf '%-50s %s\n' "$f" "vendored"
        done
    fi
    exit 0
fi

if [[ ${#ONLY[@]} -gt 0 ]]; then
    SELECTED=()
    for want in "${ONLY[@]}"; do
        [[ -d "${SKILLS_DIR}/${want}" ]] || { echo "no such skill: ${want}" >&2; exit 1; }
        state="$(classify "$want")"
        [[ "$state" == "vendored" ]] \
            || { echo "skill ${want} is ${state}, not vendored — nothing to check" >&2; exit 1; }
        SELECTED+=("$want")
    done
    VENDORED=("${SELECTED[@]}")
    # --only scopes to named skill directories; individually-vendored files have no
    # selector of their own yet, so they sit out of a scoped run rather than always
    # tagging along.
    VENDORED_FILES=()
fi

if [[ ${#VENDORED[@]} -eq 0 && ${#VENDORED_FILES[@]} -eq 0 ]]; then
    echo "no vendored skills or files in the manifest; nothing to check"
    exit 0
fi

echo "Checking ${#VENDORED[@]} vendored skill(s) and ${#VENDORED_FILES[@]} individually-vendored file(s) against ${UPSTREAM} @ ${REF}"
echo

# One tree call covers every vendored path. The tree's blob `sha` is a plain git
# blob hash, so `git hash-object` on the fork file is a byte-exact comparison
# with zero further network traffic (verified: the tree sha for
# skills/dispatching-parallel-agents/SKILL.md @ v6.3.0 equals `git hash-object`
# of the same file fetched raw from the contents endpoint).
TREE="$(mktemp)"
trap 'rm -f "$TREE"' EXIT

gh api "repos/${UPSTREAM}/git/trees/${REF}?recursive=1" >"$TREE" \
    || { echo "failed to read the ${UPSTREAM} tree at ${REF}" >&2; exit 1; }

if [[ "$(jq -r '.truncated' "$TREE")" == "true" ]]; then
    echo "upstream tree at ${REF} came back truncated; cannot compare reliably" >&2
    exit 1
fi

declare -A UPSTREAM_SHA=()
while read -r path sha; do
    UPSTREAM_SHA["$path"]="$sha"
done < <(jq -r '.tree[] | select(.type == "blob") | "\(.path) \(.sha)"' "$TREE")

report_diff() {
    local upstream_path="$1" local_file="$2"
    local remote
    remote="$(mktemp)"
    if gh api "repos/${UPSTREAM}/contents/${upstream_path}?ref=${REF}" \
        -H "Accept: application/vnd.github.raw" >"$remote" 2>/dev/null; then
        if [[ $SHOW_DIFF -eq 1 ]]; then
            diff -u --label "${upstream_path} @ ${REF}" --label "fork" \
                "$remote" "$local_file" || true
        else
            echo "      $(diff -u "$remote" "$local_file" \
                | grep -cE '^\+[^+]' || true) line(s) added, $(diff -u "$remote" "$local_file" \
                | grep -cE '^-[^-]' || true) removed vs ${REF} (--diff to see them)"
        fi
    fi
    rm -f "$remote"
}

drifted=0
for skill in "${VENDORED[@]}"; do
    findings=()

    mapfile -t upstream_files < <(
        printf '%s\n' "${!UPSTREAM_SHA[@]}" | grep -E "^skills/${skill}/" | sort
    )
    if [[ ${#upstream_files[@]} -eq 0 ]]; then
        findings+=("marked vendored but absent from ${UPSTREAM} @ ${REF} — reclassify it")
    fi

    while IFS= read -r local_file; do
        rel="${local_file#"${SKILLS_DIR}/"}"
        upstream_path="skills/${rel}"
        expected="${UPSTREAM_SHA[$upstream_path]:-}"
        actual="$(git hash-object "$local_file")"
        if [[ -z "$expected" ]]; then
            [[ ${#upstream_files[@]} -eq 0 ]] && continue
            findings+=("${rel}: exists in the fork, not upstream @ ${REF}")
        elif [[ "$expected" != "$actual" ]]; then
            findings+=("${rel}: differs from ${REF} (${expected:0:9} upstream, ${actual:0:9} here)")
        fi
    done < <(find "${SKILLS_DIR}/${skill}" -type f | sort)

    for upstream_path in "${upstream_files[@]}"; do
        [[ -f "${SKILLS_DIR}/${upstream_path#skills/}" ]] \
            || findings+=("${upstream_path#skills/}: present upstream @ ${REF}, missing from the fork")
    done

    if [[ ${#findings[@]} -eq 0 ]]; then
        printf '  ok    %s\n' "$skill"
    else
        drifted=$((drifted + 1))
        printf '  DRIFT %s\n' "$skill"
        for finding in "${findings[@]}"; do
            printf '      %s\n' "$finding"
            case "$finding" in
                *": differs from "*)
                    rel="${finding%%:*}"
                    report_diff "skills/${rel}" "${SKILLS_DIR}/${rel}"
                    ;;
            esac
        done
    fi
done

# Individually-vendored files (a single manifest row, not a whole skill dir): the
# same byte comparison, against the same upstream tree already fetched above.
files_drifted=0
for rel in "${VENDORED_FILES[@]}"; do
    local_file="${SKILLS_DIR}/${rel}"
    upstream_path="skills/${rel}"
    expected="${UPSTREAM_SHA[$upstream_path]:-}"
    if [[ ! -f "$local_file" ]]; then
        files_drifted=$((files_drifted + 1))
        printf '  DRIFT %s\n' "$rel"
        printf '      marked vendored but missing from the fork\n'
    elif [[ -z "$expected" ]]; then
        files_drifted=$((files_drifted + 1))
        printf '  DRIFT %s\n' "$rel"
        printf '      marked vendored but absent from %s @ %s — reclassify it\n' "$UPSTREAM" "$REF"
    else
        actual="$(git hash-object "$local_file")"
        if [[ "$expected" != "$actual" ]]; then
            files_drifted=$((files_drifted + 1))
            printf '  DRIFT %s\n' "$rel"
            printf '      differs from %s (%s upstream, %s here)\n' "$REF" "${expected:0:9}" "${actual:0:9}"
            report_diff "$upstream_path" "$local_file"
        else
            printf '  ok    %s\n' "$rel"
        fi
    fi
done

echo
if [[ $drifted -gt 0 || $files_drifted -gt 0 ]]; then
    cat >&2 <<EOF
${drifted} skill(s) and ${files_drifted} file(s) marked vendored have diverged from ${UPSTREAM} @ ${REF}.
The next sync takes vendored files to upstream head wholesale, so this content
would be silently wiped. Decide per file: reclassify the row to \`patched\` in
docs/customizations.md (fork delta is wanted) or revert to the upstream blob.
EOF
    exit 1
fi

echo "All ${#VENDORED[@]} vendored skill(s) and ${#VENDORED_FILES[@]} individually-vendored file(s) match ${UPSTREAM} @ ${REF}."
