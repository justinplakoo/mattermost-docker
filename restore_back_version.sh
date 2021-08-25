#!/bin/bash
cd ~/compose/mattermost-docker

docker-compose down

sudo rm -rf /opt/data/containers/mattermost/db/*
sudo cp -ra /mnt/v300g/backups_app/mattermost-backup-2021-05-28-18-00/app /opt/data/containers/mattermost/
sudo cp -ra /mnt/v300g/backups_app/mattermost-backup-2021-05-28-18-00/db/var /opt/data/containers/mattermost/
sudo cp -ra /mnt/v300g/backups_app/mattermost-backup-2021-05-28-18-00/plugins /opt/data/containers/mattermost/
sudo cp -ra /mnt/v300g/backups_app/mattermost-backup-2021-05-24-20-27/mattermost-docker/app/* ~/compose/mattermost-docker/app/
sudo cp -ra /mnt/v300g/backups_app/mattermost-backup-2021-05-24-20-27/mattermost-docker/db/* ~/compose/mattermost-docker/db/
sudo cp -ra /mnt/v300g/backups_app/mattermost-backup-2021-05-24-20-27/mattermost-docker/docker-compose.yml ~/compose/mattermost-docker/

docker-compose build
docker-compose up -d
