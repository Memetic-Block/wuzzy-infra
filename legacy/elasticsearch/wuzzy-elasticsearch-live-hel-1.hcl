job "wuzzy-elasticsearch-live-hel-1" {
  datacenters = [ "mb-hel" ]
  type = "service"

  constraint {
    attribute = "${meta.vm_max_map_count}"
    operator  = ">="
    value     = "262144"
  }

  group "wuzzy-elasticsearch-live-hel-1-group" {
    count = 1

    network {
      mode = "bridge"
      port "elasticsearch_live_hel_1" {
        static       = 9200
        host_network = "wireguard"
      }
    }

    volume "wuzzy-elasticsearch-live-hel-1" {
      type      = "host"
      read_only = false
      source    = "wuzzy-elasticsearch-live-hel-1"
    }

    task "wuzzy-elasticsearch-live-hel-1-task" {
      driver = "docker"

      config {
        image = "docker.elastic.co/elasticsearch/elasticsearch:9.1.5"
      }

      volume_mount {
        volume = "wuzzy-elasticsearch-live-hel-1"
        destination = "/usr/share/elasticsearch/data"
        read_only = false
      }

      env {
        ES_SETTING_NODE_NAME="wuzzy-elasticsearch-live-hel-1"
        ES_SETTING_NETWORK_HOST="0.0.0.0"
        ES_SETTING_HTTP_PORT="${NOMAD_PORT_elasticsearch_live_hel_1}"
        ES_SETTING_XPACK_SECURITY_ENABLED="false"
        ES_SETTING_CLUSTER_NAME="wuzzy-elasticsearch-live-cluster"
        # ES_SETTING_CLUSTER_INITIAL__MASTER__NODES="wuzzy-elasticsearch-live-hel-1,wuzzy-elasticsearch-live-hel-2,wuzzy-elasticsearch-live-fsn-1"
      }

      template {
        data = <<-EOF
        ES_SETTING_DISCOVERY_SEED__HOSTS="10.0.1.2:9200,10.0.1.3:9200"
        EOF
        destination = "local/config.env"
        env = true
        change_mode = "noop"
      }

      vault { policies = [ "wuzzy-elasticsearch-live" ] }

      template {
        data = <<-EOF
        {{- with secret "kv/wuzzy/elasticsearch-live" }}
        ELASTIC_PASSWORD="{{ .Data.data.ELASTIC_PASSWORD }}"
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
        name = "wuzzy-elasticsearch-live-hel-1"
        port = "elasticsearch_live_hel_1"

        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "10s"
        }
      }
    }
  }
}
