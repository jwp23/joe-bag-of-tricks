#!/usr/bin/env bash
# Extracts the evidence slice for subagent runs from Claude Code session
# transcripts, so a failure that happened on another machine can be debugged
# here without shipping gigabytes of raw JSONL.
#
# Why: root-causing an agent stall needs the agent's own turns — what it
# launched, what came back, and the last thing it said before it stopped. That
# is a few hundred KB. The transcripts holding it run to megabytes each, and
# pasting a summary instead re-introduces the failure this exists to avoid:
# reasoning from someone's description rather than the record. So the output is
# the ORIGINAL JSON LINES, filtered — verbatim and quotable, just small.
#
# Transcript layout this reads (verified against Claude Code v2 transcripts):
#   <projects>/<slug>/<session>.jsonl              parent session
#   <projects>/<slug>/<session>/subagents/agent-<agentId>.jsonl
# A dispatch is an assistant `tool_use` named `Agent` carrying
# `input.subagent_type`; its result entry carries `.toolUseResult.agentId`,
# which names the subagent file. Async dispatches omit `agentType` in the
# result, so the subagent_type is always taken from the dispatch side.
#
# Output per run, under --out:
#   <slug>__<session>__<agentId>.jsonl   header record + the filtered slice
#   INDEX.md                             one row per run, plus what was dropped
#
# The slice keeps the whole conversation spine — every user, assistant, and
# system entry, with tool_use and tool_result blocks intact — and drops only
# host bookkeeping (attachments, file-history snapshots, queue/mode records).
# Size is bounded by truncating strings over --max-len rather than by guessing
# which entries matter: an earlier keep-list dropped the one foreground
# `gh pr checks --watch` call that proved an agent had complied, which is
# exactly the evidence the extract exists to carry. Dropped and kept counts are
# both recorded in the slice.
#
# SECRETS: transcripts contain command output, environment dumps, and file
# contents. Scan the output before it leaves the machine:
#   betterleaks dir <out> --redact
# This script does not redact for you; it says so again at the end.
#
# Usage:
#   .claude/scripts/extract-agent-transcripts.sh
#   .claude/scripts/extract-agent-transcripts.sh --agent branch-shepherd --agent pr-merger
#   .claude/scripts/extract-agent-transcripts.sh --agent '.'           # every subagent
#   .claude/scripts/extract-agent-transcripts.sh --project spe         # slug substring
#   .claude/scripts/extract-agent-transcripts.sh --out /tmp/evidence
#   .claude/scripts/extract-agent-transcripts.sh --full                # whole subagent transcripts
#   .claude/scripts/extract-agent-transcripts.sh --max-len 8000        # less truncation
#   .claude/scripts/extract-agent-transcripts.sh --list                # find runs, write nothing

set -euo pipefail

PROJECTS="${HOME}/.claude/projects"
OUT=""
FULL=0
LIST_ONLY=0
AGENTS=()
PROJECT_FILTER=""
MAXLEN=4000

usage() {
    local status="${1:-0}" out=1
    [[ "$status" -eq 0 ]] || out=2
    awk 'NR > 1 { if (!/^#/) exit; sub(/^# ?/, ""); print }' "$0" >&"$out"
    exit "$status"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --projects) PROJECTS="$2"; shift 2 ;;
        --out)      OUT="$2"; shift 2 ;;
        --project)  PROJECT_FILTER="$2"; shift 2 ;;
        --agent)    AGENTS+=("$2"); shift 2 ;;
        --max-len)  MAXLEN="$2"; shift 2 ;;
        --full)     FULL=1; shift ;;
        --list)     LIST_ONLY=1; shift ;;
        -h|--help)  usage 0 ;;
        *) echo "unknown argument: $1" >&2; usage 1 ;;
    esac
done

command -v jq >/dev/null || { echo "required tool not found: jq" >&2; exit 1; }
[[ -d "$PROJECTS" ]] || { echo "projects dir not found: ${PROJECTS}" >&2; exit 1; }

# Entry types that are host bookkeeping rather than the agent's own turns.
# Everything not listed here is kept, so a new entry type shows up by default
# instead of vanishing.
NOISE_TYPES='["attachment","file-history-snapshot","queue-operation","mode","ai-title","last-prompt","permission-mode","summary"]'

# Default to the two agents that own the delivery tail — the ones whose stalls
# are worth reconstructing. Override with --agent, which is an ERE matched
# against the full subagent_type.
[[ ${#AGENTS[@]} -gt 0 ]] || AGENTS=(branch-shepherd pr-merger)
AGENT_RE="$(IFS='|'; echo "${AGENTS[*]}")"

if [[ -z "$OUT" ]]; then
    OUT="${PWD}/agent-transcript-evidence"
fi

if [[ "$LIST_ONLY" -eq 0 ]]; then
    mkdir -p "$OUT"
fi

HOSTNAME_SAFE="$(hostname 2>/dev/null || echo unknown-host)"
RUNS_FOUND=0
INDEX_ROWS=()

# Walk parent transcripts. A dispatch and its result live in the same file, so
# the join is per-file; jq does it in one pass rather than re-reading.
while IFS= read -r transcript; do
    slug="$(basename "$(dirname "$transcript")")"
    session="$(basename "$transcript" .jsonl)"

    [[ -z "$PROJECT_FILTER" || "$slug" == *"$PROJECT_FILTER"* ]] || continue

    # Emit one line per matched run: agentId, subagent_type, timestamp, prompt.
    # `.message.content` is a string on some entries, so every access is guarded.
    # --slurpfile binds the whole file as an array to $e; $e[0] would be only
    # its first entry.
    runs="$(jq -rn --slurpfile e "$transcript" --arg re "$AGENT_RE" '
        ($e // []) as $all
        | ($all
           | map(select(.type=="assistant")
                 | . as $entry
                 | (($entry.message.content // []) | if type=="array" then .[] else empty end)
                 | select(.type=="tool_use" and .name=="Agent")
                 | select((.input.subagent_type // "") | test($re))
                 | {id: .id,
                    st: .input.subagent_type,
                    ts: ($entry.timestamp // ""),
                    prompt: (.input.prompt // "")})
          ) as $disp
        | ($all
           | map(select(.toolUseResult.agentId != null)
                 | . as $entry
                 | (($entry.message.content // []) | if type=="array" then .[] else empty end)
                 | select(.type=="tool_result")
                 | {tid: .tool_use_id,
                    aid: $entry.toolUseResult.agentId,
                    model: ($entry.toolUseResult.resolvedModel // ""),
                    status: ($entry.toolUseResult.status // "")})
          ) as $res
        | $disp[]
        | . as $d
        | (($res | map(select(.tid == $d.id)) | first) // {aid:"", model:"", status:""}) as $r
        | [$d.st, $r.aid, $r.model, $r.status, $d.ts, ($d.prompt | gsub("[\r\n\t]"; " ") | .[0:160])]
        | @tsv
    ' 2>/dev/null || true)"

    [[ -n "$runs" ]] || continue

    while IFS=$'\t' read -r st aid model status ts prompt_head; do
        [[ -n "$st" ]] || continue
        RUNS_FOUND=$((RUNS_FOUND + 1))

        sub="${PROJECTS}/${slug}/${session}/subagents/agent-${aid}.jsonl"
        have_sub="yes"
        [[ -n "$aid" && -f "$sub" ]] || have_sub="no"

        INDEX_ROWS+=("$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
            "$slug" "$session" "${aid:-unknown}" "$st" "${model:-?}" "${status:-?}" "$have_sub" "$prompt_head")")

        if [[ "$LIST_ONLY" -eq 1 ]]; then
            printf '%s  %s  %s  sub=%s\n' "$st" "${aid:-unknown}" "${model:-?}" "$have_sub"
            continue
        fi

        dest="${OUT}/${slug}__${session}__${aid:-unknown}.jsonl"

        # Provenance header. Written as a JSON line so the slice stays valid
        # JSONL and the reader can tell where it came from and what was cut.
        jq -cn \
            --arg host "$HOSTNAME_SAFE" --arg slug "$slug" --arg session "$session" \
            --arg aid "$aid" --arg st "$st" --arg model "$model" --arg status "$status" \
            --arg ts "$ts" --arg full "$FULL" --arg prompt "$prompt_head" \
            '{_extract:"agent-run-slice", host:$host, project:$slug, session:$session,
              agentId:$aid, subagentType:$st, resolvedModel:$model, dispatchStatus:$status,
              dispatchedAt:$ts, mode:(if $full=="1" then "full" else "filtered" end),
              promptHead:$prompt}' > "$dest"

        if [[ "$have_sub" == "no" ]]; then
            # No subagent file: keep the parent-side record so the run is still
            # visible, rather than dropping it and looking like it never happened.
            jq -c --arg id "$aid" 'select((tostring | contains($id)))' "$transcript" 2>/dev/null >> "$dest" || true
            continue
        fi

        if [[ "$FULL" -eq 1 ]]; then
            cat "$sub" >> "$dest"
            continue
        fi

        # The filtered slice. Keep the whole conversation spine — every user,
        # assistant, and system entry, with all tool_use and tool_result blocks
        # intact — and drop only the housekeeping types that carry no evidence.
        #
        # Deliberately NOT a keep-list of "interesting" entries. An earlier cut
        # kept only backgrounded tool_uses and text blocks, and silently dropped
        # the foreground `gh pr checks --watch` call that proved an agent had
        # complied — i.e. it discarded the very evidence being collected. Size is
        # controlled by truncating oversized strings instead, which bounds the
        # output without deciding in advance what will matter.
        jq -c --argjson max "$MAXLEN" '
            select(((.type // "") | IN($NOISE[])) | not)
            | walk(if type == "string" and (length > $max)
                   then .[0:$max] + "…[truncated by extract-agent-transcripts]"
                   else . end)
        ' --argjson NOISE "$NOISE_TYPES" "$sub" 2>/dev/null >> "$dest" || true

        kept=$(( $(wc -l < "$dest") - 1 ))
        total=$(wc -l < "$sub")
        jq -cn --argjson kept "$kept" --argjson total "$total" \
            '{_extract:"slice-stats", entriesKept:$kept, entriesInSource:$total,
              entriesDropped:($total - $kept)}' >> "$dest"
    done <<< "$runs"
done < <(find "$PROJECTS" -maxdepth 2 -name '*.jsonl' -type f 2>/dev/null)

if [[ "$RUNS_FOUND" -eq 0 ]]; then
    echo "no runs matched /${AGENT_RE}/ under ${PROJECTS}" >&2
    echo "note: absence here is not evidence of absence — transcripts are per-machine." >&2
    exit 1
fi

if [[ "$LIST_ONLY" -eq 1 ]]; then
    echo
    echo "${RUNS_FOUND} run(s) matched. Re-run without --list to write the slices."
    exit 0
fi

{
    echo "# Agent run evidence"
    echo
    echo "Host: \`${HOSTNAME_SAFE}\`  ·  Extracted from: \`${PROJECTS}\`  ·  Matched: \`/${AGENT_RE}/\`"
    echo
    echo "Each row is one subagent run. \`sub\` is whether the subagent's own transcript was"
    echo "found; \`no\` means only the parent-side record was available."
    echo
    echo "| project | session | agentId | agent | model | status | sub | prompt (head) |"
    echo "|---|---|---|---|---|---|---|---|"
    for row in "${INDEX_ROWS[@]}"; do
        IFS=$'\t' read -r slug session aid st model status have_sub prompt_head <<< "$row"
        printf '| %s | `%s` | `%s` | %s | %s | %s | %s | %s |\n' \
            "$slug" "${session:0:8}" "$aid" "$st" "$model" "$status" "$have_sub" \
            "$(printf '%s' "$prompt_head" | sed 's/|/\\|/g')"
    done
    echo
    echo "## Before transferring"
    echo
    echo 'Transcripts carry command output, environment dumps, and file contents.'
    echo 'Scan first: `betterleaks dir . --redact`'
} > "${OUT}/INDEX.md"

echo "${RUNS_FOUND} run(s) written to ${OUT}"
du -sh "$OUT" | awk '{print "total size: " $1}'
echo
echo "NOT REDACTED. Scan before this leaves the machine:"
echo "  betterleaks dir ${OUT} --redact"
