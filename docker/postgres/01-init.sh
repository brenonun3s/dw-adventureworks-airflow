#!/bin/bash
set -e
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE "Adventureworks";
    CREATE DATABASE dw_adventureworks;
    CREATE DATABASE airflow;
EOSQL
echo ">> Carregando AdventureWorks (leva 1-3 minutos)..."
cd /data
psql --username "$POSTGRES_USER" -d Adventureworks -q -f install.sql > /dev/null
echo ">> AdventureWorks carregado."
