# syntax=docker/dockerfile:1
# Web service: 2-stage build
# Stage 1 (builder): mise-based full environment, builds the app
# Stage 2 (runtime): minimal alpine image with only the built output

ARG PROJECT=mise-app-template

# ---- Stage 1: Builder ----
FROM ${PROJECT}-base:local AS builder

# Re-declare ARG after FROM so it is available in RUN commands
ARG PROJECT=mise-app-template
WORKDIR /app

# Build the SvelteKit web app
RUN pnpm --filter "@${PROJECT}/web" build

# Generate a runtime package.json — strip workspace:* entries since those libs
# are TypeScript-only and already bundled by Vite into the server output.
RUN python3 -c "import json; pkg=json.load(open('apps/web/package.json')); deps={k:v for k,v in (pkg.get('dependencies') or {}).items() if not v.startswith('workspace:')}; json.dump({'type':'module','dependencies':deps},open('runtime-package.json','w'))"

# ---- Stage 2: Runtime ----
FROM node:20-alpine AS runtime

WORKDIR /app

# Copy the built output from builder (apps/web/build per svelte.config.js).
# Workspace packages (@mise-app-template/*) are TypeScript libs bundled by Vite —
# they do not appear in the runtime deps.
COPY --from=builder /app/apps/web/build ./build
COPY --from=builder /app/runtime-package.json ./package.json

# Install only the real npm deps (no workspace:* entries)
RUN npm install --omit=dev --ignore-scripts

ENV NODE_ENV=production
ENV PORT=8080
ENV HOST=0.0.0.0
EXPOSE 8080

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 --ingroup nodejs nodejs && \
    chown -R nodejs:nodejs /app
USER nodejs

CMD ["node", "build"]
