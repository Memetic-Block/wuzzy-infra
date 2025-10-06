job "wuzzy-goldsky-sync" {
  datacenters = [ "mb-hel" ]
  type = "batch"

  reschedule { attempts = 0 }

  group "wuzzy-goldsky-sync-group" {
    count = 1

    volume "wuzzy-goldsky-sync" {
      type      = "host"
      read_only = false
      source    = "wuzzy-goldsky-sync"
    }

    task "wuzzy-goldsky-sync-task" {
      driver = "docker"

      config {
        image = "goldsky/indexed.xyz:latest"
        command = "goldsky"
        args = [
          "indexed", "sync", "raw-transactions",
          "--network=arweave",
          "--data-version=1.0.0"
        ]
      }

      volume_mount {
        volume = "wuzzy-goldsky-sync"
        destination = "/var/opt/indexed-xyz"
        read_only = false
      }

      resources {
        cpu    = 1024
        memory = 4096
      }

      restart {
        attempts = 0
        mode = "fail"
      }
    }
  }
}
