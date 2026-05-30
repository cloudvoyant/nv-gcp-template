# syntax=docker/dockerfile:1
# Web service: 2-stage build
# Stage 1 (builder): mise-based full environment, builds the app
# Stage 2 (runtime): minimal alpine image with only the built output

ARG PROJECT=mise-app-template

# ---- Stage 1: Builder ----
FROM ${PROJECT}-base:local AS builder

WORKDIR /app

# Build production artifacts
RUN mise run build-prod

# ---- Stage 2: Runtime ----
FROM node:20-alpine AS runtime

WORKDIR /app

# Copy only the built output from builder (apps/web/build per svelte.config.js)
COPY --from=builder /app/apps/web/build ./build
COPY --from=builder /app/apps/web/package.json ./package.json

# Install only production runtime deps (no devDependencies)
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
