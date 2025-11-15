job "wuzzy-clickhouse" {
  datacenters = ["mb-hel"]
  type        = "service"
  group "clickhouse" {
    count = 1
    network {
      port "http" { to = 8123 }
      port "https" { to = 8443 }
      port "native" { to = 9000 }
    }
    volume "wuzzy-clickhouse" {
      type = "host"
      read_only = false
      source = "wuzzy-clickhouse"
    }
    task "clickhouse-server" {
      driver = "docker"
      config {
        image = "clickhouse/clickhouse-server:25.4"
        ulimit { nofile = "262144:262144" }
        volumes = [
          "local/config.xml:/etc/clickhouse-server/config.d/config.xml:ro"
        ]
      }
      volume_mount {
        volume = "wuzzy-clickhouse"
        destination = "/var/lib/clickhouse"
        read_only = false
      }
      logs {
        max_files     = 5
        max_file_size = 15
      }
      env {
        CLICKHOUSE_USER = "default"
      }
      template {
        data = <<-EOF
        <clickhouse>
          <logger>
            <level>information</level>
            <console>true</console>
          </logger>
        </clickhouse>
        EOF
        destination = "local/config.xml"
      }
      vault { policies = [ "wuzzy-clickhouse" ] }
      template {
        data = <<-EOF
        {{- with secret "kv/wuzzy/clickhouse" }}
        CLICKHOUSE_PASSWORD="{{ .Data.data.CLICKHOUSE_PASSWORD }}"
        {{- end }}
        EOF
        env = true
        destination = "secrets/config.env"
      }
      resources {
        cpu    = 2048
        memory = 2048
      }
      service {
        name = "wuzzy-clickhouse-http"
        port = "http"
        # check {
        #   name     = "wuzzy-clickhouse-http-health"
        #   type     = "http"
        #   path     = "/"
        #   interval = "10s"
        #   timeout  = "3s"
        # }
      }
      service {
        name = "wuzzy-clickhouse-https"
        port = "https"
      }
      service {
        name = "wuzzy-clickhouse-native"
        port = "native"
      }
    }
  }
}
