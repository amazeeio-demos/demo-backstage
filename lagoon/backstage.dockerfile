###############################################
#  Stage 1 - Create yarn install skeleton layer
###############################################
FROM node:16-bullseye-slim AS packages

WORKDIR /app

COPY package.json yarn.lock ./

COPY packages packages

# Comment this out if you don't have any internal plugins
COPY plugins plugins

# Comment this out if you don't want the examples
COPY examples examples

RUN find packages \! -name "package.json" -mindepth 2 -maxdepth 2 -exec rm -rf {} \+


###############################################
# Stage 2 - Install dependencies and build packages
###############################################
FROM node:16-bullseye-slim AS build

USER node
WORKDIR /app

COPY --from=packages --chown=node:node /app .

# Stop cypress from downloading it's massive binary.
ENV CYPRESS_INSTALL_BINARY=0
RUN --mount=type=cache,target=/home/node/.cache/yarn,sharing=locked,uid=1000,gid=1000 \
    yarn install --frozen-lockfile --network-timeout 600000

COPY --chown=node:node . .

RUN yarn tsc
RUN yarn --cwd packages/backend build

RUN mkdir packages/backend/dist/skeleton packages/backend/dist/bundle \
    && tar xzf packages/backend/dist/skeleton.tar.gz -C packages/backend/dist/skeleton \
    && tar xzf packages/backend/dist/bundle.tar.gz -C packages/backend/dist/bundle


###############################################
# Stage 3 - Build the actual backend image and install production dependencies
###############################################
FROM node:16-bullseye-slim AS image

# From here on we use the least-privileged `node` user to run the backend.
USER node

# This should create the app dir as `node`.
# If it is instead created as `root` then the `tar` command below will fail: `can't create directory 'packages/': Permission denied`.
# If this occurs, then ensure BuildKit is enabled (`DOCKER_BUILDKIT=1`) so the app dir is correctly created as `node`.
WORKDIR /app

# Copy the install dependencies from the build stage and context
COPY --from=build --chown=node:node /app/yarn.lock /app/package.json /app/packages/backend/dist/skeleton/ ./

RUN --mount=type=cache,target=/home/node/.cache/yarn,sharing=locked,uid=1000,gid=1000 \
    yarn install --frozen-lockfile --production --network-timeout 600000

# Copy the built packages from the build stage
COPY --from=build --chown=node:node /app/packages/backend/dist/bundle/ ./

# Copy any other files that we need at runtime
COPY --chown=node:node app-config*.yaml ./

# Comment this out if you don't want the examples
COPY --from=build /app/examples /app/examples

################################
# Switch to a Lagoon base image
################################
FROM uselagoon/node-16
COPY --from=image /app /app
RUN fix-permissions /app

# Lagoon specifi entrypoint - remove if we don't need it
COPY lagoon/backstage-entrypoint.sh /lagoon/entrypoints/backstage-n8n-entrypoint
COPY lagoon/start.sh /app/lagoon/start.sh

# This switches many Node.js dependencies to production mode.
ENV NODE_ENV production

# CMD ["node", "packages/backend", "--config", "app-config.yaml"]
CMD ["/app/lagoon/start.sh"]
