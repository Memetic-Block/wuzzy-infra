job "wuzzy-postgres-stage" {
  datacenters = [ "mb-hel" ]
  type = "service"

  group "wuzzy-postgres-stage-group" {
    count = 1

    network {
      mode = "bridge"
      port "postgres" {
        host_network = "wireguard"
      }
    }

    volume "wuzzy-postgres-stage" {
      type      = "host"
      read_only = false
      source    = "wuzzy-postgres-stage"
    }

    task "wuzzy-postgres-stage-task" {
      driver = "docker"

      config {
        image = "postgres:18.0"
        args = [ "-c", "listen_addresses=*" ]
      }

      volume_mount {
        volume = "wuzzy-postgres-stage"
        destination = "/var/lib/postgresql/18/docker"
        read_only = false
      }

      env {
        POSTGRES_DB = "wuzzy-postgres-stage"
        PGPORT      = "${NOMAD_PORT_postgres}"
      }

      vault { policies = [ "wuzzy-postgres-stage" ] }

      template {
        data = <<-EOF
        {{ with secret "kv/wuzzy/postgres-stage" }}
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
        name = "wuzzy-postgres-stage"
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
