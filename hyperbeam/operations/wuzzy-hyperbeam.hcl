job "wuzzy-hyperbeam" {
  datacenters = [ "mb-hel" ]
  type = "service"

  group "wuzzy-hyperbeam-group" {
    count = 1

    network {
      mode = "bridge"
      port "hyperbeam" {
        to = 8734
        host_network = "wireguard"
      }
    }

    volume "wuzzy-hyperbeam" {
      type = "host"
      read_only = false
      source = "wuzzy-hyperbeam"
    }

    task "hyperbeam-task-dev" {
      driver = "docker"

      config {
        image = "ghcr.io/memetic-block/hyperbeam:edge"
        force_pull = true
        image_pull_timeout = "15m"
        command = "rebar3"
        args = [ "as", "genesis_wasm", "shell" ]
        volumes = [
          "local/config.flat:/app/config.flat",
          "secrets/wallet.json:/app/wallet.json"
        ]
      }

      volume_mount {
        volume = "wuzzy-hyperbeam"
        destination = "/app/cache-mainnet"
        read_only = false
      }

      resources {
        cpu = 32768
        memory = 32768
      }

      template {
        data = <<-EOF
        priv_key_location: /app/wallet.json
        EOF
        destination = "local/config.flat"
      }

      vault { policies = [ "wuzzy-hyperbeam" ] }

      template {
        data = <<-EOF
        {{- with secret `kv/wuzzy/hyperbeam` }}
        {{- base64Decode .Data.data.HB_OPERATOR_KEY_BASE64 }}
        {{- end }}
        EOF
        destination = "secrets/wallet.json"
      }

      service {
        name = "wuzzy-hyperbeam"
        port = "hyperbeam"
        tags = [
          "traefik.enable=true",
          "traefik.http.middlewares.wuzzy-hyperbeam.headers.accesscontrolallowmethods=GET,OPTIONS,PUT,POST,DELETE,HEAD,PATCH",
          "traefik.http.middlewares.wuzzy-hyperbeam.headers.accesscontrolallowheaders=*",
          "traefik.http.middlewares.wuzzy-hyperbeam.headers.accesscontrolalloworiginlist=*",
          "traefik.http.middlewares.wuzzy-hyperbeam.headers.accesscontrolmaxage=100",
          "traefik.http.middlewares.wuzzy-hyperbeam.headers.addvaryheader=true",
          "traefik.http.routers.wuzzy-hyperbeam.entrypoints=https",
          "traefik.http.routers.wuzzy-hyperbeam.tls=true",
          "traefik.http.routers.wuzzy-hyperbeam.tls.certresolver=memetic-block",
          "traefik.http.routers.wuzzy-hyperbeam.rule=Host(`wuzzy-hyperbeam.hel.memeticblock.net`)",
          "traefik.http.routers.wuzzy-hyperbeam.middlewares=wuzzy-kibana-stage-corsheaders@consulcatalog"
        ]

        check {
          name = "wuzzy-hyperbeam-check"
          type = "http"
          port = "hyperbeam"
          path = "/~meta@1.0/info"
          interval = "10s"
          timeout  = "10s"
        }
      }
    }
  }
}
