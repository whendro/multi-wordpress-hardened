#!/usr/bin/env bash
# Usage: ./new-site.sh site2
# Creates /srv/wordpress/site2 from _template

set -euo pipefail

SITES_ROOT="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$SITES_ROOT/_template"
SITE_ID="${1:-}"

if [[ -z "$SITE_ID" ]]; then
    echo "Usage: $0 <site-name>"
    echo "Example: $0 site2"
    exit 1
fi

SITE_DIR="$SITES_ROOT/$SITE_ID"

if [[ -d "$SITE_DIR" ]]; then
    echo "ERROR: $SITE_DIR already exists"
    exit 1
fi

# Create site directory with logs
mkdir -p "$SITE_DIR/logs/nginx" "$SITE_DIR/logs/php"

# Copy compose file only — php/nginx configs are read from _template directly
cp "$TEMPLATE/docker-compose.yml" "$SITE_DIR/docker-compose.yml"
cp "$TEMPLATE/.env.example"       "$SITE_DIR/.env.example"

# Pre-fill SITE_NAME in env example
sed -i "s/wp-site1/wp-$SITE_ID/g" "$SITE_DIR/.env.example"

echo ""
echo "✓ Site scaffolded: $SITE_DIR"
echo ""
echo "Next steps:"
echo "  1. cd $SITE_DIR"
echo "  2. cp .env.example .env"
echo "  3. Edit .env — fill DB_NAME, DB_USER, DB_PASSWORD, REDIS_PREFIX, REDIS_DB"
echo "  4. Create the DB user in MariaDB:"
echo "       CREATE DATABASE wp_$SITE_ID;"
echo "       CREATE USER 'wp_${SITE_ID}_user'@'%' IDENTIFIED BY 'yourpassword';"
echo "       GRANT ALL ON wp_$SITE_ID.* TO 'wp_${SITE_ID}_user'@'%';"
echo "       FLUSH PRIVILEGES;"
echo "  5. docker compose up -d"
echo "  6. In NPM: add proxy host → yourdomain.com → http://wp-$SITE_ID-nginx:80"
echo ""
