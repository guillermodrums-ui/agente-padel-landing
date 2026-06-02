#!/bin/sh
set -e

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

envsubst '${WA_NUMBER} ${FORMSPREE_ENDPOINT}' \
    < /usr/share/nginx/html/index.html.template \
    > /usr/share/nginx/html/index.html

rm -f /usr/share/nginx/html/index.html.template
