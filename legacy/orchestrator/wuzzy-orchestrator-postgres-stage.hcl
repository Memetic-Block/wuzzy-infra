job "wuzzy-orchestrator-postgres-stage" {
  datacenters = [ "mb-hel" ]
  type = "service"

  group "wuzzy-orchestrator-postgres-stage-group" {
    count = 1

    network {
      mode = "bridge"
      port "postgres" {
        host_network = "wireguard"
      }
    }

    volume "wuzzy-orchestrator-postgres-stage" {
      type      = "host"
      read_only = false
      source    = "wuzzy-orchestrator-postgres-stage"
    }

    task "wuzzy-orchestrator-postgres-stage-task" {
      driver = "docker"

      config {
        image = "postgres:18"
        args = [ "-c", "listen_addresses=*" ]
      }

      volume_mount {
        volume = "wuzzy-orchestrator-postgres-stage"
        destination = "/var/lib/postgresql/18/docker"
        read_only = false
      }

      env {
        POSTGRES_DB = "wuzzy-orchestrator-stage"
        PGPORT      = "${NOMAD_PORT_postgres}"
      }

      vault { policies = [ "wuzzy-orchestrator-stage" ] }

      template {
        data = <<-EOF
        {{- with secret "kv/wuzzy/orchestrator-stage" }}
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
        name = "wuzzy-orchestrator-postgres-stage"
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
