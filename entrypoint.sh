#!/bin/sh

# check if required paramethers provided
if [ -z "$INPUT_SSH_KEY" ]; then
  echo "Input ssh_key is required!"
  exit 1
fi

if [ -z "$INPUT_SSH_USER" ]; then
  echo "Input ssh_user is required!"
  exit 1
fi

if [ -z "$INPUT_SSH_HOST" ]; then
  echo "Input ssh_host is required!"
  exit 1
fi

# set correct values to paramethers
if [ "$INPUT_BUILD" == 'true' ]; then
  INPUT_BUILD='--build'
else
  INPUT_BUILD=''
fi

if [ "$INPUT_FORCE_RECREATE" == 'true' ]; then
  INPUT_FORCE_RECREATE='--force-recreate'
else
  INPUT_FORCE_RECREATE=''
fi

# set INPUT_COMPOSE_FILE variable if not provided
if [ -z "$INPUT_COMPOSE_FILE" ]; then
  INPUT_COMPOSE_FILE='docker-compose.yml'
fi

# set INPUT_SSH_PORT variable if not provided
if [ -z "$INPUT_SSH_PORT" ]; then
  INPUT_SSH_PORT=22
fi

# create private key and add it to authentication agent
mkdir -p $HOME/.ssh
printf '%s\n' "$INPUT_SSH_KEY" > "$HOME/.ssh/private_key"
chmod 600 "$HOME/.ssh/private_key"
eval $(ssh-agent)
ssh-add "$HOME/.ssh/private_key"

docker login -u $INPUT_DO_TOKEN -p $INPUT_DO_TOKEN registry.digitalocean.com

# create remote context in docker and switch to it
docker context create remote --docker "host=ssh://$INPUT_SSH_USER@$INPUT_SSH_HOST:$INPUT_SSH_PORT"
docker context use remote

# pull latest images if paramether provided
if [ "$INPUT_PULL" == 'true' ]; then
  docker compose -f $INPUT_COMPOSE_FILE pull
fi

# deploy stack
docker compose -f $INPUT_COMPOSE_FILE up

# cleanup context
docker context use default 
docker context rm remote
