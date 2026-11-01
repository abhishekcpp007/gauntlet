# The whole Gauntlet stack in one image, installed straight from GitHub.
# It drives the host's Docker through the mounted socket, so every sandbox
# it starts is a sibling container, not a nested one.
FROM python:3.12-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends git \
 && rm -rf /var/lib/apt/lists/*

ARG GAUNTLET_REF=main
ARG GH=https://github.com/abhishekcpp007
RUN pip install --no-cache-dir \
    "gauntlet-sandbox @ git+${GH}/gauntlet-sandbox@${GAUNTLET_REF}" \
    "gauntlet-repo2env @ git+${GH}/gauntlet-repo2env@${GAUNTLET_REF}" \
    "gauntlet-timemachine @ git+${GH}/gauntlet-timemachine@${GAUNTLET_REF}" \
    "gauntlet-cheatcatcher @ git+${GH}/gauntlet-cheatcatcher@${GAUNTLET_REF}" \
    "gauntlet-arena[claude] @ git+${GH}/gauntlet-arena@${GAUNTLET_REF}"

COPY entrypoint.sh /usr/local/bin/gauntlet-entrypoint
RUN chmod +x /usr/local/bin/gauntlet-entrypoint

ENV GAUNTLET_CACHE=/data/cache
EXPOSE 8080
ENTRYPOINT ["gauntlet-entrypoint"]
