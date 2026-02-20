# syntax=docker/dockerfile:1
# Web service: build from base, run production server
# Note: PROJECT arg is passed from docker-compose.yml (sourced from .envrc).

ARG PROJECT
FROM ${PROJECT}-base:local

WORKDIR /app

RUN just build

ENV NODE_ENV=production
ENV PORT=8080
ENV HOST=0.0.0.0
EXPOSE 8080

RUN groupadd --system --gid 1001 nodejs && \
  useradd --system --uid 1001 --gid nodejs nodejs && \
  chown -R nodejs:nodejs /app
USER nodejs

WORKDIR /app/apps/web
CMD ["node", "build"]
