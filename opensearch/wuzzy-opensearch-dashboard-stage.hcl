job "wuzzy-opensearch-dashboard-stage" {
  datacenters = [ "mb-hel" ]
  type = "service"

  constraint {
    attribute = "${meta.region}"
    value     = "useast"
  }

  group "wuzzy-opensearch-dashboard-stage-group" {
    count = 1

    network {
      mode = "bridge"
      port "http" {
        host_network = "wireguard"
      }
    }

    task "wuzzy-opensearch-dashboard-stage-task" {
      driver = "docker"

      config {
        image = "opensearchproject/opensearch-dashboards:3.3.0"
        volumes = [
          "local/opensearch_dashboards.yml:/usr/share/opensearch-dashboards/config/opensearch_dashboards.yml"
        ]
      }

      template {
        data = <<-EOF
        server.name: wuzzy-opensearch-dashboard-stage
        server.port: ${NOMAD_PORT_http}
        server.host: 0.0.0.0
        server.ssl.enabled: false
        opensearch_security.enabled: false
        opensearch.ssl.verificationMode: none
        opensearch.requestHeadersWhitelist: ["securitytenant","Authorization"]
        opensearch_security.multitenancy.enabled: true
        opensearch_security.multitenancy.tenants.preferred: ["Private", "Global"]
        opensearch_security.readonly_mode.roles: ["kibana_read_only"]
        {{- range service "wuzzy-opensearch-stage-hel-1" }}
        opensearch.hosts: [ "http://{{ .Address }}:{{ .Port }}" ]
        {{- end }}
        server.customResponseHeaders : { "Access-Control-Allow-Credentials" : "true" }
        EOF
        destination = "local/opensearch_dashboards.yml"
      }

      resources {
        cpu    = 1024
        memory = 1024
      }

      service {
        name = "wuzzy-opensearch-dashboard-stage"
        port = "http"

        check {
          name     = "wuzzy-opensearch-dashboard-stage Health Check"
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "10s"
        }

        tags = [
          "traefik.enable=true",
          "traefik.http.middlewares.wuzzy-opensearch-dashboard-stage-corsheaders.headers.accesscontrolallowmethods=GET,OPTIONS,PUT,POST,DELETE,HEAD,PATCH",
          "traefik.http.middlewares.wuzzy-opensearch-dashboard-stage-corsheaders.headers.accesscontrolallowheaders=*",
          "traefik.http.middlewares.wuzzy-opensearch-dashboard-stage-corsheaders.headers.accesscontrolalloworiginlist=*",
          "traefik.http.middlewares.wuzzy-opensearch-dashboard-stage-corsheaders.headers.accesscontrolmaxage=100",
          "traefik.http.middlewares.wuzzy-opensearch-dashboard-stage-corsheaders.headers.addvaryheader=true",
          "traefik.http.routers.wuzzy-opensearch-dashboard-stage.entrypoints=https",
          "traefik.http.routers.wuzzy-opensearch-dashboard-stage.tls=true",
          "traefik.http.routers.wuzzy-opensearch-dashboard-stage.tls.certresolver=memetic-block",
          "traefik.http.routers.wuzzy-opensearch-dashboard-stage.rule=Host(`wuzzy-opensearch-dashboard-stage.hel.memeticblock.net`)",
          "traefik.http.routers.wuzzy-opensearch-dashboard-stage.middlewares=memetic-block-devs-ipwhitelist@consulcatalog,wuzzy-opensearch-dashboard-stage-corsheaders@consulcatalog"
        ]
      }
    }
  }
}
