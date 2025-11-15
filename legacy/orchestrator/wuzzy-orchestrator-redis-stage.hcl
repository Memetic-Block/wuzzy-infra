job "wuzzy-orchestrator-redis-stage" {
  datacenters = [ "mb-hel" ]
  type = "service"

  group "wuzzy-orchestrator-redis-stage-group" {
    count = 1

    volume "wuzzy-orchestrator-redis-stage" {
      type = "host"
      read_only = false
      source = "wuzzy-orchestrator-redis-stage"
    }

    network {
      mode = "bridge"
      port "redis" {
        host_network = "wireguard"
      }
    }

    task "wuzzy-orchestrator-redis-stage" {
      driver = "docker"
      config {
        image = "redis:7.2"
        command = "redis-server"
        args = [
          "--maxmemory-policy noeviction",
          "--appendonly no",
          "--port ${NOMAD_PORT_redis}"
        ]
      }

      volume_mount {
        volume = "wuzzy-orchestrator-redis-stage"
        destination = "/data"
        read_only = false
      }

      resources {
        cpu    = 1024
        memory = 2048
      }

      service {
        name = "wuzzy-orchestrator-redis-stage"
        port = "redis"
        
        check {
          name     = "wuzzy-orchestrator-redis-stage-check"
          type     = "tcp"
          interval = "5s"
          timeout  = "10s"
        }
      }
    }
  }
}
