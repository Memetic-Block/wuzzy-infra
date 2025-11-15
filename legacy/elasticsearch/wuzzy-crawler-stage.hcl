job "wuzzy-crawler-stage" {
  datacenters = [ "mb-hel" ]
  type = "batch"

  periodic {
    crons             = [ "@daily" ]
    prohibit_overlap = true
  }

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
        image = "ghcr.io/memetic-block/elastic-crawler:0.4.2"
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
        output_index: permaweb-crawler
        ssl_verification_mode: none # NB: disabled due to arns undernames issue
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
        {{- range service "arns-indexer" }}
        CRAWL_DOMAINS_API="{{ .Address }}:{{ .Port }}"
        {{- end }}
        EOF
        env = true
        destination = "local/config.env"
      }

      template {
        data = <<-EOF
        #!/bin/sh

        curl -o /tmp/crawl-config-domains.yml \
          "http://${CRAWL_DOMAINS_API}/crawler-config-domains.yml"

        sed \
          "s/output_index: permaweb-crawler/output_index: permaweb-crawler-$(date +%Y-%m-%d)/" \
          /config/crawler-base-config.yml > /tmp/crawler-base-config-daily.yml

        cat \
          /tmp/crawler-base-config-daily.yml \
          /tmp/crawl-config-domains.yml > crawler.yml

        # cat crawler.yml
        # cat /tmp/crawler-base-config-daily.yml
        # cat /tmp/crawl-config-domains.yml
        jruby -J-Xmx16384M bin/crawler crawl crawler.yml
        EOF
        destination = "local/entrypoint.sh"
        perms = "0755"
      }

      resources {
        cpu    = 4096
        memory = 16384
      }

      restart {
        attempts = 0
        mode = "fail"
      }
    }
  }
}
