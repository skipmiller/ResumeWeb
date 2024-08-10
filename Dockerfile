# --- Build Image ---
    FROM node:lts-bullseye-slim AS build
    ARG NX_CLOUD_ACCESS_TOKEN
    
    # Replace this
    COPY package.json pnpm-lock.yaml ./
    
    # With this if .npmrc is not required
    COPY package.json pnpm-lock.yaml ./
    COPY ./tools/prisma /app/tools/prisma
    
    RUN pnpm install --frozen-lockfile
    

# --- Release Image ---
FROM node:lts-bullseye-slim AS release
ARG NX_CLOUD_ACCESS_TOKEN

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

CMD [ "dumb-init", "pnpm", "run", "start" ]
