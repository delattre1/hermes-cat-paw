# Lightweight Plow Chat configuration over the official Hermes base image.
# Pin is plow-pbc/plow-hermes-agent@8088c7f7 (plugin hermes-plugin-plow@c6987ab,
# which includes the setup-turn authority fix #144).
# Ref: https://github.com/plow-pbc/plow-hermes-agent
FROM public.ecr.aws/e1h7x4a2/plow-cloud-agents:base-8088c7f77f5ffd536a80c9dc302ebdb39e6be1d2

COPY vendor/client.pin /opt/plow/agent-index-client.pin
RUN set -eu; \
    sha="$(sed -n 's/^sha=//p' /opt/plow/agent-index-client.pin)"; \
    want="$(sed -n 's/^sha256=//p' /opt/plow/agent-index-client.pin)"; \
    path="$(sed -n 's/^path=//p' /opt/plow/agent-index-client.pin)"; \
    curl -fsS --max-time 60 -o /opt/plow/agent-index-client.py \
      "https://raw.githubusercontent.com/plow-pbc/agent-index-client/$sha/$path"; \
    got="$(sha256sum /opt/plow/agent-index-client.py | cut -d' ' -f1)"; \
    [ "$got" = "$want" ] || { echo "agent-index client checksum mismatch" >&2; exit 1; }; \
    chmod 0644 /opt/plow/agent-index-client.py

# Hermes Cat Paw overlays product skills (Plow Chat, Plow Latch, recon pack
# routing). Segment playbooks are cloned at install time, not baked here.
COPY --chown=10000:10000 skills/ /var/lib/hermes/skills/
COPY --chown=10000:10000 skills/ /opt/hermes/skills/

# Normaliza modos sem mexer no dono do root de skills (que é da base).
RUN find /opt/hermes/skills -type d -exec chmod 0755 {} + \
 && find /opt/hermes/skills -type f -exec chmod 0644 {} + \
 && find /var/lib/hermes/skills -type d -exec chmod 0755 {} + \
 && find /var/lib/hermes/skills -type f -exec chmod 0644 {} +

COPY image/s6-overlay/ /etc/s6-overlay/
RUN chmod 0755 /etc/s6-overlay/s6-rc.d/agent-index/run
