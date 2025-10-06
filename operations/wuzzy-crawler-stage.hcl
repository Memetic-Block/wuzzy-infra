job "wuzzy-crawler-stage" {
  datacenters = [ "mb-hel" ]
  type = "batch"

  reschedule { attempts = 0 }

  constraint {
    attribute = "${meta.vm_max_map_count}"
    operator  = ">="
    value     = "262144"
  }

  group "wuzzy-crawler-stage-group" {
    count = 1

    volume "wuzzy-crawler-stage" {
      type      = "host"
      read_only = false
      source    = "wuzzy-crawler-stage"
    }

    task "wuzzy-crawler-stage-task" {
      driver = "docker"

      config {
        image = "docker.elastic.co/integrations/crawler:0.4.0"
        volumes = [
          "local/crawler-base-config.yml:/config/crawler-base-config.yml"
        ]
        entrypoint = [ "/workdir/entrypoint.sh" ]
        mount {
          type = "bind"
          source = "local/entrypoint.sh"
          target = "/workdir/entrypoint.sh"
          readonly = true
        }
      }

      volume_mount {
        volume = "wuzzy-crawler-stage"
        destination = "/wuzzy-crawler-stage"
        read_only = false
      }

      template {
        data = <<-EOF
        output_sink: elasticsearch
        output_index: permaweb-crawler-test
        {{ range service "wuzzy-elasticsearch-stage" }}
        elasticsearch:
          host: http://{{ .Address }}
          port: {{ .Port }}
        {{- end }}
          username: elastic
          password: changeme
          ssl_verify: false
          pipeline_enabled: false

        purge_crawl_enabled: true
        EOF
        destination = "local/crawler-base-config.yml"
      }

      template {
        data = <<-EOF
        #!/bin/sh

        cat \
          /config/crawler-base-config.yml \
          /wuzzy-crawler-stage/crawl-config-domains.yml > crawler.yml

        jruby -J-Xmx8192M bin/crawler crawl crawler.yml
        EOF
        destination = "local/entrypoint.sh"
        perms = "0755"
      }

      resources {
        cpu    = 4096
        memory = 8192
      }

      restart {
        attempts = 0
        mode = "fail"
      }
    }
  }
}
