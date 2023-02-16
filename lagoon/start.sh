#!/bin/sh

cd /app

echo "BRYAN: LAGOON_ENVIRONMENT_TYPE=${LAGOON_ENVIRONMENT_TYPE:-local}"

node packages/backend --config app-config-${LAGOON_ENVIRONMENT_TYPE:-local}.yml
