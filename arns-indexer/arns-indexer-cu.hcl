job "arns-indexer-cu" {
  datacenters = ["mb-hel"]
  type = "service"

  group "arns-indexer-cu-group" {
    count = 1

    volume "arns-indexer-cu" {
      type = "host"
      read_only = false
      source = "arns-indexer-cu"
    }

    network {
      mode = "bridge"
      port "http" { host_network = "wireguard" }
    }

    service {
      name = "arns-indexer-cu"
      port = "http"
      check {
        name     = "arns-indexer-cu-check"
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "10s"
        address_mode = "alloc"
        check_restart {
          limit = 30
          grace = "15s"
          ignore_warnings = false
        }
      }
    }

    task "arns-indexer-cu-task" {
      driver = "docker"
      config {
        image = "ghcr.io/permaweb/ao-cu:d959e784fbf499bc8811063036b1407fc957c2e4"
        volumes = [ "secrets/cu-wallet.json:/usr/app/cu-wallet.json" ]
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }

      volume_mount {
        volume = "arns-indexer-cu"
        destination = "/usr/app/tmp"
        read_only = false
      }

      resources {
        cpu    = 4096
        memory = 16384
      }

      env {
        WALLET_FILE = "/usr/app/cu-wallet.json"
        PORT = "${NOMAD_PORT_http}"
        NODE_CONFIG_ENV = "development"
        NODE_HEAPDUMP_OPTIONS = "nosignal"
        DEBUG = "*"
        GRAPHQL_URL = "https://arweave.net/graphql"
        CHECKPOINT_GRAPHQL_URL = "https://arweave.net/graphql"
        ENABLE_METRICS_ENDPOINT = "true"
        PROCESS_WASM_MEMORY_MAX_LIMIT = 17179869184
        DB_URL = "/usr/app/tmp/db/ao-cu-db"
        WASM_BINARY_FILE_DIRECTORY = "/usr/app/tmp/wasm"
        PROCESS_MEMORY_CACHE_FILE_DIR = "/usr/app/tmp/state"
        PROCESS_MEMORY_FILE_CHECKPOINTS_DIR = "/usr/app/tmp/checkpoints"
        CHECKPONT_VALIDATION_THRESH = 1 # NB: misspelled in source code; do not fix
        CHECKPONT_VALIDATION_STEPS = 0 # NB: misspelled in source code; do not fix
        CHECKPONT_VALIDATION_RETRIES = 1 # NB: misspelled in source code; do not fix
        PROCESS_MEMORY_CACHE_MAX_SIZE = 4294967296 # 4GB in bytes
        PROCESS_MEMORY_CACHE_TTL = 172800000 # 48h in ms
        PROCESS_MEMORY_CACHE_CHECKPOINT_INTERVAL = 3600000 # 1h in ms
        DISABLE_PROCESS_FILE_CHECKPOINT_CREATION = "false"
        EAGER_CHECKPOINT_EVAL_TIME_THRESHOLD = 5000 # 5s in ms
        # ALLOW_OWNERS=""
      }

      vault { policies = [ "wuzzy-arns-indexer-cu" ] }

      template {
        data = <<-EOF
        {{- with secret `kv/wuzzy/arns-indexer-cu` }}
        PROCESS_CHECKPOINT_TRUSTED_OWNERS="fcoN_xJeisVsPXA-trzVAuIiqO3ydLQxM-L4XbrQKzY,{{ .Data.data.CU_WALLET_ADDRESS }}"
        {{- end }}
        EOF
        destination = "secrets/config.env"
        env = true
      }

      template {
        data = "{{ with secret `kv/wuzzy/arns-indexer-cu` }}{{ base64Decode .Data.data.CU_WALLET_JWK_BASE64 }}{{ end }}"
        destination = "secrets/cu-wallet.json"
      }
    }
  }
}
