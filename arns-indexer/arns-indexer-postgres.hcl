job "arns-indexer-postgres" {
  datacenters = [ "mb-hel" ]
  type = "service"

  group "arns-indexer-postgres-group" {
    count = 1

    network {
      mode = "bridge"
      port "postgres" {
        host_network = "wireguard"
      }
    }

    volume "arns-indexer-postgres" {
      type      = "host"
      read_only = false
      source    = "arns-indexer-postgres"
    }

    task "arns-indexer-postgres" {
      driver = "docker"

      config {
        image = "postgres:18"
        args = [ "-c", "listen_addresses=*" ]
      }

      volume_mount {
        volume = "arns-indexer-postgres"
        destination = "/var/lib/postgresql/18/docker"
        read_only = false
      }

      env {
        POSTGRES_DB = "arns_indexer"
        PGPORT      = "${NOMAD_PORT_postgres}"
      }

      vault { policies = [ "wuzzy-arns-indexer-postgres" ] }

      template {
        data = <<-EOF
        {{- with secret "kv/wuzzy/arns-indexer/postgres" }}
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
        name = "arns-indexer-postgres"
        port = "postgres"

        check {
          name     = "arns-indexer-postgres-tcp-check"
          type     = "tcp"
          interval = "5s"
          timeout  = "10s"
        }
        check {
          name      = "arns-indexer-postgres-pg_isready-check"
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
