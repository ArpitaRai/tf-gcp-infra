#!/bin/bash
echo "================================================================="
echo "Run the application"
echo "================================================================="

sudo systemctl daemon-reload
sudo systemctl enable webapp.service
sudo systemctl start webapp.service