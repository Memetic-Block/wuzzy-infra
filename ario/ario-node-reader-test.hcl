job "ario-node-reader-test" {
  datacenters = ["mb-hel"]
  type = "batch"

  reschedule { attempts = 0 }

  group "ario-node-reader-test-group" {
    count = 1

    volume "wuzzy-ario-node-core" {
      type = "host"
      read_only = true
      source = "wuzzy-ario-node-core"
    }

    task "ario-node-reader-test-task" {
      driver = "docker"

      config {
        image = "ghcr.io/memetic-block/sqlite3:latest"

        # entrypoint = [ "sh", "-c" ]
        # command = "ls"

        command = "sqlite3"
        args = [
          "-readonly",
          # "sqlite/core.db",
          # "sqlite/data.db",
          "sqlite/bundles.db",
          ".schema"
        ]

        # entrypoint = [ "/workdir/entrypoint.sh" ]
        # mount {
        #   type = "bind"
        #   source = "local/entrypoint.sh"
        #   target = "/workdir/entrypoint.sh"
        #   readonly = true
        # }
      }

      volume_mount {
        volume = "wuzzy-ario-node-core"
        destination = "/data"
        read_only = true
      }

      restart {
        attempts = 0
        mode = "fail"
      }
    }
  }
}
