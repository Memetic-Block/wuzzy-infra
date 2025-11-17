#!/bin/sh
set -e

echo "Setting up crawler configuration..."

# Replace password in config if ELASTIC_PASSWORD is set
if [ -n "$ELASTIC_PASSWORD" ]; then
  sed "s/password: changeme/password: $ELASTIC_PASSWORD/" /config/crawler-base-config.yml > /tmp/crawler.yml
else
  cp /config/crawler-base-config.yml /tmp/crawler.yml
fi

# Move to working directory
cp /tmp/crawler.yml crawler.yml

echo "Starting crawler..."
echo "Configuration:"
cat crawler.yml

# Run the crawler
jruby -J-Xmx16384M bin/crawler crawl crawler.yml
