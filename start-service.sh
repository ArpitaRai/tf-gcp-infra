#!/bin/bash


echo "================================================================="
echo "Creating user and changing directory ownership"
echo "================================================================="
sudo adduser csye6225 --shell /usr/sbin/nologin || { echo "Failed to add csye6225 user. Exiting."; exit 1; }
sudo chown -R csye6225:csye6225 /opt/csye6225dir || { echo "Failed to change directory permissions. Exiting."; exit 1; }
sudo chmod -R 744 /opt/csye6225dir || { echo "Failed to change directory permissions. Exiting."; exit 1; }

echo "================================================================="
echo "Run the application"
echo "================================================================="

sudo systemctl daemon-reload
sudo systemctl enable webapp.service
sudo systemctl start webapp.service
