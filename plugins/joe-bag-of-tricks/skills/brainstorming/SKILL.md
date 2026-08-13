---
name: brainstorming
description: "Use when starting creative work - creating features, building components, adding functionality, or modifying behavior. Also use when in plan mode and the user asks to brainstorm or design. Explores user intent, requirements and design before implementation."
---

# Brainstorming Ideas Into Designs

Help turn ideas into fully formed designs through natural collaborative dialogue.

Start by classifying how much process the request needs, then work
through your path: understand the context, refine the idea, present a
design, and get your human partner's approval.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any
project, or take any implementation action until you have told your
human partner what you intend and they have approved it. This applies
to EVERY task on EVERY path below — the ceremony scales with the task;
the approval gate never does.
</HARD-GATE>

## Three Paths

Before your first question, classify the request and say the
classification out loud — "this looks bounded, so I'll present a short
design here rather than write a design doc" — so your human partner can
override it:

- **Spike** — a feasibility question ("can we...", "is it possible...",
  "quick and dirty is fine") whose output is an answer, not code you
  keep. Present the question and what you'll try in 2-3 sentences, get
  a nod, then find out as cheaply as correctness allows. No design
  doc, no bd epic. Report findings as a recommendation; anything you
  built stays labeled throwaway.
- **Bounded** — a well-scoped change to code that already exists in
  this repo: a new flag, a small endpoint, a one-file fix.
  Understanding the kind of app is not enough — bounded means the flow
  you are changing is already here to read. If there is no existing
  flow to change, the task is not bounded. Ask the clarifying
  questions that matter, present a short design IN CHAT (a few
  sentences to a few short paragraphs), and STOP. Implementation
  starts only after your human partner says yes to that design — a
  bounded task's approval is as hard a gate as an architectural
  one. No design doc edit, no bd epic hierarchy — track the change in
  a single bd task and implement via the normal development workflow.
- **Architectural** — new projects, new subsystems, changes that
  restructure how components fit together or alter interfaces others
  depend on. Follow the full process: questions, approaches, sectioned
  design, living design doc, bd epic carrying the spec, then the
  writing-plans skill.

When in doubt between two paths, take the heavier one. The ratchet is
one-way: hidden complexity discovered mid-task upgrades the path —
stop, say so, and step up. Nothing downgrades mid-task.

## Plan Mode Integration

When you are in plan mode (`EnterPlanMode` / `/plan`) and the user asks to brainstorm or design a feature, this skill still applies. Plan mode limits your tools (no Write/Edit), so the workflow adapts:

**In plan mode:**

1. Classify the path first, out loud, exactly as the Three Paths section requires — spike and bounded work runs its (fully conversational) path inside plan mode and exits via `ExitPlanMode` with the probe plan or short design as the plan
2. On the architectural path, run checklist steps 1-5 normally (explore context, visual companion, clarify, propose approaches, present design) — these are conversational and work with available tools
3. When the design is approved, write a summary to the plan file: design overview, components, key decisions, and note that next steps are design doc writing + bd epic creation
4. Call `ExitPlanMode` to present the design for approval
5. After approval (now outside plan mode with full tools): continue with architectural steps 6-10 — write design doc, design self-review, user review, create bd epic, invoke writing-plans

**The conversational design IS the plan mode output.** File operations happen after exiting plan mode.

**Red flags — you are doing it wrong if:**
- You skip brainstorming because "Write isn't available in plan mode"
- You jump to writing-plans ad-hoc path without a design or design doc
- You do freeform design discussion without invoking this skill
- You exit plan mode without presenting the design summary first

## Anti-Pattern: "Too Simple To Need Approval"

Every path ends with your human partner approving your intent before
implementation. A todo list, a single-function utility, a config
change — the design may be two sentences in chat, but you MUST present
it and get approval. "Simple" tasks are where unexamined assumptions
cause the most wasted work. What scales with simplicity is the
artifact, never the approval.

## Red Flags

| Thought | Reality |
|---------|---------|
| "This is too simple to need a design" | Simple means a short design, not no design. Two sentences in chat, then approval. |
| "I'll call it bounded and skip the design doc and epic" | Reaching for a label to skip work IS the doubt — take the heavier path. |
| "It's bounded and the design is obvious — I'll start while they read it" | The gate is the approval, not the design's length. Present, then stop until you hear yes. |
| "I understand this kind of app, so it's bounded" | Bounded measures the repo, not your familiarity. A new project has no existing flow — it is architectural. |
| "The spike works, so I'll keep the code" | A spike's output is an answer. Keeping the code is a new request — classify it. |
| "It grew, but I'm almost done — no need to re-classify" | Hidden complexity upgrades the path mid-task. Stop and say so. |
| "They approved the spike, so the follow-up change is approved too" | Each task gets its own classification and its own approval. |

## Checklist

Classify first, announce the path, then create a task for each item on
your path and complete them in order.

**Spike:**
1. **Explore project context** — enough to frame the probe
2. **Present question + probe plan** — 2-3 sentences
3. **Get approval** — a nod is enough
4. **Investigate** — as cheaply as correctness allows
5. **Report findings** — a recommendation; label anything built as throwaway

**Bounded:**
1. **Explore project context** — check files, docs, recent commits
2. **Ask clarifying questions** — one at a time, the ones that matter
3. **Present short design in chat** — approach, files touched, testing
4. **Get approval** — STOP and wait for an explicit yes; presenting the design and starting in the same breath is skipping the gate
5. **Implement** — create a single bd task for the change, then proceed with the normal development workflow (TDD applies); no design doc, no epic

**Architectural:**
1. **Explore project context** — check files, docs (including `docs/designs/` for a doc covering this area), recent commits
2. **Offer the visual companion just-in-time** — NOT upfront. The first time a question would genuinely be clearer shown than described, offer it then (its own message); on approval its browser tab opens for you. If no visual question ever arises, never offer it. See the Visual Companion section below.
3. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
4. **Propose 2-3 approaches** — with trade-offs and your recommendation
5. **Present design** — in sections scaled to their complexity, get user approval after each section
6. **Create or update the design doc** — new subsystem: create `docs/designs/<topic>.md`; existing subsystem: update its doc in place. Commit. See Documentation section below.
7. **Design self-review** — quick inline check for placeholders, contradictions, ambiguity, scope (see below)
8. **User reviews the design doc** — ask user to review it before proceeding
9. **Create bd epic and decompose into features/bugs** — the epic carries this change's spec (requirements/acceptance/trade-offs); see Work Decomposition section below
10. **Transition to implementation** — invoke writing-plans skill with the epic ID

## Process Flow

```dot
digraph brainstorming {
    "Classify: spike / bounded / architectural" [shape=diamond];
    "Present question + probe (2-3 sentences)" [shape=box];
    "Ask clarifying questions (bounded)" [shape=box];
    "Present short design in chat" [shape=box];
    "Human approves?" [shape=diamond];
    "Investigate; report recommendation" [shape=doublecircle];
    "Create single bd task; implement via\nnormal workflow (no design doc, no epic)" [shape=doublecircle];
    "Hidden complexity? Upgrade path" [shape=box];
    "Explore project context" [shape=box];
    "Ask clarifying questions" [shape=box];
    "Propose 2-3 approaches" [shape=box];
    "Present design sections" [shape=box];
    "User approves design?" [shape=diamond];
    "Design doc exists\nfor this area?" [shape=diamond];
    "Write design doc\n(create or update)" [shape=box];
    "Design self-review\n(fix inline)" [shape=box];
    "User reviews design doc?" [shape=diamond];
    "Create bd epic\n(spec in --description/--design)" [shape=box];
    "Decompose into\nfeatures/bugs" [shape=box];
    "User approves\nhierarchy?" [shape=diamond];
    "Invoke writing-plans\nwith epic ID" [shape=doublecircle];

    "Classify: spike / bounded / architectural" -> "Present question + probe (2-3 sentences)" [label="spike"];
    "Classify: spike / bounded / architectural" -> "Ask clarifying questions (bounded)" [label="bounded"];
    "Classify: spike / bounded / architectural" -> "Explore project context" [label="architectural"];
    "Present question + probe (2-3 sentences)" -> "Human approves?";
    "Ask clarifying questions (bounded)" -> "Present short design in chat";
    "Present short design in chat" -> "Human approves?";
    "Human approves?" -> "Investigate; report recommendation" [label="spike: yes"];
    "Human approves?" -> "Create single bd task; implement via\nnormal workflow (no design doc, no epic)" [label="bounded: yes"];
    "Hidden complexity? Upgrade path" -> "Classify: spike / bounded / architectural";
    "Explore project context" -> "Ask clarifying questions";
    "Ask clarifying questions" -> "Propose 2-3 approaches";
    "Propose 2-3 approaches" -> "Present design sections";
    "Present design sections" -> "User approves design?";
    "User approves design?" -> "Present design sections" [label="no, revise"];
    "User approves design?" -> "Design doc exists\nfor this area?" [label="yes"];
    "Design doc exists\nfor this area?" -> "Write design doc\n(create or update)" [label="yes: update in place"];
    "Design doc exists\nfor this area?" -> "Write design doc\n(create or update)" [label="no: create new"];
    "Write design doc\n(create or update)" -> "Design self-review\n(fix inline)";
    "Design self-review\n(fix inline)" -> "User reviews design doc?";
    "User reviews design doc?" -> "Write design doc\n(create or update)" [label="changes requested"];
    "User reviews design doc?" -> "Create bd epic\n(spec in --description/--design)" [label="approved"];
    "Create bd epic\n(spec in --description/--design)" -> "Decompose into\nfeatures/bugs";
    "Decompose into\nfeatures/bugs" -> "User approves\nhierarchy?";
    "User approves\nhierarchy?" -> "Decompose into\nfeatures/bugs" [label="revise"];
    "User approves\nhierarchy?" -> "Invoke writing-plans\nwith epic ID" [label="approved"];
}
```

**Terminal states are path-bound.** Architectural: the ONLY skill you
invoke after brainstorming is writing-plans, with the epic ID — never
frontend-design, mcp-builder, or any other implementation skill. Bounded:
after approval, implementation proceeds directly through the normal
development workflow under a single bd task; no design doc, no epic. Spike:
the terminal state is a reported recommendation.

## The Process

The subsections below serve the bounded and architectural paths (a
spike stops at "present the probe, get a nod"). Sections from
**Exploring approaches** onward are architectural-path depth — for
bounded work, context plus a few questions plus a short in-chat design
is the whole process.

**Understanding the idea:**

- Check out the current project state first (files, docs, recent commits), including whether `docs/designs/` already has a doc covering the area you're about to change
- Before asking detailed questions, assess scope: if the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first.
- If the project is too large for a single design doc, help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built? Then brainstorm the first sub-project through the normal design flow. Each sub-project gets its own design doc → plan → implementation cycle.
- For appropriately-scoped projects, ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**

- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why
- YAGNI ruthlessly - remove unnecessary features from every approach and design
- When the user selects an approach, invoke **record-decision** to capture the choice and trade-offs

**Presenting the design:**

- Once you believe you understand what you're building, present the design
- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

**Design for isolation and clarity:**

- Break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently
- For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on?
- Can someone understand what a unit does without reading its internals? Can you change the internals without breaking consumers? If not, the boundaries need work.
- Smaller, well-bounded units are also easier for you to work with - you reason better about code you can hold in context at once, and your edits are more reliable when files are focused. When a file grows large, that's often a signal that it's doing too much.

**Working in existing codebases:**

- Explore the current structure before proposing changes. Follow existing patterns.
- Where existing code has problems that affect the work (e.g., a file that's grown too large, unclear boundaries, tangled responsibilities), include targeted improvements as part of the design - the way a good developer improves code they're working in.
- Don't propose unrelated refactoring. Stay focused on what serves the current goal.

## After the Design (architectural path)

**Documentation:**

`docs/designs/` holds **living** design docs — one per subsystem/component, describing the system's
current design. A change updates the relevant doc in place; it does not add a new dated file. The
per-change specifics (requirements, acceptance criteria, trade-offs for *this* change) don't belong
here — they go into the bd epic (see Work Decomposition below). This is bead-driven development: the
spec for a change lives in bd, not in a standalone markdown spec file.

- Check whether a relevant doc already exists: `ls docs/designs/` (or grep for the subsystem/component name)
  - **Existing subsystem:** open the doc and edit it in place so it reads as the current design — add,
    revise, or remove sections as needed. Don't append a changelog entry; the doc describes what the
    system *is*, not its history (that's what git history and record-decision ADRs are for).
  - **New subsystem:** create `docs/designs/<topic>.md`, named for the subsystem/component
    (kebab-case, no date prefix — e.g. `docs/designs/authentication.md`, not
    `docs/designs/2026-08-08-auth-design.md`)
- Use elements-of-style:writing-clearly-and-concisely skill if available
- Commit the design doc change to git

**Design Self-Review:**
After creating or updating the design doc, look at it with fresh eyes:

1. **Placeholder scan:** Any "TBD", "TODO", incomplete sections, or vague requirements? Fix them.
2. **Internal consistency:** Do any sections contradict each other — including parts of the doc you didn't touch this session? Does the architecture match the component descriptions?
3. **Scope check:** Is this focused enough for a single implementation plan, or does it need decomposition?
4. **Ambiguity check:** Could any requirement be interpreted two different ways? If so, pick one and make it explicit.

**User Review Gate:**
After the design self-review, ask the user to review the design doc before proceeding:

> "Design doc for `<topic>` [created/updated] at `<path>`. Please review it and let me know if you want to make any changes before we start writing out the implementation plan."

Wait for the user's response. If they request changes, make them and re-run the design self-review. Only proceed once the user approves.

**Work Decomposition:**

After the user approves the design doc, create the bd issue hierarchy. The epic carries the spec for
*this change* — requirements, acceptance criteria, and trade-offs live directly in bd now, not in a
separate spec file:

1. Create the epic:
   ```bash
   bd create "<project name>" -t epic \
     --description="<one-paragraph summary of what this builds and why>" \
     --design="$(cat <<'EOF'
   ## Requirements
   - <requirement 1>
   - <requirement 2>

   ## Acceptance Criteria
   - <criterion 1>

   ## Trade-offs
   - <trade-off decided during brainstorming, if not already captured by record-decision>
   EOF
   )" \
     --spec-id="docs/designs/<topic>.md" --json
   ```
   `--spec-id` links the epic back to the living design doc it's built on — a reference pointer, not
   the spec for this change (that's the `--description`/`--design` content above).

2. Decompose into features (or bugs) as children of the epic. Each feature represents a component or subsystem from the design:
   ```bash
   bd create "<component name>" -t feature \
     --parent <epic-id> \
     --description="<what this component does>" \
     --acceptance="<acceptance criteria>" --json
   ```

3. Present the hierarchy to the user:
   ```bash
   bd children <epic-id>
   ```
   Ask: "Here's how I've broken down the work. Does this decomposition look right?"

4. Revise if the user requests changes. Only proceed once approved.

**Implementation:**

- Invoke the writing-plans skill with the epic ID to create detailed tasks
- Do NOT invoke any other skill. writing-plans is the next step.

## Visual Companion

A browser-based companion for showing mockups, diagrams, and visual options during brainstorming. Available as a tool — not a mode. Accepting the companion means it's available for questions that benefit from visual treatment; it does NOT mean every question goes through the browser.

**Offering the companion (just-in-time):** Do NOT offer it upfront. Wait until a question would genuinely be clearer shown than told — a real mockup / layout / diagram question, not merely a UI *topic*. The first time that happens, offer it then, as its own message:
> "This next part might be easier if I show you — I can put together mockups, diagrams, and comparisons in a browser tab as we go. It's still new and can be token-intensive. Want me to? I'll open it for you."

**This offer MUST be its own message.** Only the offer — no clarifying question, summary, or other content. Wait for the user's response. If they accept, start the server with `--open` so their browser opens to the first screen automatically. If they decline, continue text-only and don't offer again unless they raise it.

**Per-question decision:** Even after the user accepts, decide FOR EACH QUESTION whether to use the browser or the terminal. The test: **would the user understand this better by seeing it than reading it?**

- **Use the browser** for content that IS visual — mockups, wireframes, layout comparisons, architecture diagrams, side-by-side visual designs
- **Use the terminal** for content that is text — requirements questions, conceptual choices, tradeoff lists, A/B/C/D text options, scope decisions

A question about a UI topic is not automatically a visual question. "What does personality mean in this context?" is a conceptual question — use the terminal. "Which wizard layout works better?" is a visual question — use the browser.

If they agree to the companion, read the detailed guide before proceeding:
`skills/brainstorming/visual-companion.md`
