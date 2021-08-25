#!/bin/bash

# Credit for helping to outline the correct upgrade process goes to @tuxity and @GuidoDr

##
## Instructions
##

# 1. Edit the variables below to match your environment. This uses default variables and assumes you're on 5.31.0.
#    If you're wanting to use another version of Postgres/Mattermost , update the variables as desired.

# 2. Copy the contents of this script into a file within your mattermost-docker folder. This is essential. 
#    You can use 'sudo touch upgrade.sh && sudo nano upgrade.sh' then paste the script.

# 3. run 'sudo bash upgrade.sh' replace upgrade.sh with what you've named the file.
#    This may take some time to complete as it's migrating the database to Postgres 13.6 from 9.4


##
## Environment Variables
##

# Below is default values in the mattermost-docker container. If you've edited these you will need
# to modify them before running the script or this will generate a new databse.
POSTGRES_USER="mmuser"
POSTGRES_PASSWORD="mmuser_password"
POSTGRES_DB="mattermost"

# You should be on Postgres 9.4. To get your version run
# 'sudo cat volumes/db/var/lib/postgresql/data/PG_VERSION' to confirm this.
POSTGRES_OLD_VERSION=9.4
POSTGRES_NEW_VERSION=13

# This tag is found here - https://hub.docker.com/_/postgres'
# This tag needs to be an apline release to include python3-dev
POSTGRES_DOCKER_TAG='13.2-alpine'
POSTGRES_OLD_DOCKERFILE=`sudo cat ./db/Dockerfile | grep 'FROM postgres'`
POSTGRES_NEW_DOCKERFILE='FROM postgres:'$POSTGRES_DOCKER_TAG


# This is found here - https://github.com/tianon/docker-postgres-upgrade
# The string here needs to match a folder on that repo. It should read 'old-to-new'.
UPGRADE_LINE='9.4-to-13'

# Mattermost Versions
CURRENT_MM_VERSION="5.31.0"
NEW_MM_VERSION="5.32.1"

##
## Script Start
##

docker-compose stop

sleep 5

# Creating a backup folder and backing up the mattermost / database.
# mkdir /opt/data/containers/backups
# cp -ra /opt/data/containers/mattermost/ /mnt/v300g/backups_app/mattermost-backup-$(date +'%F-%H-%M')/
# cp -ra /opt/data/containers/mattermost/db/ backups/database-backup-$(date +'%F-%H-%M')/

mkdir /opt/data/containers/mattermost/db/$POSTGRES_OLD_VERSION
chmod 755 /opt/data/containers/mattermost/db/$POSTGRES_OLD_VERSION
cp -rpa /opt/data/containers/mattermost/db/var/lib/postgresql/data /opt/data/containers/mattermost/db/$POSTGRES_OLD_VERSION/
rm -rf /opt/data/containers/mattermost/db/var
mkdir -p /opt/data/containers/mattermost/db/$POSTGRES_NEW_VERSION/data
chmod 755 -R /opt/data/containers/mattermost/db/$POSTGRES_NEW_VERSION/data

sed -i "s/$POSTGRES_OLD_DOCKERFILE/$POSTGRES_NEW_DOCKERFILE/" ./db/Dockerfile
# sed -i "s#/var/lib/postgresql/data#/var/lib/postgresql/$POSTGRES_NEW_VERSION/data#" ./db/Dockerfile
sed -i "s/python-dev/python3-dev/" ./db/Dockerfile
sed -i "s/$CURRENT_MM_VERSION/$NEW_MM_VERSION/" ./app/Dockerfile


# replacing the old postgres path with a new path
sed -i "s#/opt/data/containers/mattermost/db/var/lib/postgresql/data:/var/lib/postgresql/data#/opt/data/containers/mattermost/db/$POSTGRES_NEW_VERSION/data:/var/lib/postgresql/data#" ./docker-compose.yml

# migrate the database to the new postgres version
docker run --rm \
    -e PGUSER="$POSTGRES_USER" \
    -e POSTGRES_INITDB_ARGS=" -U $POSTGRES_USER" \
    -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    -e POSTGRES_DB="$POSTGRES_DB" \
    -v /opt/data/containers/mattermost/db:/var/lib/postgresql \
    tianon/postgres-upgrade:$UPGRADE_LINE \
    --link

cp -p /opt/data/containers/mattermost/db/$POSTGRES_OLD_VERSION/data/pg_hba.conf /opt/data/containers/mattermost/db/$POSTGRES_NEW_VERSION/data/

# rebuild the containers
docker-compose build
docker-compose up -d

sleep 5
# reindex the database
echo "REINDEX SCHEMA CONCURRENTLY public;" | docker exec mattermostdocker_db_1 psql -U $POSTGRES_USER $POSTGRES_DB
