job "wuzzy-kibana-stage" {
  datacenters = [ "mb-hel" ]
  type = "service"

  constraint {
    attribute = "${meta.region}"
    value     = "useast"
  }

  group "wuzzy-kibana-stage-group" {
    count = 1

    network {
      mode = "bridge"
      port "kibana" {
        to           = 5601
        host_network = "wireguard"
      }
    }

    task "wuzzy-kibana-stage-task" {
      driver = "docker"

      config {
        image = "docker.elastic.co/kibana/kibana:9.1.5"
        volumes = [
          "local/kibana.yml:/home/kibana/config/kibana.yml"
        ]
      }

      env {
        KBN_PATH_CONF="/home/kibana/config"
      }

      template {
        data = <<-EOF
        server.name: wuzzy-kibana-stage
        server.port: 5601
        server.host: 0.0.0.0
        server.publicBaseUrl: https://wuzzy-kibana-stage.hel.memeticblock.net

        {{- range service "wuzzy-elasticsearch-stage" }}
        elasticsearch.hosts: [ "http://{{ .Address }}:{{ .Port }}" ]
        {{- end }}
        EOF
        destination = "local/kibana.yml"
      }

      resources {
        cpu    = 1024
        memory = 1024
      }

      service {
        name = "wuzzy-kibana-stage"
        port = "kibana"

        check {
          type     = "http"
          path     = "/api/status"
          interval = "10s"
          timeout  = "10s"
        }

        tags = [
          "traefik.enable=true",
          "traefik.http.middlewares.wuzzy-kibana-stage-corsheaders.headers.accesscontrolallowmethods=GET,OPTIONS,PUT,POST,DELETE,HEAD,PATCH",
          "traefik.http.middlewares.wuzzy-kibana-stage-corsheaders.headers.accesscontrolallowheaders=*",
          "traefik.http.middlewares.wuzzy-kibana-stage-corsheaders.headers.accesscontrolalloworiginlist=*",
          "traefik.http.middlewares.wuzzy-kibana-stage-corsheaders.headers.accesscontrolmaxage=100",
          "traefik.http.middlewares.wuzzy-kibana-stage-corsheaders.headers.addvaryheader=true",
          "traefik.http.routers.wuzzy-kibana-stage.entrypoints=https",
          "traefik.http.routers.wuzzy-kibana-stage.tls=true",
          "traefik.http.routers.wuzzy-kibana-stage.tls.certresolver=memetic-block",
          "traefik.http.routers.wuzzy-kibana-stage.rule=Host(`wuzzy-kibana-stage.hel.memeticblock.net`)",
          "traefik.http.routers.wuzzy-kibana-stage.middlewares=memetic-block-devs-ipwhitelist@consulcatalog,wuzzy-kibana-stage-corsheaders@consulcatalog"
        ]
      }
    }
  }
}
