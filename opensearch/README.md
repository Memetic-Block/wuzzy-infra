# OpenSearch - Local Development Setup

This is a local development environment for OpenSearch with OpenSearch Dashboards.

## Prerequisites

- Docker and Docker Compose installed
- At least 4GB of RAM available for the cluster

## Setup

The setup runs a 2-node OpenSearch cluster with security disabled for local development.

### Start OpenSearch Cluster

```bash
docker-compose up -d
```

This will start:
- `opensearch-node1` - Primary node (ports 9200, 9600)
- `opensearch-node2` - Secondary node
- `opensearch-dashboards` - Web UI (port 5601)

### Initialize UBI Plugin

After the cluster is running, initialize the User Behavior Insights (UBI) plugin:

```bash
# Wait for OpenSearch to be ready
sleep 10

# Initialize the UBI plugin
curl -X POST "http://localhost:9200/_plugins/ubi/initialize"
```

## Services

- **OpenSearch REST API**: http://localhost:9200
  - No authentication required (security disabled for local dev)
  - Performance Analyzer: http://localhost:9200/_plugins/_performanceanalyzer/metrics
  
- **OpenSearch Dashboards**: http://localhost:5601
  - Web interface for querying and visualizing data
  - Create index patterns to explore your data

## Common Operations

### Check Cluster Health

```bash
curl http://localhost:9200/_cluster/health?pretty
```

### List All Indices

```bash
curl http://localhost:9200/_cat/indices?v
```

### Search an Index

```bash
curl http://localhost:9200/<index-name>/_search?pretty
```

### Create Index Pattern in Dashboards

1. Open OpenSearch Dashboards: http://localhost:5601
2. Navigate to **Management** → **Stack Management** → **Index Patterns**
3. Click **Create index pattern**
4. Enter your index pattern (e.g., `permaweb-crawler-local*`)
5. Select a time field or choose "I don't want to use a time field"
6. Click **Create index pattern**
7. Navigate to **Discover** to explore your data

## Stopping Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (clears all data)
docker-compose down -v
```

## Data Persistence

OpenSearch data is stored in Docker volumes:
- `opensearch-data1` - Data for node 1
- `opensearch-data2` - Data for node 2

These volumes persist across container restarts. To start with a clean slate:

```bash
docker-compose down -v
```

## Troubleshooting

### Services fail to start

Check if you have enough memory allocated to Docker (at least 4GB recommended).

### Cluster status is yellow or red

```bash
# Check cluster health
curl http://localhost:9200/_cluster/health?pretty

# Check node status
curl http://localhost:9200/_cat/nodes?v
```

Yellow status is normal for a 2-node cluster with indices that have replicas.

### Can't connect to OpenSearch

- Wait 30-60 seconds after starting for the cluster to initialize
- Check logs: `docker-compose logs opensearch-node1`

### OpenSearch Dashboards shows "OpenSearch Dashboards server is not ready yet"

- Wait for OpenSearch cluster to be fully started
- Check dashboards logs: `docker-compose logs opensearch-dashboards`

## Configuration

The cluster is configured with:
- **Cluster name**: `opensearch-cluster`
- **Security**: Disabled (`DISABLE_SECURITY_PLUGIN=true`)
- **Demo config**: Disabled (`DISABLE_INSTALL_DEMO_CONFIG=true`)
- **JVM Heap**: 512MB min/max per node
- **Memory lock**: Enabled (prevents swapping)

## Integration with Crawler

This OpenSearch cluster is designed to work with the crawler setup in `../crawler/`. See the crawler README for instructions on transferring data from Elasticsearch to OpenSearch using elasticsearch-dump.
