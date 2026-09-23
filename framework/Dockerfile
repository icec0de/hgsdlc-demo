# HG SDLC framework: backend + bundled UI + OpenCode CLI (talks to OpenRouter)
# build context = hgsdlc_demo/

FROM node:23.5.0-alpine AS frontend
WORKDIR /fe
COPY hgsdlc/frontend/package.json hgsdlc/frontend/package-lock.json ./
RUN npm ci
COPY hgsdlc/frontend/ ./
RUN npm run build

FROM gradle:8.8-jdk21 AS backend
WORKDIR /workspace
COPY hgsdlc/backend/settings.gradle.kts hgsdlc/backend/build.gradle.kts hgsdlc/backend/gradlew ./
COPY hgsdlc/backend/gradle ./gradle
COPY hgsdlc/backend/src ./src
# serve the UI from the backend jar (StaticFrontendController forwards SPA routes to index.html)
COPY --from=frontend /fe/dist ./src/main/resources/static
RUN chmod +x ./gradlew && ./gradlew --no-daemon clean bootJar -PskipFrontend=true -x test

FROM eclipse-temurin:21-jre-jammy
ARG OPENCODE_VERSION=latest
ARG NODE_VERSION=23.5.0
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl bash git jq xz-utils \
    && arch="$(dpkg --print-architecture)" \
    && case "${arch}" in amd64) a=x64 ;; arm64) a=arm64 ;; *) exit 1 ;; esac \
    && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${a}.tar.xz" \
       | tar -xJ -C /usr/local --strip-components=1 --no-same-owner \
    && npm install -g "opencode-ai@${OPENCODE_VERSION}" \
    && npm cache clean --force \
    && rm -rf /var/lib/apt/lists/* \
    && git config --system --add safe.directory '*'

RUN useradd --create-home --uid 10001 --shell /bin/bash app \
    && mkdir -p /app /data /tmp/workspace /home/app/.config/opencode \
    && chown -R app:app /app /data /tmp/workspace /home/app

COPY --from=backend /workspace/build/libs/*.jar /app/app.jar
COPY framework/entrypoint.sh framework/setup.sh /app/
COPY framework/flow /app/flow
RUN chmod +x /app/*.sh

ENV HOME=/home/app
WORKDIR /app
USER app
EXPOSE 8080
ENTRYPOINT ["/app/entrypoint.sh"]
