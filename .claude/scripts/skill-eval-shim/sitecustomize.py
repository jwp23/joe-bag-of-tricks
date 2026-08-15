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
input carries the probe name). Nothing is copied from skill-creator and nothing
under `~/.claude/plugins/` is modified — the upstream function still does the work.

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
    global _ORIGINAL
    try:
        from scripts import run_eval
    except ImportError:
        return
    if run_eval.run_single_query is run_single_query:
        return
    _ORIGINAL = run_eval.run_single_query
    run_eval.run_single_query = run_single_query


if os.environ.get("SKILL_EVAL_SHIM") == "1":
    _install()
