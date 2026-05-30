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

# Build the SvelteKit web app and produce a standalone production deployment.
# pnpm deploy resolves workspace:* deps and copies only prod node_modules.
RUN pnpm --filter "@${PROJECT}/web" build && \
    pnpm --filter "@${PROJECT}/web" deploy --legacy --prod /tmp/web-deploy

# ---- Stage 2: Runtime ----
FROM node:20-alpine AS runtime

WORKDIR /app

# Copy the built output and resolved production node_modules from builder.
# node_modules come from pnpm deploy (no workspace: protocol, no devDeps).
COPY --from=builder /app/apps/web/build ./build
COPY --from=builder /tmp/web-deploy/node_modules ./node_modules

ENV NODE_ENV=production
ENV PORT=8080
ENV HOST=0.0.0.0
EXPOSE 8080

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 --ingroup nodejs nodejs && \
    chown -R nodejs:nodejs /app
USER nodejs

CMD ["node", "build"]
