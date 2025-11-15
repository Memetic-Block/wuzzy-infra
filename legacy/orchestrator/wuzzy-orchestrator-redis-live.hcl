job "wuzzy-orchestrator-redis-live" {
  datacenters = [ "mb-hel" ]
  type = "service"

  group "wuzzy-orchestrator-redis-live-group" {
    count = 1

    volume "wuzzy-orchestrator-redis-live" {
      type = "host"
      read_only = false
      source = "wuzzy-orchestrator-redis-live"
    }

    network {
      mode = "bridge"
      port "redis" {
        host_network = "wireguard"
      }
    }

    task "wuzzy-orchestrator-redis-live" {
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
        volume = "wuzzy-orchestrator-redis-live"
        destination = "/data"
        read_only = false
      }

      resources {
        cpu    = 1024
        memory = 2048
      }

      service {
        name = "wuzzy-orchestrator-redis-live"
        port = "redis"
        
        check {
          name     = "wuzzy-orchestrator-redis-live-check"
          type     = "tcp"
          interval = "5s"
          timeout  = "10s"
        }
      }
    }
  }
}
