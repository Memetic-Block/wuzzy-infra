# Update procedure:
# 1. Blame the docker-compose.yml !!on main branch!!
# 2. Apply updates vs last diff
# 3. Carefully run updated jobspec

job "ario-node-wuzzy" {
  datacenters = ["mb-hel"]
  type = "service"

  group "ario-node-wuzzy-group" {
    count = 1
       
    volume "wuzzy-ario-node-redis" {
      type = "host"
      read_only = false
      source = "wuzzy-ario-node-redis"
    } 
    volume "wuzzy-ario-node-core" {
      type = "host"
      read_only = false
      source = "wuzzy-ario-node-core"
    }
    volume "wuzzy-ario-node-observer" {
      type = "host"
      read_only = false
      source = "wuzzy-ario-node-observer"
    }

    network {
      mode = "bridge"
      port "envoy" {
        to = 3000
        host_network = "wireguard"
      }
      port "envoy_admin" {
        static = 9901
        host_network = "wireguard"
      }
      port "core" {
        host_network = "wireguard"
      }
      port "observer" {
        host_network = "wireguard"
      }
      port "resolver" {
        host_network = "wireguard"
      }
      port "redis" {
        host_network = "wireguard"
      }
    }

    task "ario-node-wuzzy-envoy" {
      driver = "docker"
      config {
        image = "ghcr.io/ar-io/ar-io-envoy:r33"
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }

      resources {
        cpu    = 1024
        memory = 1024
      }

      env {
        LOG_LEVEL="info"
        TVAL_AR_IO_HOST="localhost"
        TVAL_AR_IO_PORT="${NOMAD_PORT_core}"
        TVAL_OBSERVER_HOST="localhost"
        TVAL_OBSERVER_PORT="${NOMAD_PORT_observer}"
        TVAL_GATEWAY_HOST="arweave.net"
        # TVAL_GRAPHQL_HOST="localhost"
        # TVAL_GRAPHQL_PORT="${NOMAD_PORT_core}"
        TVAL_GRAPHQL_HOST="arweave.net"
        TVAL_GRAPHQL_PORT="443"
        TVAL_ARNS_ROOT_HOST="gateway.wuzzy.tech"
      }

      service {
        name = "ario-node-wuzzy-envoy"
        port = "envoy"
        
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.wuzzy-ario-node-envoy.entrypoints=https",
          "traefik.http.routers.wuzzy-ario-node-envoy.tls=true",
          "traefik.http.routers.wuzzy-ario-node-envoy.tls.certresolver=wuzzy-tech",
          "traefik.http.routers.wuzzy-ario-node-envoy.tls.domains[0].main=gateway.wuzzy.tech",
		      "traefik.http.routers.wuzzy-ario-node-envoy.tls.domains[0].sans=*.gateway.wuzzy.tech",
          "traefik.http.routers.wuzzy-ario-node-envoy.middlewares=corsheader-wuzzy-ario-node-envoy@consulcatalog",
          "traefik.http.routers.wuzzy-ario-node-envoy.priority=1",
          "traefik.http.routers.wuzzy-ario-node-envoy.rule=HostRegexp(`gateway.wuzzy.tech`, `{subdomain:.*}.gateway.wuzzy.tech`)",
          "traefik.http.middlewares.corsheader-wuzzy-ario-node-envoy.headers.accesscontrolallowmethods=GET,OPTIONS,PUT,POST,DELETE",
          "traefik.http.middlewares.corsheader-wuzzy-ario-node-envoy.headers.accesscontrolallowheaders=content-type",
          "traefik.http.middlewares.corsheader-wuzzy-ario-node-envoy.headers.accesscontrolalloworiginlist=*",
          "traefik.http.middlewares.corsheader-wuzzy-ario-node-envoy.headers.accesscontrolmaxage=42",
          "traefik.http.middlewares.corsheader-wuzzy-ario-node-envoy.headers.addvaryheader=true"
        ]
        check {
          name     = "ario-node-wuzzy-envoy-check"
          type     = "http"
          port     = "envoy"
          path     = "/ar-io/info"
          interval = "10s"
          timeout  = "10s"
          check_restart {
            limit = 30
            grace = "15s"
            ignore_warnings = false
          }
        }
      }
    }

    task "ario-node-wuzzy-core-task" {
      driver = "docker"
      config {
        image = "ghcr.io/ar-io/ar-io-core:r56"
      }
      
      logs {
        max_files     = 5
        max_file_size = 15
      }

      vault { policies = [ "wuzzy-ario-node", "wuzzy-clickhouse" ] }

      template {
        data = <<-EOF
        {{- with secret "kv/wuzzy/ario-node" }}
        ADMIN_API_KEY="{{ .Data.data.ADMIN_API_KEY }}"
        {{- end }}
        {{- with secret "kv/wuzzy/clickhouse" }}
        CLICKHOUSE_PASSWORD="{{ .Data.data.CLICKHOUSE_PASSWORD }}"
        {{- end }}
        EOF
        destination = "secrets/config.env"
        env = true
      }

      template {
        data = <<-EOF
        {{- range service "wuzzy-clickhouse-http" }}
        CLICKHOUSE_URL="http://{{ .Address }}:{{ .Port }}"
        {{- end }}
        EOF
        change_mode = "noop"
        destination = "local/config.env"
        env = true
      }

      env {
        CLICKHOUSE_USER="default"
        ARNS_ROOT_HOST="gateway.wuzzy.tech"
        AR_IO_WALLET="i4PgvaR8hIY5aSojKKy7LRMfdWkYdwt-HpaHaRznZtk"
        PORT="${NOMAD_PORT_core}"
        NODE_ENV="production"
        LOG_LEVEL="info"
        LOG_FORMAT="simple"
        # APEX_ARNS_NAME="wuzzy"
        # TRUSTED_NODE_URL=${TRUSTED_NODE_URL:-}
        TRUSTED_GATEWAY_URL="https://arweave.net"
        # TRUSTED_GATEWAYS_URLS=${TRUSTED_GATEWAYS_URLS:-}
        # TRUSTED_GATEWAYS_REQUEST_TIMEOUT_MS=${TRUSTED_GATEWAYS_REQUEST_TIMEOUT_MS:-}
        START_HEIGHT = "1"
        # STOP_HEIGHT=${STOP_HEIGHT:-}
        # SKIP_CACHE=${SKIP_CACHE:-}
        # SIMULATED_REQUEST_FAILURE_RATE=${SIMULATED_REQUEST_FAILURE_RATE:-}
        # INSTANCE_ID=${INSTANCE_ID:-}
        # ADMIN_API_KEY="... see secrets above"
        # BACKFILL_BUNDLE_RECORDS=${BACKFILL_BUNDLE_RECORDS:-}
        # FILTER_CHANGE_REPROCESS=${FILTER_CHANGE_REPROCESS:-}
        # ANS104_UNBUNDLE_WORKERS=${ANS104_UNBUNDLE_WORKERS:-}
        # ANS104_DOWNLOAD_WORKERS=${ANS104_DOWNLOAD_WORKERS:-}
        ANS104_UNBUNDLE_FILTER = "{\"never\": true}"
        ANS104_INDEX_FILTER = "{ \"always\": true }"
        # DATA_ITEM_FLUSH_COUNT_THRESHOLD=${DATA_ITEM_FLUSH_COUNT_THRESHOLD:-}
        # MAX_FLUSH_INTERVAL_SECONDS=${MAX_FLUSH_INTERVAL_SECONDS:-}
        # SANDBOX_PROTOCOL=${SANDBOX_PROTOCOL:-}
        # START_WRITERS=${START_WRITERS:-}
        # IO_PROCESS_ID=${IO_PROCESS_ID:-}
        CHAIN_CACHE_TYPE="redis"
        REDIS_CACHE_URL="redis://127.0.0.1:${NOMAD_PORT_redis}"
        # REDIS_CACHE_TTL_SECONDS=${REDIS_CACHE_TTL_SECONDS:-}
        # NODE_JS_MAX_OLD_SPACE_SIZE=${NODE_JS_MAX_OLD_SPACE_SIZE:-}
        # ENABLE_FS_HEADER_CACHE_CLEANUP="true"
        # ON_DEMAND_RETRIEVAL_ORDER=${ON_DEMAND_RETRIEVAL_ORDER:-}
        # WEBHOOK_TARGET_SERVERS=${WEBHOOK_TARGET_SERVERS:-}
        # WEBHOOK_INDEX_FILTER=${WEBHOOK_INDEX_FILTER:-}
        # WEBHOOK_BLOCK_FILTER=${WEBHOOK_INDEX_FILTER:-}
        CONTIGUOUS_DATA_CACHE_CLEANUP_THRESHOLD=1209600
        # TRUSTED_ARNS_RESOLVER_URL=""
        TRUSTED_ARNS_GATEWAY_URL="https://__NAME__.arweave.net"
        AR_IO_SDK_LOG_LEVEL="none"
        ARNS_RESOLVER_PRIORITY_ORDER="on-demand,gateway"
        # ARNS_RESOLVER_ENFORCE_UNDERNAME_LIMIT=${ARNS_RESOLVER_ENFORCE_UNDERNAME_LIMIT:-}
        # ARNS_RESOLVER_OVERRIDE_TTL_SECONDS=${ARNS_RESOLVER_OVERRIDE_TTL_SECONDS:-}
        ARNS_CACHE_TTL_SECONDS=3600
        ARNS_CACHE_MAX_KEYS=10000
        ARNS_CACHE_TYPE="redis"
        # ARNS_CACHE_TYPE=${ARNS_CACHE_TYPE:-redis}
        # ARNS_NAMES_CACHE_TTL_SECONDS=${ARNS_NAMES_CACHE_TTL_SECONDS:-}
        ENABLE_MEMPOOL_WATCHER="false"
        # MEMPOOL_POOLING_INTERVAL_MS=${MEMPOOL_POOLING_INTERVAL_MS:-}
        # AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-}
        # AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-}
        # AWS_REGION=${AWS_REGION:-}
        # AWS_ENDPOINT=${AWS_ENDPOINT:-}
        ## AWS_S3_BUCKET=${AWS_S3_BUCKET:-}
        ## AWS_S3_PREFIX=${AWS_S3_PREFIX:-}
        # AWS_S3_CONTIGUOUS_DATA_BUCKET=${AWS_S3_CONTIGUOUS_DATA_BUCKET:-}
        # AWS_S3_CONTIGUOUS_DATA_PREFIX=${AWS_S3_CONTIGUOUS_DATA_PREFIX:-}
        # AR_IO_NODE_RELEASE=25
        # CHUNK_POST_URLS=${CHUNK_POST_URLS:-}
        # CHUNK_POST_MIN_SUCCESS_COUNT=${CHUNK_POST_MIN_SUCCESS_COUNT:-}
        # SECONDARY_CHUNK_POST_CONCURRENCY_LIMIT=${SECONDARY_CHUNK_POST_CONCURRENCY_LIMIT:-}
        # SECONDARY_CHUNK_POST_URLS=${SECONDARY_CHUNK_POST_URLS:-}
        # CHUNK_POST_RESPONSE_TIMEOUT_MS=${CHUNK_POST_RESPONSE_TIMEOUT_MS:-}
        # CHUNK_POST_ABORT_TIMEOUT_MS=${CHUNK_POST_ABORT_TIMEOUT_MS:-}
        GET_DATA_CIRCUIT_BREAKER_TIMEOUT_MS=15000
        AO_CU_URL="https://cu.ardrive.io"
        # AO_MU_URL=${AO_MU_URL:-}
        # AO_GATEWAY_URL=${AO_GATEWAY_URL:-}
        # AO_GRAPHQL_URL=${AO_GRAPHQL_URL:-}
        # WRITE_ANS104_DATA_ITEM_DB_SIGNATURES=${WRITE_ANS104_DATA_ITEM_DB_SIGNATURES:-}
        # WRITE_TRANSACTION_DB_SIGNATURES=${WRITE_TRANSACTION_DB_SIGNATURES:-}
        # ENABLE_DATA_DB_WAL_CLEANUP=${ENABLE_DATA_DB_WAL_CLEANUP:-}
        # MAX_DATA_ITEM_QUEUE_SIZE=${MAX_DATA_ITEM_QUEUE_SIZE:-}
        # TAG_SELECTIVITY=${TAG_SELECTIVITY:-}
        # MAX_EXPECTED_DATA_ITEM_INDEXING_INTERVAL_SECONDS=${MAX_EXPECTED_DATA_ITEM_INDEXING_INTERVAL_SECONDS:-}
        # ENABLE_BACKGROUND_DATA_VERIFICATION=${ENABLE_BACKGROUND_DATA_VERIFICATION:-}
        # BACKGROUND_DATA_VERIFICATION_INTERVAL_SECONDS=${BACKGROUND_DATA_VERIFICATION_INTERVAL_SECONDS:-}
        # CLICKHOUSE_URL=${CLICKHOUSE_URL:-}
        # BUNDLE_DATA_IMPORTER_QUEUE_SIZE=${BUNDLE_DATA_IMPORTER_QUEUE_SIZE:-}
        # FS_CLEANUP_WORKER_BATCH_SIZE=${FS_CLEANUP_WORKER_BATCH_SIZE:-}
        # FS_CLEANUP_WORKER_BATCH_PAUSE_DURATION=${FS_CLEANUP_WORKER_BATCH_PAUSE_DURATION:-}
        # FS_CLEANUP_WORKER_RESTART_PAUSE_DURATION=${FS_CLEANUP_WORKER_RESTART_PAUSE_DURATION:-}
        # BUNDLE_REPAIR_RETRY_INTERVAL_SECONDS=${BUNDLE_REPAIR_RETRY_INTERVAL_SECONDS:-}
        # BUNDLE_REPAIR_RETRY_BATCH_SIZE=${BUNDLE_REPAIR_RETRY_BATCH_SIZE:-}
        # WEIGHTED_PEERS_TEMPERATURE_DELTA=${WEIGHTED_PEERS_TEMPERATURE_DELTA:-}
        ARNS_NAME_LIST_CACHE_MISS_REFRESH_INTERVAL_SECONDS=60
      }

      volume_mount {
        volume = "wuzzy-ario-node-core"
        destination = "/app/data"
        read_only = false
      }

      resources {
        cpu    = 4096
        memory = 10240
      }

      service {
        name = "wuzzy-ario-node-core"
        port = "core"
        check {
          name     = "wuzzy-ario-node-core-check"
          type     = "http"
          path     = "/ar-io/healthcheck"
          interval = "10s"
          timeout  = "10s"
          check_restart {
            limit = 30
            grace = "15s"
            ignore_warnings = false
          }
        }
      }
    }

    task "ario-node-wuzzy-redis" {
      driver = "docker"
      config {
        image = "redis:7.2"
        command = "redis-server"
        args = [
          "--maxmemory-policy allkeys-lru",
          "--appendonly no",
          "--port ${NOMAD_PORT_redis}"
        ]
      }

      volume_mount {
        volume = "wuzzy-ario-node-redis"
        destination = "/data"
        read_only = false
      }

      resources {
        cpu    = 2048
        memory = 4096
      }

      service {
        name = "wuzzy-ario-node-redis"
        port = "redis"
        
        check {
          name     = "wuzzy-ario-node-redis-check"
          type     = "tcp"
          interval = "5s"
          timeout  = "10s"
        }
      }
    }

    task "ario-node-wuzzy-observer-task" {
      driver = "docker"
      config {
        image = "ghcr.io/ar-io/ar-io-observer:7384807c660228579b312474090c47ea9b7727ec"
        volumes = [
          "secrets/observer_key.json:/app/wallets/qgQShO5_T34Usg03tMTfqu9gI4oUe2-Gtz1BQ9bhx2c.json",
        ]
      }
      
      logs {
        max_files     = 5
        max_file_size = 15
      }
        
      vault {
        policies = ["wuzzy-ario-node"]
      }
        
      template {
        data = "{{ with secret `kv/wuzzy/ario-node` }}{{ base64Decode .Data.data.OBSERVER_KEY_BASE64}}{{end}}"
        destination = "secrets/observer_key.json"
      }

      env {
        PORT="${NOMAD_PORT_observer}"
        LOG_LEVEL="info"
        OBSERVER_WALLET="qgQShO5_T34Usg03tMTfqu9gI4oUe2-Gtz1BQ9bhx2c"
        # IO_PROCESS_ID=${IO_PROCESS_ID:-}
        SUBMIT_CONTRACT_INTERACTIONS=true
        NUM_ARNS_NAMES_TO_OBSERVE_PER_GROUP=5
        #- REPORT_GENERATION_INTERVAL_MS=${REPORT_GENERATION_INTERVAL_MS:-}
        RUN_OBSERVER=true
        MIN_RELEASE_NUMBER=0
        # AR_IO_NODE_RELEASE=25
        # AO_CU_URL=${AO_CU_URL:-}
        # AO_MU_URL=${AO_MU_URL:-}
        # AO_GATEWAY_URL=${AO_GATEWAY_URL:-}
        # AO_GRAPHQL_URL=${AO_GRAPHQL_URL:-}
      }

      volume_mount {
        volume = "wuzzy-ario-node-observer"
        destination = "/app/data"
        read_only = false
      }

      resources {
        cpu    = 2048
        memory = 2048
      }

      service {
        name = "wuzzy-ario-node-observer"
        port = "observer"
        
        check {
          name     = "wuzzy-ario-node-observer-check"
          type     = "http"
          path     = "/ar-io/observer/healthcheck"
          interval = "10s"
          timeout  = "10s"
          check_restart {
            limit = 30
            grace = "15s"
            ignore_warnings = false
          }
        }
      }
    }
  }
}
