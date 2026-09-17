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

# Review + recon CLIs (gitleaks, nmap, nuclei, …) from vendor/review-tools.pin.
# The 818 playbooks are still cloned at install time. Live packets at an
# owned host still prefer Latch when it is connected.
COPY vendor/review-tools.pin /opt/cat-paw/review-tools.pin
COPY image/install-review-tools.sh /opt/cat-paw/install-review-tools.sh
RUN chmod 0755 /opt/cat-paw/install-review-tools.sh \
 && /opt/cat-paw/install-review-tools.sh
COPY image/verify-review-tools.sh /opt/cat-paw/verify-review-tools.sh
RUN chmod 0755 /opt/cat-paw/verify-review-tools.sh \
 && /opt/cat-paw/verify-review-tools.sh
ENV PATH="/opt/cat-paw/bin:/usr/local/bin:${PATH}" \
    TRIVY_CACHE_DIR=/opt/cat-paw/trivy-cache \
    GRYPE_DB_CACHE_DIR=/opt/cat-paw/grype-db \
    NUCLEI_TEMPLATES=/opt/cat-paw/nuclei-templates

# Hermes Cat Paw overlays product skills (Plow Chat, Plow Latch, cybersecurity
# pack routing, change-review, target-workspace, image-tools).
COPY --chown=10000:10000 skills/ /var/lib/hermes/skills/
COPY --chown=10000:10000 skills/ /opt/hermes/skills/

# Normaliza modos sem mexer no dono do root de skills (que é da base).
RUN find /opt/hermes/skills -type d -exec chmod 0755 {} + \
 && find /opt/hermes/skills -type f -exec chmod 0644 {} + \
 && find /var/lib/hermes/skills -type d -exec chmod 0755 {} + \
 && find /var/lib/hermes/skills -type f -exec chmod 0644 {} +

COPY image/s6-overlay/ /etc/s6-overlay/
RUN chmod 0755 /etc/s6-overlay/s6-rc.d/agent-index/run
