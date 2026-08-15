"""Register skill-creator's probe skill where Claude Code can actually see it.

skill-creator's `scripts/run_eval.py` advertises the description under test by
writing `<project>/.claude/commands/<probe-name>.md`. Claude Code 2.1.220 lists
that file under `slash_commands` only, never under `skills`, and exposes no tool
for invoking a project command — so the model can never reach the probe and every
query scores 0 triggers, positives and negatives alike. Measured 0/3 on all 18
queries of a working eval set before this shim.

This wraps `run_single_query` so the same probe is ALSO written as a real skill at
`<project>/.claude/skills/<probe-name>/SKILL.md`, which is what the model sees and
what skill-creator's own detector already matches on (a `Skill` tool_use whose
input carries the probe name). Nothing under `~/.claude/plugins/` is modified —
the upstream function still does the work.

The probe-file body written below is DERIVED from skill-creator: the frontmatter
block scalar, the `# {skill_name}` heading, and the "This skill handles: ..." line
reproduce upstream's `command_content` so the two probes carry byte-identical
descriptions. That is a compatibility requirement, not a stylistic one — the probe
must match upstream's format for the same eval to mean the same thing. Likewise
`run_eval`'s `f"{skill_name}-skill-{unique_id}"` naming and its module-global use
of `uuid` are reproduced so the shim can predict the name upstream will pick.

  Derived from: anthropics/skills, skills/skill-creator/scripts/run_eval.py
  (`run_single_query`), licensed Apache-2.0 per skills/skill-creator/LICENSE.txt.

Loaded as `sitecustomize`, not imported by hand, because `run_eval` fans out over a
`ProcessPoolExecutor` whose workers re-import the module (Python 3.14 defaults to
the `forkserver` start method on Linux, so a patch applied only in the parent is
lost). Every interpreter imports `sitecustomize` at startup, workers included. The
replacement is a module-level function for the same reason: `submit()` pickles it
by name, which a closure could not satisfy.

Activated only when `SKILL_EVAL_SHIM=1` is set, so it is inert for anything else
that happens to have this directory on `PYTHONPATH`.

Delete this file once skill-creator registers its probe as a skill upstream.
"""

import os
import shutil
import tempfile
import uuid
from pathlib import Path

_ORIGINAL = None


class _FixedUuid:
    """Stand-in for `uuid.uuid4()`, carrying a hex we chose in advance."""

    def __init__(self, hex_value: str) -> None:
        self.hex = hex_value


class _FixedUuidModule:
    """Stand-in for the `uuid` module `run_eval` calls `uuid4().hex[:8]` on."""

    def __init__(self, hex_value: str) -> None:
        self._hex = hex_value

    def uuid4(self) -> _FixedUuid:
        return _FixedUuid(self._hex)


def run_single_query(
    query: str,
    skill_name: str,
    skill_description: str,
    timeout: int,
    project_root: str,
    model: str | None = None,
) -> bool:
    """Publish the probe as a project skill, then delegate to skill-creator.

    Each call gets a private copy of the fixture. `run_eval` fans out ten workers
    over one project root, and skills — unlike the command files upstream writes —
    are all visible to every concurrent session at once. Ten skills with identical
    descriptions and different names makes the model read one and invoke another,
    which the detector scores as a miss.
    """
    from scripts import run_eval

    if _ORIGINAL is None:
        # A worker that imported this module without running _install() would
        # otherwise die on a TypeError deep in the pool and score the query 0.
        raise SystemExit(
            "skill-eval-shim: run_single_query called with no wrapped original — "
            "the shim did not install in this interpreter."
        )

    # Fix the probe id up front so we know the name the wrapped call will use.
    probe_id = uuid.uuid4().hex[:8]
    run_eval.uuid = _FixedUuidModule(probe_id)
    probe_name = f"{skill_name}-skill-{probe_id}"

    workroot = os.environ.get("SKILL_EVAL_WORKROOT") or tempfile.gettempdir()
    Path(workroot).mkdir(parents=True, exist_ok=True)
    private_root = Path(tempfile.mkdtemp(prefix="probe-", dir=workroot))
    shutil.rmtree(private_root)
    shutil.copytree(project_root, private_root, ignore=shutil.ignore_patterns(".claude"))

    skill_dir = private_root / ".claude" / "skills" / probe_name
    indented = "\n  ".join(skill_description.split("\n"))
    skill_dir.mkdir(parents=True, exist_ok=True)
    (skill_dir / "SKILL.md").write_text(
        f"---\n"
        f"name: {probe_name}\n"
        f"description: |\n"
        f"  {indented}\n"
        f"---\n\n"
        f"# {skill_name}\n\n"
        f"This skill handles: {skill_description}\n"
    )
    try:
        return _ORIGINAL(query, skill_name, skill_description, timeout, str(private_root), model)
    finally:
        shutil.rmtree(private_root, ignore_errors=True)


def _install() -> None:
    """Patch `run_eval.run_single_query`, or kill the interpreter saying why.

    Every failure mode here is silent by nature: a shim that does not install
    scores 0/3 on every query, which is indistinguishable from a catastrophically
    bad description. `SystemExit` from `sitecustomize` is fatal and prints the
    traceback, so a broken shim stops the run instead of billing for a lie.
    """
    global _ORIGINAL
    try:
        from scripts import run_eval
    except ImportError as exc:
        raise SystemExit(
            f"skill-eval-shim: cannot import skill-creator's scripts.run_eval ({exc}). "
            "PYTHONPATH must carry the skill-creator root. Refusing to run: an "
            "uninstalled shim scores 0 triggers on every query."
        )
    if run_eval.run_single_query is run_single_query:
        return
    # The shim predicts the probe name and rewrites the probe file, so it depends
    # on two details of upstream's implementation. Assert them rather than let a
    # rename degrade into an all-zero scoreboard.
    if not hasattr(run_eval, "uuid"):
        raise SystemExit(
            "skill-eval-shim: run_eval no longer has a module-global `uuid`; the "
            "probe-id override cannot work. Re-read run_single_query upstream."
        )
    import inspect

    if "-skill-" not in inspect.getsource(run_eval.run_single_query):
        raise SystemExit(
            "skill-eval-shim: run_eval.run_single_query no longer names its probe "
            "`<skill>-skill-<id>`; the predicted probe name would not match. "
            "Re-read run_single_query upstream."
        )
    _ORIGINAL = run_eval.run_single_query
    run_eval.run_single_query = run_single_query


if os.environ.get("SKILL_EVAL_SHIM") == "1":
    _install()
