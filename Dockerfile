# --- Base Image ---
    FROM node:lts-bullseye-slim AS base

    # ARG for sensitive data (consider using Docker secrets or environment variables in production)
    ARG NX_CLOUD_ACCESS_TOKEN
    
    # Set environment variables for pnpm
    ENV PNPM_HOME="/pnpm"
    ENV PATH="$PNPM_HOME:$PATH"
    
    # Install pnpm via corepack
    RUN corepack enable pnpm && corepack prepare pnpm@9.0.6 --activate
    
    # Set the working directory
    WORKDIR /app
    
    # --- Build Image ---
    FROM base AS build
    
    # ARG for sensitive data (same as above)
    ARG NX_CLOUD_ACCESS_TOKEN
    
    # Copy necessary files for the build
    COPY package.json pnpm-lock.yaml ./
    COPY ./tools/prisma /app/tools/prisma
    
    # Install dependencies
    RUN pnpm install --frozen-lockfile
    
    # Copy the rest of the application code
    COPY . .
    
    # Set environment variable for NX Cloud (again, consider Docker secrets for sensitive data)
    ENV NX_CLOUD_ACCESS_TOKEN=$NX_CLOUD_ACCESS_TOKEN
    
    # Build the application
    RUN pnpm run build
    
    # --- Production Image ---
    FROM node:lts-bullseye-slim AS production
    
    # Set environment variables for pnpm
    ENV PNPM_HOME="/pnpm"
    ENV PATH="$PNPM_HOME:$PATH"
    
    # Install pnpm via corepack
    RUN corepack enable pnpm && corepack prepare pnpm@9.0.6 --activate
    
    # Set the working directory
    WORKDIR /app
    
    # Copy built assets from the build stage
    COPY --from=build /app /app
    
    # Install only production dependencies
    RUN pnpm install --prod --frozen-lockfile
    
    # Expose the port your app runs on
    EXPOSE 3000
    
    # Command to run your application
    CMD ["node", "dist/main.js"] # Adjust the entry point according to your application