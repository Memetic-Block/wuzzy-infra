job "wuzzy-opensearch-live-hel-1" {
  datacenters = [ "mb-hel" ]
  type = "service"

  group "wuzzy-opensearch-live-hel-1-group" {
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

    volume "wuzzy-opensearch-live-hel-1" {
      type      = "host"
      read_only = false
      source    = "wuzzy-opensearch-live-hel-1"
    }

    task "wuzzy-opensearch-live-hel-1-task" {
      driver = "docker"

      config {
        image = "opensearchproject/opensearch:3.3.1"
        volumes = [
          "local/opensearch.yml:/usr/share/opensearch/config/opensearch.yml"
        ]
      }

      volume_mount {
        volume = "wuzzy-opensearch-live-hel-1"
        destination = "/usr/share/opensearch/data"
        read_only = false
      }

      env {
        DISABLE_SECURITY_PLUGIN = "true"
      }

      template {
        data = <<-EOF
        node.name: wuzzy-opensearch-live-hel-1
        network.host: 0.0.0.0
        network.publish_host: {{ env "NOMAD_IP_transport" }}
        http.port: {{ env "NOMAD_PORT_http" }}
        transport.port: {{ env "NOMAD_PORT_transport" }}
        # discovery.type: single-node
        cluster.name: wuzzy-opensearch-live-cluster
        cluster.initial_cluster_manager_nodes: wuzzy-opensearch-live-hel-1,wuzzy-opensearch-live-hel-2
        {{- range service "wuzzy-opensearch-live-hel-2-transport" }}
        discovery.seed_hosts: {{ .Address }}:{{ .Port }}
        {{- end }}
        EOF
        destination = "local/opensearch.yml"
        change_mode = "noop"
      }

      vault { policies = [ "wuzzy-opensearch-live" ] }

      template {
        data = <<-EOF
        {{- with secret "kv/wuzzy/opensearch-live" }}
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
        name = "wuzzy-opensearch-live-hel-1"
        port = "http"
        check {
          name     = "wuzzy-opensearch-live-hel-1 Health Check"
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "10s"
        }
      }

      service {
        name = "wuzzy-opensearch-live-hel-1-transport"
        port = "transport"
        tags = [ "transport" ]
      }
    }
  }
}
