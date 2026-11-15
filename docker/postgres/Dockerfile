FROM postgres:16

RUN apt-get update \
 && apt-get install -y --no-install-recommends unzip ruby dos2unix curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /data
COPY install.sql update_csvs.rb /data/
RUN curl -sSL -o aw.zip https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks-oltp-install-script.zip \
 && unzip -q aw.zip && rm aw.zip \
 && ruby update_csvs.rb && rm update_csvs.rb \
 && chmod -R a+r /data

COPY 01-init.sh /docker-entrypoint-initdb.d/
RUN dos2unix /docker-entrypoint-initdb.d/*.sh
