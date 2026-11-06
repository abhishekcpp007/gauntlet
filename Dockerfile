# The whole Gauntlet stack in one image, installed straight from GitHub.
# It drives the host's Docker through the mounted socket, so every sandbox
# it starts is a sibling container, not a nested one.
FROM python:3.12-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends git \
 && rm -rf /var/lib/apt/lists/*

ARG GAUNTLET_REF=main
ARG GH=https://github.com/abhishekcpp007
# Only the two leaf packages. arena and harness each declare the four libraries
# as direct git references, so pip pulls them in. Naming a library here too
# would give pip a second URL for the same name (one with @REF, one without)
# and it refuses that with ResolutionImpossible.
RUN pip install --no-cache-dir \
    "gauntlet-arena[claude] @ git+${GH}/gauntlet-arena@${GAUNTLET_REF}" \
    "gauntlet-harness[claude,gym] @ git+${GH}/gauntlet-harness@${GAUNTLET_REF}"

COPY entrypoint.sh /usr/local/bin/gauntlet-entrypoint
RUN chmod +x /usr/local/bin/gauntlet-entrypoint

ENV GAUNTLET_CACHE=/data/cache
EXPOSE 8080
ENTRYPOINT ["gauntlet-entrypoint"]
