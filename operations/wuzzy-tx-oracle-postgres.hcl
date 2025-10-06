job "wuzzy-tx-oracle-postgres" {
  datacenters = [ "mb-hel" ]
  type = "service"

  group "wuzzy-tx-oracle-postgres-group" {
    count = 1

    network {
      mode = "bridge"
      port "postgres" {
        host_network = "wireguard"
      }
    }

    volume "wuzzy-tx-oracle-postgres" {
      type      = "host"
      read_only = false
      source    = "wuzzy-tx-oracle-postgres"
    }

    task "wuzzy-tx-oracle-postgres-task" {
      driver = "docker"

      config {
        image = "postgres:17.2"
        args = [ "-c", "listen_addresses=*" ]
      }

      volume_mount {
        volume = "wuzzy-tx-oracle-postgres"
        destination = "/var/lib/postgresql/data"
        read_only = false
      }

      env {
        POSTGRES_DB = "wuzzy-tx-oracle"
        PGPORT      = "${NOMAD_PORT_postgres}"
      }

      vault { policies = [ "wuzzy-tx-oracle" ] }

      template {
        data = <<-EOF
        {{ with secret "kv/wuzzy/tx-oracle" }}
        POSTGRES_USER     = "{{ .Data.data.DB_USER }}"
        POSTGRES_PASSWORD = "{{ .Data.data.DB_PASSWORD }}"
        {{ end }}
        EOF
        destination = "secrets/config.env"
        env = true
      }

      resources {
        cpu    = 4096
        memory = 4096
      }

      service {
        name = "wuzzy-tx-oracle-postgres"
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
