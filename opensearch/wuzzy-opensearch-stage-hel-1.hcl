job "wuzzy-opensearch-stage-hel-1" {
  datacenters = [ "mb-hel" ]
  type = "service"

  group "wuzzy-opensearch-stage-hel-1-group" {
    count = 1

    network {
      mode = "bridge"
      port "http" {
        host_network = "wireguard"
      }
      port "transport" {
        host_network = "wireguard"
      }
      port "performance_monitor" {
        host_network = "wireguard"
      }
    }

    volume "wuzzy-opensearch-stage-hel-1" {
      type      = "host"
      read_only = false
      source    = "wuzzy-opensearch-stage-hel-1"
    }

    task "wuzzy-opensearch-stage-hel-1-task" {
      driver = "docker"

      config {
        image = "opensearchproject/opensearch:3.3.1"
        volumes = [
          "local/opensearch.yml:/usr/share/opensearch/config/opensearch.yml"
        ]
      }

      volume_mount {
        volume = "wuzzy-opensearch-stage-hel-1"
        destination = "/usr/share/opensearch/data"
        read_only = false
      }

      env {
        DISABLE_SECURITY_PLUGIN = "true"
      }

      template {
        data = <<-EOF
        node.name: wuzzy-opensearch-stage-hel-1
        network.host: 0.0.0.0
        network.publish_host: {{ env "NOMAD_IP_transport" }}
        http.port: {{ env "NOMAD_PORT_http" }}
        transport.port: {{ env "NOMAD_PORT_transport" }}
        discovery.type: single-node
        EOF
        destination = "local/opensearch.yml"
        change_mode = "noop"
      }

      vault { policies = [ "wuzzy-opensearch-stage" ] }

      template {
        data = <<-EOF
        {{- with secret "kv/wuzzy/opensearch-stage" }}
        OPENSEARCH_INITIAL_ADMIN_PASSWORD="{{ .Data.data.OPENSEARCH_INITIAL_ADMIN_PASSWORD }}"
        {{- end }}
        EOF
        destination = "secrets/config.env"
        env = true
      }

      resources {
        cpu    = 2048
        memory = 4096
      }

      service {
        name = "wuzzy-opensearch-stage-hel-1"
        port = "http"
        check {
          name     = "wuzzy-opensearch-stage-hel-1 Health Check"
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "10s"
        }
      }

      service {
        name = "wuzzy-opensearch-stage-hel-1-transport"
        port = "transport"
        tags = [ "transport" ]
      }
    }
  }
}
