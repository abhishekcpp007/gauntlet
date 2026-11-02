# Gauntlet

![Repos](https://img.shields.io/badge/repos-7-blue) ![Live tasks](https://img.shields.io/badge/live%20tasks-53%20(Nov%202026)-orange) ![License](https://img.shields.io/badge/license-MIT-green)

An open source proving ground for AI coding agents. Point it at any Python repo and it turns the project's own history into graded coding tasks, then races agents (and you) on them in the browser, with every command recorded, replayable and checked for cheating.

```bash
git clone https://github.com/abhishekcpp007/gauntlet && cd gauntlet
docker compose up
# open http://127.0.0.1:8080
```

![A match: oracle wins, the cheater gets caught, noop gives up](docs/arena-match.png)

First boot builds an environment for [pallets/itsdangerous](https://github.com/pallets/itsdangerous) and mines a handful of real tasks from its git history. That takes a couple of minutes. After that you're picking tasks and starting matches.

## Why I built it

Coding agent benchmarks like SWE-bench are expensive to build and easy to fool. Somebody has to set up each repo, find commits that make good tasks, and trust that a green test run means the agent actually fixed something. I spent a lot of time on RL environments and trajectory work, and kept wanting one small toolkit that did the whole loop on any repo I chose, and that took cheating seriously.

So Gauntlet is five small libraries that each make sense alone, an arena that snaps them together, and an RL harness that turns this week's merged PRs into training environments.

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

| Repo | What it does | Standalone use |
|---|---|---|
| [gauntlet-sandbox](https://github.com/abhishekcpp007/gauntlet-sandbox) | Runs agent actions in locked-down containers (no network, capped CPU, memory and pids, every capability dropped) and records each step as a JSONL trajectory | Safe code execution for any agent or eval harness |
| [gauntlet-repo2env](https://github.com/abhishekcpp007/gauntlet-repo2env) | Builds a Docker env for a Python repo and mines SWE-style tasks from commits that change both code and tests | Make your own SWE-bench from any repo in minutes |
| [gauntlet-timemachine](https://github.com/abhishekcpp007/gauntlet-timemachine) | Replays a trajectory, checks it's deterministic, branches a new run from any step, and renders a self-contained HTML viewer | Debug agent runs step by step |
| [gauntlet-cheatcatcher](https://github.com/abhishekcpp007/gauntlet-cheatcatcher) | Static checks over trajectories and patches for reward hacking: test tampering, conftest hooks that force passes, runner sniffing, answer peeking | Audit any agent's output before you trust its score |
| [gauntlet-arena](https://github.com/abhishekcpp007/gauntlet-arena) | Web UI and engine: live side-by-side matches, Human vs AI mode, a Claude agent, a leaderboard | The whole thing, end to end |
| [gauntlet-harness](https://github.com/abhishekcpp007/gauntlet-harness) | Turns freshly merged GitHub PRs into leak-free RL environments, judges models on test transitions and rubrics, exports training data | A contamination-free benchmark and an RL gym in one |

## The RL harness

[gauntlet-harness](https://github.com/abhishekcpp007/gauntlet-harness) is the research end of the stack. It takes PRs merged on GitHub in the last few days, builds each one into a sandboxed task at the commit before the merge, and proves the task is leak-free and solvable before keeping it. Then it runs models in those tasks and judges every episode on F2P, N2P, S2P and P2P test transitions plus a Rubrics-as-Rewards rubric. Its methods follow SWE-bench, Multi-SWE-bench, SWE-rebench, SWE-RL and Rubrics as Rewards.

**Gauntlet Live, November 2026** is the first task set it made: 53 tasks from 186 PRs across 10 repos, all merged between September and October 2026. The oracle solves 53 of 53, and the cheater is caught on 53 of 53. A weekly workflow keeps making new ones. Building it on real PRs also exposed six bugs in the harness itself, and [the harness README](https://github.com/abhishekcpp007/gauntlet-harness#it-found-its-own-bugs) tells that story.

It plugs into RL code three ways: a Python `SWEEnv`, a Gymnasium env (`gauntlet/SWE-v0`) and an HTTP server for agents in any language. `gauntlet export` turns finished episodes into SFT transcripts, GRPO advantages or DPO pairs. It ships in the same image:

```bash
docker compose run --rm --entrypoint gauntlet arena pipeline --repo mahmoud/boltons \
  --merged-after 2026-09-01 --policies oracle,noop,cheater -o /data/runs
```

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

- Python repos with pytest only, for now.
- The env image is built at one commit, so tasks from much older history can fail if dependencies moved a lot.
- The problem statement is the commit message, not a GitHub issue. That makes some tasks harder than they'd be for a human with context.
- Containers aren't VMs. The sandbox defaults stop accidents and casual escapes. For truly hostile code, run it on a throwaway VM or under gVisor.
- Cheat Catcher is static analysis. It catches the known tricks with few false positives, and it's built to have new rules added as new tricks show up.

MIT licensed. Built by Abhishek.
