# client-facing web app: serves whatever is on main of /shared/webapp.git
# and exposes that repo as git://webapp/webapp.git for the framework to clone and push
FROM nginx:1.27-alpine
RUN apk add --no-cache git git-daemon \
    && git config --system --add safe.directory '*'
COPY site /seed
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY live.js /live/__live.js
COPY sync.sh /docker-entrypoint.d/90-sync.sh
RUN chmod +x /docker-entrypoint.d/90-sync.sh
EXPOSE 80 9418
