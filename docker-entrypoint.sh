#!/bin/bash

#
# Section: Docker-in-Docker
#

# +e = prevents exit immediately if a command exits with a non-zero status (like StrictHostKeyChecking without a key...).

set +e

export SQREEN_DISABLE_STARTUP_WARNING=1

# seems to fail...
sysctl net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.forwarding=1

export DOCKER_HOST="tcp://docker:2375"
export DOCKER_HOST="unix:///var/run/docker.sock"

# exec "$@"

source ~/.profile

pwd

if [[ -f ./.thinx_env ]]; then
  echo "Sourcing .thinx_env"
  source ./.thinx_env
else
  echo ".thinx_env not found, expects ENVIRONMENT, ROLLBAR_ACCESS_TOKEN, ROLLBAR_ENVIRONMENT and REVISION variables to be set."
fi

# Installs all tools, not just those currently allowed by .dockerignore, requires running Docker
if [[ ! -z $(which docker) ]]; then
  echo "Installing Build-tools for DinD/DooD"
  pushd builders
  bash ./install-builders.sh
  popd
else
  echo "Skipping build-tools installation, Docker not available."
fi

echo "Adding host checking exception for github.com..."
ssh -o "StrictHostKeyChecking=no" git@github.com

echo "Deploying with Rollbar..."
if [[ ! -z $ROLLBAR_ACCESS_TOKEN ]]; then
  LOCAL_USERNAME=$(whoami)
  curl https://api.rollbar.com/api/1/deploy/ \
    -F access_token=$ROLLBAR_ACCESS_TOKEN \
    -F environment=$ROLLBAR_ENVIRONMENT \
    -F revision=$REVISION \
    -F local_username=$LOCAL_USERNAME
else
  echo "Skipping Rollbar deployment, access token not defined..."
fi

set -e

# workaround for log aggregator until solved using event database
mkdir -p /opt/thinx/.pm2/logs/
touch /opt/thinx/.pm2/logs/index-out-1.log

echo "/mnt/data/conf contents:"
ls -lf /mnt/data/conf

echo "/opt/thinx/thinx-device-api/conf contents:"
ls -lf /opt/thinx/thinx-device-api/conf

if [ $ENVIRONMENT == "test" ]; then
  echo "Running in TEST MODE!"
  npm test | tee -ipa /opt/thinx/.pm2/logs/index-out-1.log
  cp -vf ./lcov.info /mnt/data/test-reports/lcov.info
  cp -vfR ./.nyc_output /mnt/data/test-reports/.nyc_output
else
  echo "Running in production mode..."
  node thinx.js | tee -ipa /opt/thinx/.pm2/logs/index-out-1.log
fi
