job "wuzzy-tx-oracle-redis" {
  datacenters = ["mb-hel"]
  type = "service"

  group "wuzzy-tx-oracle-redis-group" {
    count = 1

    volume "wuzzy-tx-oracle-redis" {
      type = "host"
      read_only = false
      source = "wuzzy-tx-oracle-redis"
    }

    network {
      mode = "bridge"
      port "redis" {
        host_network = "wireguard"
      }
    }

    task "wuzzy-tx-oracle-redis" {
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
        volume = "wuzzy-tx-oracle-redis"
        destination = "/data"
        read_only = false
      }

      resources {
        cpu    = 1024
        memory = 2048
      }

      service {
        name = "wuzzy-tx-oracle-redis"
        port = "redis"
        
        check {
          name     = "wuzzy-tx-oracle-redis-check"
          type     = "tcp"
          interval = "5s"
          timeout  = "10s"
        }
      }
    }
  }
}
