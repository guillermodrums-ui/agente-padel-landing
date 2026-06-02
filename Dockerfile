FROM nginx:1.27-alpine

RUN rm -f /etc/nginx/conf.d/default.conf /usr/share/nginx/html/index.html /usr/share/nginx/html/50x.html

COPY nginx/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY nginx/40-substitute-env.sh /docker-entrypoint.d/40-substitute-env.sh
RUN chmod +x /docker-entrypoint.d/40-substitute-env.sh

# Keep the HTML template OUTSIDE the web root: nginx never serves it, and it
# survives container restarts so the entrypoint can regenerate index.html from
# it idempotently on every boot. (Putting it in the web root + deleting it after
# the first render caused a crash-loop 502 on Railway restarts — see
# nginx/40-substitute-env.sh.)
COPY public/index.html.template /usr/share/nginx/templates/index.html.template

ENV PORT=8080
EXPOSE 8080
