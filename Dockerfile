# Lightweight Plow Chat configuration over the official Hermes base image.
# Ref: https://github.com/plow-pbc/plow-hermes-agent
FROM public.ecr.aws/e1h7x4a2/plow-cloud-agents:base-8710797b6409c77df560c6198407765d138ea617

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

# Hermes Cat Paw adds context only. Operational skills remain owned by the Hermes
# installation that runs this image.
COPY --chown=10000:10000 skills/ /var/lib/hermes/skills/
COPY --chown=10000:10000 skills/ /opt/hermes/skills/

# Normaliza modos sem mexer no dono do root de skills (que é da base).
RUN find /opt/hermes/skills -type d -exec chmod 0755 {} + \
 && find /opt/hermes/skills -type f -exec chmod 0644 {} + \
 && find /var/lib/hermes/skills -type d -exec chmod 0755 {} + \
 && find /var/lib/hermes/skills -type f -exec chmod 0644 {} +

COPY image/s6-overlay/ /etc/s6-overlay/
RUN chmod 0755 /etc/s6-overlay/s6-rc.d/agent-index/run

# The fleet pin's `_prime` omits `_channel_prompt`'s `authority` argument.
# That TypeError kills the websocket on first install; reconnects then log
# `grant read failed: ClientResponseError`. Patch in place so we keep the
# audited base and only the two known failure paths change.
COPY image/plow_chat/patch_plugin.py /tmp/patch_plow_chat.py
RUN python3 /tmp/patch_plow_chat.py && rm /tmp/patch_plow_chat.py
