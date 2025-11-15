job "wuzzy-orchestrator-postgres-live" {
  datacenters = [ "mb-hel" ]
  type = "service"

  group "wuzzy-orchestrator-postgres-live-group" {
    count = 1

    network {
      mode = "bridge"
      port "postgres" {
        host_network = "wireguard"
      }
    }

    volume "wuzzy-orchestrator-postgres-live" {
      type      = "host"
      read_only = false
      source    = "wuzzy-orchestrator-postgres-live"
    }

    task "wuzzy-orchestrator-postgres-live-task" {
      driver = "docker"

      config {
        image = "postgres:18"
        args = [ "-c", "listen_addresses=*" ]
      }

      volume_mount {
        volume = "wuzzy-orchestrator-postgres-live"
        destination = "/var/lib/postgresql/18/docker"
        read_only = false
      }

      env {
        POSTGRES_DB = "wuzzy-orchestrator-live"
        PGPORT      = "${NOMAD_PORT_postgres}"
      }

      vault { policies = [ "wuzzy-orchestrator-live" ] }

      template {
        data = <<-EOF
        {{- with secret "kv/wuzzy/orchestrator-live" }}
        POSTGRES_USER     = "{{ .Data.data.DB_USER }}"
        POSTGRES_PASSWORD = "{{ .Data.data.DB_PASSWORD }}"
        {{- end }}
        EOF
        destination = "secrets/config.env"
        env = true
      }

      resources {
        cpu    = 4096
        memory = 4096
      }

      service {
        name = "wuzzy-orchestrator-postgres-live"
        port = "postgres"

        check {
          name     = "postgres-tcp-check"
          type     = "tcp"
          interval = "5s"
          timeout  = "10s"
        }
        check {
          name      = "postgres-pg_isready-check"
          type      = "script"
          command   = "pg_isready"
          args      = [
            "-U", "${POSTGRES_USER}",
            "-d", "${POSTGRES_DB}"
          ]
          interval  = "5s"
          timeout   = "10s"
        }
      }
    }
  }
}
