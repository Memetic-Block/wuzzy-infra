job "arns-indexer-redis" {
  datacenters = [ "mb-hel" ]
  type = "service"

  group "arns-indexer-redis-group" {
    count = 1

    volume "arns-indexer-redis" {
      type = "host"
      read_only = false
      source = "arns-indexer-redis"
    }

    network {
      mode = "bridge"
      port "redis" {
        host_network = "wireguard"
      }
    }

    task "arns-indexer-redis" {
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
        volume = "arns-indexer-redis"
        destination = "/data"
        read_only = false
      }

      resources {
        cpu    = 512
        memory = 512
      }

      service {
        name = "arns-indexer-redis"
        port = "redis"
        
        check {
          name     = "arns-indexer-redis-check"
          type     = "tcp"
          interval = "5s"
          timeout  = "10s"
        }
      }
    }
  }
}
