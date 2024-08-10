# --- Base Image ---
    FROM node:lts-bullseye-slim AS base
    ARG NX_CLOUD_ACCESS_TOKEN
    
    ENV PNPM_HOME="/pnpm"
    ENV PATH="$PNPM_HOME:$PATH"
    
    # Install pnpm via corepack
    RUN corepack enable pnpm && corepack prepare pnpm@9.0.6 --activate
    
    WORKDIR /app
    
    # --- Build Image ---
    FROM base AS build
    ARG NX_CLOUD_ACCESS_TOKEN
    
    COPY package.json pnpm-lock.yaml ./
    COPY ./tools/prisma /app/tools/prisma
    RUN pnpm install --frozen-lockfile
    
    COPY . .
    
    ENV NX_CLOUD_ACCESS_TOKEN=$NX_CLOUD_ACCESS_TOKEN
    
    RUN pnpm run build
    