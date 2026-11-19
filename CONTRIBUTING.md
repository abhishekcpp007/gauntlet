# Contributing to Gauntlet

Thanks for looking. Gauntlet is young, so a small fix or a good bug report moves it a long way.

## Where things live

Gauntlet is seven repos. This one is the front door: the Docker image, the Compose files and the docs. The code is in the pieces.

| You want to change | Repo |
|---|---|
| How a PR becomes a task, grading, cheats, reports | [gauntlet-harness](https://github.com/abhishekcpp007/gauntlet-harness) |
| Building an env for a repo, mining tasks | [gauntlet-repo2env](https://github.com/abhishekcpp007/gauntlet-repo2env) |
| Reward hacking detectors | [gauntlet-cheatcatcher](https://github.com/abhishekcpp007/gauntlet-cheatcatcher) |
| Containers and trajectories | [gauntlet-sandbox](https://github.com/abhishekcpp007/gauntlet-sandbox) |
| Replay and the HTML viewer | [gauntlet-timemachine](https://github.com/abhishekcpp007/gauntlet-timemachine) |
| The web UI and matches | [gauntlet-arena](https://github.com/abhishekcpp007/gauntlet-arena) |

Not sure which one? Open the issue here and I'll move it.

## Good ways to start

- **Try a repo.** Run `repo2env build` and `repo2env mine` on a small, well-tested Python or JS repo and tell me how many tasks came out. A repo that gives zero tasks is a useful report too.
- **Write a cheat.** The grader is meant to be attacked. If you can make a run score above 0 without fixing the bug, that's the best issue you can file. See `ZOO` in `src/gauntlet_harness/policies.py` for the ones that exist.
- **Add a detector.** Cheat Catcher's rules are in `src/gauntlet_cheatcatcher/rules.py`. Every rule needs a test that fires on a cheat and a test that stays quiet on honest work.
- **Pick an issue** labelled [good first issue](https://github.com/abhishekcpp007/gauntlet/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) or [help wanted](https://github.com/abhishekcpp007/gauntlet/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22).

## Set up

Each piece is a normal Python package.

```bash
git clone https://github.com/abhishekcpp007/gauntlet-harness
cd gauntlet-harness
uv sync
uv run pytest          # Docker tests skip if Docker isn't running
uv run ruff check
```

To run the whole stack from local folders, follow "Hacking on it" in the [README](README.md#hacking-on-it).

## Before you open a PR

- Add a test that fails without your change and passes with it.
- Run `uv run pytest` and `uv run ruff check` in the repo you touched.
- Keep the diff small. One fix per PR.
- If you change a number in a README, say which command produced it.

## AI tools

Use them if you like. I do. Two asks: run the tests yourself, and be able to explain the change in your own words when I ask about it.

## Reporting a security problem

If you find a way out of the sandbox, please don't post the details in public. Open an issue that only says you found one, and I'll get in touch to take the details privately.

## Be kind

Assume good faith, keep it about the code, and remember everyone here is doing this in their spare time.
