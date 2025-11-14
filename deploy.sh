#!/bin/bash
# Deployment script for the server
# This script should be run on your HK server

set -e

# Configuration
DEPLOY_DIR="/var/www/mkdocs-notes"
BACKUP_DIR="/var/www/mkdocs-notes-backup"

echo "Starting deployment..."

# Create backup of current site
if [ -d "$DEPLOY_DIR" ]; then
    echo "Creating backup..."
    rm -rf "$BACKUP_DIR"
    cp -r "$DEPLOY_DIR" "$BACKUP_DIR"
fi

# Create deploy directory if it doesn't exist
mkdir -p "$DEPLOY_DIR"

echo "Deployment directory ready at: $DEPLOY_DIR"

# If using Docker
if command -v docker &> /dev/null; then
    echo "Docker detected. You can use docker-compose to deploy."
    echo "Run: docker-compose up -d"
fi

# If using nginx to serve static files
if command -v nginx &> /dev/null; then
    echo "Nginx detected."
    echo "Make sure your nginx config points to: $DEPLOY_DIR"
    echo "After rsync deployment, reload nginx: sudo systemctl reload nginx"
fi

echo "Deployment setup complete!"
