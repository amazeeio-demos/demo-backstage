# [Backstage](https://backstage.io)

This is your newly scaffolded Backstage App, Good Luck!

To start the app, run:

```sh
yarn install
yarn dev
```

---

To run in Docker locally (for Lagoon style work)

- touch .env.local (and pop and variables you'd like in there for local development)

```sh
export DOCKER_BUILDKIT=1 # or configure in daemon.json
export COMPOSE_DOCKER_CLI_BUILD=1
docker-compose up
```

