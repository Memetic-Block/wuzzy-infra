job "wuzzy-elasticsearch-stage" {
  datacenters = [ "mb-hel" ]
  type = "service"

  constraint {
    attribute = "${meta.vm_max_map_count}"
    operator  = ">="
    value     = "262144"
  }

  group "wuzzy-elasticsearch-stage-group" {
    count = 1

    network {
      mode = "bridge"
      port "elasticsearch" {
        to           = 9200
        host_network = "wireguard"
      }
    }

    volume "wuzzy-elasticsearch-stage" {
      type      = "host"
      read_only = false
      source    = "wuzzy-elasticsearch-stage"
    }

    task "wuzzy-elasticsearch-stage-task" {
      driver = "docker"

      config {
        image = "docker.elastic.co/elasticsearch/elasticsearch:9.1.5"
      }

      volume_mount {
        volume = "wuzzy-elasticsearch-stage"
        destination = "/usr/share/elasticsearch/data"
        read_only = false
      }

      env {
        ELASTIC_PASSWORD="changeme"
        ES_SETTING_NODE_NAME="wuzzy-elasticsearch-stage-node-01"
        ES_SETTING_CLUSTER_NAME="wuzzy-elasticsearch-stage-cluster"
        ES_SETTING_CLUSTER_INITIAL__MASTER__NODES="wuzzy-elasticsearch-stage-node-01"
        ES_SETTING_NETWORK_HOST="0.0.0.0"
        ES_SETTING_HTTP_PORT="${NOMAD_PORT_elasticsearch}"
        ES_SETTING_XPACK_SECURITY_ENABLED="false"
      }

      resources {
        cpu    = 2048
        memory = 4096
      }

      service {
        name = "wuzzy-elasticsearch-stage"
        port = "elasticsearch"

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
