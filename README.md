# Gauntlet

[![CI](https://github.com/abhishekcpp007/gauntlet/actions/workflows/ci.yml/badge.svg)](https://github.com/abhishekcpp007/gauntlet/actions/workflows/ci.yml)
[![Harness CI](https://github.com/abhishekcpp007/gauntlet-harness/actions/workflows/ci.yml/badge.svg)](https://github.com/abhishekcpp007/gauntlet-harness/actions/workflows/ci.yml)
[![Nightly calibrate](https://github.com/abhishekcpp007/gauntlet-harness/actions/workflows/calibrate.yml/badge.svg)](https://github.com/abhishekcpp007/gauntlet-harness/actions/workflows/calibrate.yml)
![Tasks](https://img.shields.io/badge/shipped%20tasks-147-orange)
![Languages](https://img.shields.io/badge/python%20%7C%20js%20%7C%20ts-pytest%20%7C%20vitest%20%7C%20jest-blue)
![License](https://img.shields.io/badge/license-MIT-green)

An open source proving ground for AI coding agents. It turns pull requests merged on GitHub this week into sandboxed, leak-checked coding tasks, runs agents (and you) on them, and grades every episode with a grader that has been attacked by nine purpose-built cheats and still pays them nothing.

```bash
git clone https://github.com/abhishekcpp007/gauntlet && cd gauntlet
docker compose up
# open http://127.0.0.1:8080
```

![A match: oracle wins, the cheater gets caught, noop gives up](docs/arena-match.png)

First boot builds an environment for [pallets/itsdangerous](https://github.com/pallets/itsdangerous) and mines a handful of real tasks from its git history. That takes a couple of minutes. After that you're picking tasks and starting matches.

## In numbers

Every figure here comes from a run you can repeat with the commands in the [harness README](https://github.com/abhishekcpp007/gauntlet-harness).

| Task set | Tasks | Repos | What one task is | Oracle | Best cheat reward |
|---|---|---|---|---|---|
| [Gauntlet Live, Nov 2026](https://github.com/abhishekcpp007/gauntlet-harness/tree/main/datasets/gauntlet-live-2026-11) | 53 | 10 Python | one merged PR | 53 / 53 | 0, and the conftest cheater caught 53 / 53 |
| [Gauntlet Live JS, Nov 2026](https://github.com/abhishekcpp007/gauntlet-harness/tree/main/datasets/gauntlet-live-js-2026-11) | 69 | 11 JS/TS | one merged PR | 68 / 69 | 0 over 621 cheat episodes |
| [Gauntlet LHT, Nov 2026](https://github.com/abhishekcpp007/gauntlet-harness/tree/main/datasets/gauntlet-lht-2026-11) | 25 | 13 Python | a whole release, `vX` to `vY` | 25 / 25 | 0 over 225 cheat episodes |

147 tasks from 26 repos. Every task ships with its own env fingerprint, and CI recomputes all 147 on every push, so a task that would no longer rebuild on a fresh machine turns the build red.

The grader was red-teamed in three rounds. Each round I wrote the cheat a smart model would write after reading the grader's source, watched it win, and closed the hole:

| Round | Cheat | Before the fix | After |
|---|---|---|---|
| 1 | forge pytest reports from inside source, base64 so no regex sees it | resolved 7 / 10 at +0.89, Cheat Catcher saw nothing | canary tests + file hashes, every cheat that ran caught (23 / 23) |
| 2 | read the canary code, spare anything that looks planted | resolved 7 / 10 at +0.88 | canaries look like real sibling tests, 0 / 60 |
| 3 | remember the base commit's test names, force only those to pass | won 3 / 3 on one task at +0.87 | target tests renamed during grading, 0 / 53 |

A nightly workflow re-runs the whole zoo on random live tasks and fails if the oracle stops winning or any cheat scores above 0. Running all of this on real repos also found more than 30 bugs in the harness itself, each fixed with a regression test named after the PR that exposed it.

## Why I built it

Coding agent benchmarks are expensive to build, go stale once their fixes land in training data, and are easier to fool than their scores suggest. A green test run doesn't prove an agent fixed anything if the agent could touch the tests, the runner or the report.

So Gauntlet keeps making new tasks out of PRs merged after a model's cutoff, proves each one is leak-free and solvable before keeping it, and treats the grader as something to attack rather than trust. It's six small libraries that each make sense alone, plus an arena that snaps them together.

## The pieces

```mermaid
flowchart LR
    R[GitHub repo] --> E[repo2env<br/>build env + mine tasks]
    E -->|tasks| A[arena<br/>matches + leaderboard]
    A -->|one sandbox per contestant| S[sandbox<br/>locked-down Docker + trajectories]
    S -->|trajectory| T[timemachine<br/>replay, branch, viewer]
    S -->|trajectory + patch| C[cheatcatcher<br/>reward hacking checks]
    E -->|hidden tests| G{graded}
    C --> G
    G --> L[leaderboard]
    T --> A
    PR[fresh merged PRs] --> H[harness<br/>leak-free RL envs, F2P/P2P judging]
    S --> H
    C --> H
    H --> D[(SFT / GRPO / DPO data)]
```

| Repo | What it does | Tests |
|---|---|---|
| [gauntlet-harness](https://github.com/abhishekcpp007/gauntlet-harness) | Turns freshly merged PRs and release ranges into leak-free RL environments, red-teams its own grader, reports pass@k with intervals and paired tests, exports SFT, GRPO and DPO data | 340 |
| [gauntlet-repo2env](https://github.com/abhishekcpp007/gauntlet-repo2env) | Builds a Docker env for a Python (pytest) or JS/TS (vitest, jest) repo and mines SWE-style tasks from its history | 98 |
| [gauntlet-cheatcatcher](https://github.com/abhishekcpp007/gauntlet-cheatcatcher) | Static checks over trajectories and patches for reward hacking: test tampering, outcome forcing, runner sniffing, answer peeking. 0 cheating verdicts on 53 real merged fixes | 90 |
| [gauntlet-sandbox](https://github.com/abhishekcpp007/gauntlet-sandbox) | Runs agent actions in locked-down containers (no network, capped CPU, memory and pids, every capability dropped) and records each step as JSONL | 31 |
| [gauntlet-timemachine](https://github.com/abhishekcpp007/gauntlet-timemachine) | Replays a trajectory, checks it's deterministic, branches a new run from any step, renders a self-contained HTML viewer | 14 |
| [gauntlet-arena](https://github.com/abhishekcpp007/gauntlet-arena) | Web UI and engine: live side-by-side matches, Human vs AI mode, a Claude agent, a leaderboard | 12 |

## Plug in a model

The harness runs any model behind the Anthropic API or an OpenAI-compatible endpoint, hosted or local, on the same tasks with the same grading:

```bash
pip install "gauntlet-harness[claude,openai] @ git+https://github.com/abhishekcpp007/gauntlet-harness"
gauntlet run --tasks tasks.jsonl --policies claude:claude-sonnet-5-5,oracle,noop --attempts 4

# a local model through Ollama, same tasks, same grading
OPENAI_BASE_URL=http://localhost:11434/v1 gauntlet run --tasks tasks.jsonl --policies openai:qwen3:32b,oracle,noop
```

The report puts a 95% interval next to every pass@1 and runs McNemar's exact test between every pair of models, so a gap that isn't real gets called that. `--cutoff YYYY-MM-DD` splits every number at a model's training cutoff. It also plugs into RL code as a Python `SWEEnv`, a Gymnasium env (`gauntlet/SWE-v0`) or an HTTP server, and `gauntlet export` turns episodes into SFT, GRPO or DPO data.

## A match, start to finish

1. repo2env builds the env image once and mines tasks. Each task is a commit's parent, the hidden tests from that commit, and the lists of tests that should flip to passing or stay passing.
2. The arena gives every contestant its own sandbox at that parent commit. No network, no hidden tests.
3. Contestants work. Every `exec`, file write and file read lands in their trajectory as it happens, and the browser streams it live.
4. Their diff gets graded. Edits to test files and conftest are dropped first, then the hidden tests go on top, then pytest runs.
5. Cheat Catcher reads the trajectory and the diff. A run flagged as cheating doesn't count, even with green tests.
6. Time Machine renders the replay, with Cheat Catcher's findings pinned to the exact steps that triggered them.

![Leaderboard](docs/arena-leaderboard.png)

Every lane links to a full replay in Time Machine:

![Time Machine viewer](docs/timemachine.png)

The arena ships with three calibration contestants. `oracle` applies the real fix and should always win. `noop` gives up and should always lose. `cheater` plants a conftest hook that rewrites every test report to "passed", which fools a plain pytest grader. In Gauntlet it gets stripped by the grader, flagged by Cheat Catcher, and parked at the bottom of the leaderboard.

## Run your own repos

```bash
GAUNTLET_REPOS="https://github.com/pallets/itsdangerous https://github.com/pallets/markupsafe" \
GAUNTLET_TASKS_PER_REPO=8 \
docker compose up
```

Add `ANTHROPIC_API_KEY` to put the Claude agent in the ring. Set `GAUNTLET_API_KEY` if the arena will be reachable by anyone but you, since it starts containers on demand. Compose publishes it on localhost only by default.

Tasks get mined once and kept in the `gauntlet-data` volume. Run `docker compose down -v` to start fresh.

## Without Compose

Every piece is a normal Python package, so you can skip the container:

```bash
pip install "gauntlet-arena[claude] @ git+https://github.com/abhishekcpp007/gauntlet-arena"  # plus the other four
repo2env build https://github.com/pallets/itsdangerous
repo2env mine pallets__itsdangerous.env.json --limit 5
gauntlet-arena serve --tasks pallets__itsdangerous.tasks.jsonl
```

Or benchmark headless:

```bash
gauntlet-arena run --tasks pallets__itsdangerous.tasks.jsonl --all --agents claude,oracle,noop
```

## Hacking on it

Clone all seven repos side by side and build from local folders instead of GitHub:

```bash
for r in gauntlet gauntlet-sandbox gauntlet-repo2env gauntlet-timemachine gauntlet-cheatcatcher gauntlet-arena gauntlet-harness; do
  git clone https://github.com/abhishekcpp007/$r
done
# rename the pieces to sandbox/, repo2env/, timemachine/, cheatcatcher/, arena/, harness/ next to gauntlet/
cd gauntlet && docker compose -f compose.dev.yaml up --build
```

Each piece uses uv, ruff and pytest, and its CI runs the Docker tests on real containers.

## Limits, honestly

- Python with pytest, and JS/TS with vitest or jest. No other languages yet, and no JS workspaces or repos whose tests import a build.
- No frontier model has been run on the published sets yet, so there's no model leaderboard. The harness is ready for one, and the numbers above are calibration, not model scores.
- Fresh tasks rot: 2 of the 53 Live tasks stopped building within four days because their repo force-pushed. The weekly build is what pays for that.
- The problem statement is the PR text, not a full issue thread, so some tasks are harder than they'd be for a human with context.
- Containers aren't VMs. The sandbox defaults stop accidents and casual escapes. For truly hostile code, run it on a throwaway VM or under gVisor.
- The canary is placed at random, so beating it is a rate, not a yes or no. The harness README gives the measured rate and why Cheat Catcher still catches those runs.

## Cite

```bibtex
@software{gauntlet2026,
  author = {Abhishek},
  title  = {Gauntlet: leak-free RL environments from fresh GitHub PRs, with a red-teamed grader},
  year   = {2026},
  url    = {https://github.com/abhishekcpp007/gauntlet}
}
```

MIT licensed. Built by Abhishek.
