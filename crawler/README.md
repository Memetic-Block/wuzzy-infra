# Wuzzy Crawler - Local Development Setup

This is a local development environment for the Wuzzy web crawler using Elasticsearch and Kibana.

## Prerequisites

- Docker and Docker Compose installed
- At least 16GB of RAM available for the crawler

## Setup

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. (Optional) Modify `.env` to change default ports or Elasticsearch password

## Usage

### Start Elasticsearch and Kibana

```bash
docker-compose up -d elasticsearch kibana
```

Wait for both services to be healthy (check with `docker-compose ps`).

### Run the Crawler

The crawler runs as a one-time job and exits when complete:

```bash
docker-compose run --rm crawler
```

### View Crawled Data in Kibana

1. Open Kibana in your browser: http://localhost:5600
2. Navigate to **Management** → **Stack Management** → **Index Patterns**
3. Create an index pattern for `permaweb-crawler-local*`
4. Navigate to **Analytics** → **Discover** to explore the crawled data

### Check Elasticsearch Data Directly

```bash
# View all indices
curl http://localhost:9201/_cat/indices?v

# Search crawled documents
curl http://localhost:9201/permaweb-crawler-local/_search?pretty
```

### Export Data to Local OpenSearch (elasticsearch-dump)

The `elasticsearch-dump` service transfers data from the local Elasticsearch to the local OpenSearch cluster (running in `../opensearch/`). This is a two-phase process:

**1. Export Mapping (run first):**

```bash
# Run the mapping export
DUMP_TYPE=mapping docker-compose run --rm elasticsearch-dump
```

**2. Export Data (run after mapping):**

```bash
# Run the data export
DUMP_TYPE=data docker-compose run --rm elasticsearch-dump
```

**Verify in OpenSearch Dashboards:**
- OpenSearch Dashboards: http://localhost:5601 (from opensearch docker-compose)
- Create index pattern for `permaweb-crawler-local*`

The elasticsearch-dump service connects to OpenSearch via `host.docker.internal:9200` by default. No authentication is required since the local OpenSearch has security disabled.

## Services

- **Elasticsearch**: http://localhost:9201
  - Index: `permaweb-crawler-local`
  - No authentication required (security disabled for local dev)
  
- **Kibana**: http://localhost:5600
  - Connected to local Elasticsearch instance

## Crawled Domains

The crawler is configured to crawl the following domains:
- https://cookbook.arweave.net
- https://cookbook_ao.arweave.net
- https://memeticblock.arweave.net

To modify the domain list, edit `config/crawler-base-config.yml`.

## Stopping Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (clears all data)
docker-compose down -v
```

## Troubleshooting

### Crawler fails to start
- Ensure Elasticsearch is healthy: `docker-compose ps`
- Check Elasticsearch logs: `docker-compose logs elasticsearch`

### Out of memory errors
- Increase Docker's memory limit to at least 18GB (16GB for crawler + overhead)
- Or reduce the crawler's heap size in `docker-compose-entrypoint.sh` (change `-J-Xmx16384M`)

### Can't connect to Kibana
- Wait for Kibana to fully start (can take 1-2 minutes)
- Check Kibana logs: `docker-compose logs kibana`

## Data Persistence

Elasticsearch data is stored in a Docker volume named `crawler_esdata`. This persists across container restarts. To start fresh, remove the volume:

```bash
docker-compose down -v
```
