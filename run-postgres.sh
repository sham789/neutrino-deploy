#!/bin/bash

docker run -d \
    --name postgres \
    -p 5432:5432 \
    -e POSTGRES_DB=neutrino_mainnet \
    -e POSTGRES_USER=main \
    -e POSTGRES_PASSWORD=123123123 \
    -e POSTGRES_HOST_AUTH_METHOD=trust \
    -e PGDATA=/var/lib/postgresql/data/pgdata \
    --network neutrino \
    -v /custom/mount:/var/lib/postgresql/data \
    postgres
