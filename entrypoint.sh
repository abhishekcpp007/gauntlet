#!/bin/sh
# First boot: build an env and mine tasks for every repo in GAUNTLET_REPOS.
# Later boots reuse what's already in /data/tasks. Then start the arena.
set -e

TASKS=/data/tasks
mkdir -p "$TASKS" /data/arena "$GAUNTLET_CACHE"

if ! ls "$TASKS"/*.tasks.jsonl >/dev/null 2>&1; then
  n=0
  for repo in ${GAUNTLET_REPOS:-https://github.com/pallets/itsdangerous}; do
    n=$((n + 1))
    echo "==> building $repo"
    if repo2env build "$repo" -o "$TASKS/repo$n.env.json"; then
      echo "==> mining tasks from $repo"
      repo2env mine "$TASKS/repo$n.env.json" --limit "${GAUNTLET_TASKS_PER_REPO:-5}" \
        --max-commits "${GAUNTLET_MAX_COMMITS:-500}" \
        -o "$TASKS/repo$n.tasks.jsonl" || echo "    no tasks found in $repo"
    else
      echo "    couldn't build $repo, skipping it"
    fi
  done
fi

# drop empty files so the arena doesn't trip over them
find "$TASKS" -name '*.tasks.jsonl' -size 0 -delete

if ! ls "$TASKS"/*.tasks.jsonl >/dev/null 2>&1; then
  echo "no tasks to serve. Set GAUNTLET_REPOS to Python repos with pytest suites." >&2
  exit 1
fi

exec gauntlet-arena serve --tasks "$TASKS"/*.tasks.jsonl --data /data/arena --host 0.0.0.0 --port 8080
