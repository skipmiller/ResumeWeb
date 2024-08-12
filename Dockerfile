# --- Base Image ---
    FROM node:lts-bullseye-slim AS base

    # Commented out NX Cloud ARG since it's not being used
    # ARG NX_CLOUD_ACCESS_TOKEN
    
    ENV PNPM_HOME="/pnpm"
    ENV PATH="$PNPM_HOME:$PATH"
    
    RUN corepack enable pnpm && corepack prepare pnpm@9.0.6 --activate
    
    WORKDIR /app
    
    # --- Build Image ---
    FROM base AS build
    
    # Commented out NX Cloud ARG since it's not being used
    # ARG NX_CLOUD_ACCESS_TOKEN
    
    COPY .npmrc package.json pnpm-lock.yaml ./
    COPY ./tools/prisma /app/tools/prisma
    RUN pnpm install --frozen-lockfile
    
    COPY . .
    
    # Commented out NX Cloud ENV since it's not being used
    # ENV NX_CLOUD_ACCESS_TOKEN=$NX_CLOUD_ACCESS_TOKEN
    
    RUN pnpm run build
    
    # --- Release Image ---
    FROM base AS release
    
    # Commented out NX Cloud ARG since it's not being used
    # ARG NX_CLOUD_ACCESS_TOKEN
    
    RUN apt update && apt install -y dumb-init --no-install-recommends && rm -rf /var/lib/apt/lists/*
    
    COPY --chown=node:node --from=build /app/.npmrc /app/package.json /app/pnpm-lock.yaml ./
    RUN pnpm install --prod --frozen-lockfile
    
    COPY --chown=node:node --from=build /app/dist ./dist
    COPY --chown=node:node --from=build /app/tools/prisma ./tools/prisma
    RUN pnpm run prisma:generate
    
    ENV TZ=UTC
    ENV PORT=3000
    ENV NODE_ENV=production
    
    EXPOSE 3000
    
    CMD ["dumb-init", "pnpm", "run", "start"]