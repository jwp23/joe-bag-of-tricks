# Building joe-bag-of-tricks — The Steps We Took

A first-person account of how this repo came to be: the actual sequence, the
decisions, and — just as useful — the options considered and rejected. The
generalized, reusable version lives in
[converting-your-workflow-to-a-plugin.md](converting-your-workflow-to-a-plugin.md).
This document is the case study behind that guide.

Session model: Opus at `xhigh` effort for the main thread; research delegated to
`claude-code-guide` subagents.

---

## The goal

Pull the skills and agents out of a single project's `.claude/` directory and
into a standalone repo I could install on any machine — and, when I push an
update from one machine, have it propagate to the others. Possibly share it with
others down the line.

Starting material, from the `.claude/` directory of
[`spe`](https://github.com/jwp23/spe) (a simple PDF editor): **18 skills, 4 agents, 1 command**
(`bootstrap`), plus project `rules/`, a `brainstorm/` scratch dir, and a small
`docs/adr/`.

---

## Step 1 — Look before designing

First move was to actually read what was there, not assume. Listing the skills,
the agent frontmatter, and the settings showed the real shape: a set of mostly
general-purpose engineering skills (TDD, debugging, planning, review) and four
clean agents (`code-reviewer`, `coderabbit-reviewer`, `pr-creator`,
`pr-merger`). A grep for project-specific strings (`cargo`, `bd`, `docs/adr`,
`pdftoppm`, `iced`, …) mapped exactly which files carried assumptions.

The finding that shaped everything: the "project-specific" references were almost
all *cross-project conventions* (beads for issues, ADRs for decisions, Rust/cargo
as the example stack) rather than anything truly tied to the origin project. Only
a couple of references were genuinely broken once extracted.

## Step 2 — Research the format instead of recalling it

Rather than write `plugin.json` and `marketplace.json` from memory, I dispatched
a `claude-code-guide` subagent to verify the current spec against the docs:
manifest fields, component discovery, the monorepo-marketplace layout, the CLI
for add/install/update, version resolution, and private-repo auth. This is the
rule that kept the build honest — **the spec changes; verify it.**

## Step 3 — The decisions

Four decisions, made explicitly before any files moved:

- **Granularity → one plugin.** I initially wanted mix-and-match plugins so
  people could compose their own workflow. Research killed that cleanly: there is
  **no per-component enable/disable** inside a plugin, and plugin components are
  **always namespaced**. My skills are a coupled chain (brainstorming → writing-
  plans → executing-plans, agents dispatched by skills, foundations referenced
  everywhere). Splitting them wouldn't deliver composability — it would break
  cross-references. The real composability is use-time: skills auto-fire only
  when relevant.
- **Versioning → explicit semver.** Bump `version` in `plugin.json` to
  propagate. More discipline than the git-SHA scheme, but predictable and
  pinnable if others use it.
- **Genericize → minimal, personal.** Keep the `bd` commands and `docs/adr`
  conventions (I want them in every project). Genericize `cargo`, since I'll use
  this on non-Rust projects.
- **Naming → all three the same.** See below.

## Step 4 — The naming detour

More time went here than anywhere else, and it's worth recording why. There are
three names — repo, marketplace, and plugin — and the plugin name becomes the
slash prefix on every skill (`/name:skill`).

Candidates and why they lost:

- **`joebot` / `jbot`** — "bot" frames it as a chatbot, which fights the
  magician's-**bag-of-tricks** image I was after. Rejected.
- **`tricks` / `presto` / `conjure`** — short and on-theme, but drop the personal
  "Joe" identity and don't echo the marketplace.
- **`joe-bag-tricks`** — a *near-miss* of `joe-bag-of-tricks` (of/no-of). Not
  short enough to win on brevity, not distinct enough to avoid "which one had the
  *of*?" typos. This is the trap to avoid: either match exactly or be clearly
  distinct.

Decision: **match all three to `joe-bag-of-tricks`.** Since skills mostly
auto-fire (and Claude fuzzy-matches the skill word when you type `/`), the long
prefix is rarely typed, so its one cost barely applies — and consistency wins.
The redundant-looking `install joe-bag-of-tricks@joe-bag-of-tricks` is typed once
per machine.

## Step 5 — Scaffold and copy

Built the monorepo-marketplace layout — `.claude-plugin/marketplace.json` at the
root, the plugin under `plugins/joe-bag-of-tricks/` with its own
`.claude-plugin/plugin.json`, `skills/`, `agents/`, `docs/adr/`. Copied (not
moved) the 18 skills and 4 agents with every supporting file intact, plus the one
ADR that a skill's design rationale pointed at. Wrote both manifests from the
researched schema, plus a README and `.gitignore`.

## Step 6 — Fix what extraction broke

Reference fixes were narrower than feared — concentrated almost entirely in
`finishing-a-development-branch`:

- Agent dispatches by file path (`.claude/agents/pr-creator.md`) → namespaced
  agent names (`joe-bag-of-tricks:pr-creator`).
- A broken pointer to `.claude/docs/adr/001-…` → the copy carried into the
  plugin's own `docs/adr/`.
- The `cargo test` default → language-neutral phrasing with cargo as an example.

The worktree and security-review skills already spoke in multi-language terms, so
they needed nothing.

## Step 7 — Drop what didn't belong

The `bootstrap` command was genuinely project-specific — its suggested ADR
sequence was literally "GUI framework / PDF rendering libraries / Linux system
utility strategy." Wrong for a general toolkit, and I'd only asked for skills +
agents. I removed it rather than ship project content or invent a generic
replacement I hadn't reviewed. Easy to add back later, genericized, if wanted.

## Step 8 — Validate

`claude plugin validate` on both the marketplace and the plugin. It passed, with
one warning — the `bootstrap` command had no frontmatter — which was moot once
`bootstrap` was removed. Re-validated clean.

## Step 9 — License and attribution

Thirteen of the eighteen skills share names with the community
[Superpowers](https://github.com/obra/superpowers) project. Rather than guess its
license, I read the actual `LICENSE` in my installed copy: **MIT, © 2025 Jesse
Vincent**. MIT permits redistribution but requires preserving the copyright and
license notice.

So: a dual-copyright MIT `LICENSE` (mine + Jesse Vincent's notice retained), a
`license` field in `plugin.json`, and an accurate README attribution section that
names exactly which 13 skills are derived and which 5 skills + 4 agents are
original. I verified the Superpowers repo URL from my local marketplace config
rather than typing a plausible one.

## Step 10 — Ship

`git init`, a single clean initial commit (amended to fold in the LICENSE), then
a **private** GitHub repo created and pushed over SSH:

```bash
gh repo create joe-bag-of-tricks --private --source=. --remote=origin --push
```

Private was the right default while the license/attribution question was fresh —
flippable to public anytime.

## Step 11 — The private-repo install correction

The first README said `/plugin marketplace add jwp23/joe-bag-of-tricks`. For a
*private* repo that shorthand isn't the most reliable form. I verified how
private-repo auth actually works and corrected the README to lead with the SSH
URL form (`git@github.com:jwp23/joe-bag-of-tricks.git`), note that the shorthand
works with a configured credential helper, and note that background auto-update
needs a `GITHUB_TOKEN`. Per my own never-touch-`main` rule, that correction
landed as a branch + PR, not a direct push.

---

## What I'd tell myself before starting

- **Look first, design second.** The grep for project-specific strings answered
  the "how much do I have to genericize?" question before I'd committed to a plan.
- **Two facts kill the fun idea early.** No per-component toggle + mandatory
  namespacing meant "mix-and-match plugins" was never really on the table for
  coupled skills. Learning that up front saved a bad split.
- **Name once, match everything.** The naming detour was the biggest time sink
  for the smallest surface. Matching all three names ended it.
- **Don't invent — verify.** Format from the docs, license from the real
  `LICENSE`, repo URL from local config. Every place I could have guessed, I
  looked instead.
