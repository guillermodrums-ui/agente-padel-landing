#!/bin/sh
set -e

# Render index.html from a template on EVERY boot — and this MUST be idempotent.
# Railway restarts the SAME container (the writable layer is preserved) under
# restartPolicyType=ON_FAILURE, so anything that only works on the first boot
# turns a single restart into a permanent crash-loop -> 502 for the whole site.
#
# Past bug (the 502 this fixes): the template was COPYed into the web root and
# this script `rm`-ed it after rendering. On the first restart the template was
# already gone, `envsubst < .../index.html.template` failed, and `set -e` aborted
# the nginx entrypoint BEFORE `exec nginx` -> container exits 1 -> ON_FAILURE
# restart -> same crash again -> permanent 502. (Confirmed in Railway deploy logs
# + reproduced locally with `docker run` then `docker restart`.)
#
# Fix: the template now lives OUTSIDE the web root (so nginx never serves it) and
# is NEVER deleted. We just regenerate index.html from it on each boot.
TEMPLATE=/usr/share/nginx/templates/index.html.template
OUTPUT=/usr/share/nginx/html/index.html

# Boot-anyway hardening: a missing env var degrades the lead form but must NOT
# crash the container. During market validation a 502 landing (whole site down)
# is worse than a form with a degraded destination. We warn loudly to stderr
# instead of hard-crashing the boot (was: `: "${VAR:?...}"`, which aborted the
# nginx entrypoint under `set -e` and put the service in a crash-loop).
if [ -z "${WA_NUMBER:-}" ]; then
    echo "WARN: WA_NUMBER unset — lead form WhatsApp link degraded" >&2
    export WA_NUMBER=""
fi

if [ -z "${FORMSPREE_ENDPOINT:-}" ]; then
    echo "WARN: FORMSPREE_ENDPOINT unset — lead form submissions will not be delivered" >&2
    export FORMSPREE_ENDPOINT=""
fi

# Defense in depth: a missing template must NEVER abort the boot. With the fix
# above this branch should not trigger, but if the template ever disappears we
# keep any already-rendered index.html instead of crash-looping into a 502.
if [ -f "$TEMPLATE" ]; then
    envsubst '${WA_NUMBER} ${FORMSPREE_ENDPOINT}' < "$TEMPLATE" > "$OUTPUT"
else
    echo "WARN: $TEMPLATE missing — serving existing index.html as-is" >&2
fi
