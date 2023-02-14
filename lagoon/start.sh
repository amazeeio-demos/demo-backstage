#!/bin/sh

cd /app

node packages/backend --config app-config-${LAGOON_ENVIRONMENT_TYPE:-local}.yaml
