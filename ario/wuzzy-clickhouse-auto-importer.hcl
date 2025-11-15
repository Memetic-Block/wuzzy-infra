job "wuzzy-clickhouse-auto-importer" {
  datacenters = ["mb-hel"]
  type        = "service"
  group "clickhouse-auto-importer" {
    count = 1
    volume "wuzzy-ario-node-core" {
      type = "host"
      read_only = false
      source = "wuzzy-ario-node-core"
    }
    task "clickhouse-auto-import" {
      driver = "docker"
      config {
        image = "ghcr.io/ar-io/ar-io-clickhouse-auto-import:4512361f3d6bdc0d8a44dd83eb796fd88804a384"
        entrypoint = [ "/bin/bash", "/entrypoint.sh" ]
        volumes = [
          "local/debug-entrypoint.sh:/entrypoint.sh:ro"
        ]
      }
      volume_mount {
        volume = "wuzzy-ario-node-core"
        destination = "/app/data"
        read_only = false
      }
      env {
        CLICKHOUSE_USER = "default"
        CLICKHOUSE_HOST = "${NOMAD_IP_native}"
        PARQUET_DATA_PATH = "/app/data/parquet"
        DATASETS_PATH = "/app/data/datasets"
        ETL_STAGING_PATH = "/app/data/etl/staging"
      }
      template {
        data = <<-EOF
        #!/usr/bin/env bash
        ar_io_host=$AR_IO_HOST
        ar_io_port=$AR_IO_PORT
        echo "Starting ClickHouse Auto Importer Debug Endpoint Connector to ArIO at $ar_io_host:$ar_io_port"
        curl http://$ar_io_host:$ar_io_port/ar-io/info
        echo "\nTrying to connect to debug endpoint...\n"
        curl -H "Authorization: Bearer $ADMIN_API_KEY" http://$ar_io_host:$ar_io_port/ar-io/admin/debug
        EOF
        destination = "local/debug-entrypoint.sh"
      }
      template {
        data = <<-EOF
        {{- range service "wuzzy-ario-node-core" }}
        AR_IO_HOST="{{ .Address }}"
        AR_IO_PORT="{{ .Port }}"
        {{- end }}
        EOF
        env = true
        destination = "local/config.env"
      }
      vault { policies = [ "wuzzy-clickhouse", "wuzzy-ario-node" ] }
      template {
        data = <<-EOF
        {{- with secret "kv/wuzzy/clickhouse" }}
        CLICKHOUSE_PASSWORD="{{ .Data.data.CLICKHOUSE_PASSWORD }}"
        {{- end }}
        {{- with secret "kv/wuzzy/ario-node" }}
        ADMIN_API_KEY="{{ .Data.data.ADMIN_API_KEY }}"
        {{- end }}
        EOF
        env = true
        destination = "secrets/config.env"
      }
      resources {
        cpu    = 1024
        memory = 1024
      }
    }
  }
}
