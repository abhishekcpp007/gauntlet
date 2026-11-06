"""Print the non-Gauntlet requirements of the given project directories.

compose.dev.yaml installs the six packages from sibling folders. arena and
harness declare the four libraries as git direct references, so handing pip a
local path and that URL for the same name makes it give up with
ResolutionImpossible. We install the libraries from disk, install arena and
harness with --no-deps, and feed pip their third-party requirements from here.
"""

from __future__ import annotations

import sys
import tomllib
from pathlib import Path


def requirements(project: Path, extras: list[str]) -> list[str]:
    data = tomllib.loads((project / "pyproject.toml").read_text(encoding="utf-8"))
    table = data["project"]
    reqs = list(table.get("dependencies", []))
    optional = table.get("optional-dependencies", {})
    for name in extras:
        reqs += optional.get(name, [])
    return [r for r in reqs if not r.replace("_", "-").startswith("gauntlet-")]


def main(argv: list[str]) -> int:
    extras = ["claude", "gym"]
    found: set[str] = set()
    for arg in argv:
        found.update(requirements(Path(arg), extras))
    print("\n".join(sorted(found)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
