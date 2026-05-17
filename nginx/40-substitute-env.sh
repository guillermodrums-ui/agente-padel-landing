#!/bin/sh
set -e

: "${WA_NUMBER:?WA_NUMBER must be set}"
: "${FORMSPREE_ENDPOINT:?FORMSPREE_ENDPOINT must be set}"

envsubst '${WA_NUMBER} ${FORMSPREE_ENDPOINT}' \
    < /usr/share/nginx/html/index.html.template \
    > /usr/share/nginx/html/index.html

rm -f /usr/share/nginx/html/index.html.template
