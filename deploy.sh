#!/bin/bash

network_gateway='172.19.0.1'
network_subnet='172.19.0.0/16'

network_name='neutrino'

grep_cont_ip() {
	docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $1
}

clean_up () {
	docker ps -a | grep riotpurpp | awk '{ print $1 }' | xargs docker stop | xargs docker rm
	docker ps -a | grep postgres | awk '{ print $1 }' | xargs docker stop | xargs docker rm
	docker ps -a | grep neutrino-redis | awk '{ print $1 }' | xargs docker stop | xargs docker rm
}

while [ -n "$1" ]
    do
        case "$1" in
            --clean) clean_up; exit 0; ;;
        esac
        shift
    done

docker pull riotpurpp/neutrino-web:beta
docker pull riotpurpp/neutrino-cache-updater:master
docker pull riotpurpp/neutrino-explorer:master

docker network create --subnet "$network_subnet" --gateway "$network_gateway" "$network_name"

explorer_id=$(docker run -itd -p 8001:8001 --network neutrino --env-file explorer-env riotpurpp/neutrino-explorer:master)

postgres_id=$(./run-postgres.sh)

postgres_ip=$(grep_cont_ip "$postgres_id")

cache_updater_id=$(docker run -itd -e "DB_HOST=$postgres_ip" --network neutrino --env-file cache-updater-env riotpurpp/neutrino-cache-updater:master)

redis_id=$(docker run -itd --network neutrino -p 6379:6379 --name neutrino-redis redis redis-server --appendonly yes)

redis_ip=$(grep_cont_ip "$redis_id")

# REDIS_URL=redis://mypass@172.105.72.70:6379
# POSTGRES_CONNECTION_URL=postgresql://postgres:123123123@localhost:5432/neutrino_mainnet
# EXPLORER_ENDPOINT=http://127.0.0.1:8001

explorer_ip=$(grep_cont_ip "$explorer_id")
explorer_url="http://$explorer_ip:8001"

postgres_connection_url="postgresql://postgres:123123123@$postgres_ip:5432/neutrino_mainnet"

web_id=$(
	docker run -itd --network neutrino -p 8002:5000 --env-file web-env \
		-e "EXPLORER_ENDPOINT=$explorer_url" \
		-e "REDIS_HOST=$redis_ip" \
		-e "POSTGRES_CONNECTION_URL=$postgres_connection_url" riotpurpp/neutrino-web:beta)
