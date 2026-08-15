#!/usr/bin/env python3
"""Count Claude tokens for labelled text blobs.

Reads a JSON object of {label: text} on stdin, writes {label: token_count} on
stdout. This is the shared counting core: check-context-budget.sh and
token-diff.sh both call it, and neither knows how tokens are counted.

Counting goes through the Anthropic count_tokens endpoint. Token counts are
model-specific, so the model id matters and is passed in. NEVER substitute
tiktoken or chars/4 — those are OpenAI heuristics that undercount Claude on
prose and undercount markdown, which is what skills are.

Every count includes the fixed ~7-token envelope the endpoint adds for the
message wrapper. It is constant per blob, so it neither grows with content nor
survives a HEAD-vs-worktree subtraction.

Credentials come from the `ant auth login` profile, which the SDK reads on its
own. A set ANTHROPIC_API_KEY — even an empty one — shadows that profile; check
with `ant auth status`.

Usage:
    echo '{"label": "text"}' | ./count-tokens.py [MODEL]
"""

import json
import sys

import anthropic

DEFAULT_MODEL = "claude-opus-5"


def count(client, model, text):
    """Token count for one blob; empty text costs nothing, envelope included."""
    if not text.strip():
        return 0
    counted = client.messages.count_tokens(
        model=model,
        messages=[{"role": "user", "content": text}],
    )
    return counted.input_tokens


def main():
    model = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_MODEL
    blobs = json.load(sys.stdin)
    client = anthropic.Anthropic()
    counts = {label: count(client, model, text) for label, text in blobs.items()}
    json.dump(counts, sys.stdout)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
