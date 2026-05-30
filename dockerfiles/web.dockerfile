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

# Generate a runtime package.json with only real npm deps (no workspace:* refs).
# Workspace libs (@mise-app-template/*) are TypeScript source bundled by Vite —
# they are inlined into the server output and not needed at runtime.
RUN node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('apps/web/package.json','utf8'));const deps=Object.fromEntries(Object.entries(p.dependencies||{}).filter(([,v])=>!v.startsWith('workspace:')));fs.writeFileSync('/app/runtime.json',JSON.stringify({type:'module',dependencies:deps}));"

# ---- Stage 2: Runtime ----
FROM node:20-alpine AS runtime

WORKDIR /app

# Copy the built output from builder (apps/web/build per svelte.config.js).
COPY --from=builder /app/apps/web/build ./build
COPY --from=builder /app/runtime.json ./package.json

# Install only the real npm deps
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
