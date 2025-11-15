job "wuzzy-crawler-live" {
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

  group "wuzzy-crawler-live-group" {
    count = 1

    volume "wuzzy-crawler-live" {
      type      = "host"
      read_only = false
      source    = "wuzzy-crawler-live"
    }

    task "wuzzy-crawler-live-task" {
      driver = "docker"

      config {
        image = "ghcr.io/memetic-block/elastic-crawler:0.4.2"
        volumes = [
          "secrets/crawler-base-config.yml:/config/crawler-base-config.yml"
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
        volume = "wuzzy-crawler-live"
        destination = "/wuzzy-crawler-live"
        read_only = false
      }

      vault { policies = [ "wuzzy-opensearch-live" ] }

      template {
        data = <<-EOF
        output_sink: elasticsearch
        output_index: permaweb-crawler
        ssl_verification_mode: none # NB: disabled due to arns undernames issue
        elasticsearch:
          {{- range service "wuzzy-opensearch-live-hel-1" }}
          host: http://{{ .Address }}
          port: {{ .Port }}
          {{- end }}
          username: admin
          {{- with secret "kv/wuzzy/opensearch-live" }}
          password: {{ .Data.data.OPENSEARCH_INITIAL_ADMIN_PASSWORD }}
          {{- end }}
          ssl_verify: false
          pipeline_enabled: false
        purge_crawl_enabled: true
        EOF
        destination = "secrets/crawler-base-config.yml"
      }

      template {
        data = <<-EOF
        {{- range service "arns-indexer" }}
        DOMAIN_CONFIG_URL="http://{{ .Address }}:{{ .Port }}/crawler-config-domains.yml"
        {{- end }}
        EOF
        env = true
        destination = "local/config.env"
      }

      template {
        data = <<-EOF
        #!/bin/sh

        echo "Fetching crawl config domains from ${DOMAIN_CONFIG_URL}"
        # wget -O /tmp/crawl-config-domains.yml "${DOMAIN_CONFIG_URL}"
        curl -o /tmp/crawl-config-domains.yml "${DOMAIN_CONFIG_URL}"

        sed \
          "s/output_index: permaweb-crawler/output_index: permaweb-crawler-$(date +%Y-%m-%d)/" \
          /config/crawler-base-config.yml > /tmp/crawler-base-config-daily.yml

        cat \
          /tmp/crawler-base-config-daily.yml \
          /tmp/crawl-config-domains.yml > crawler.yml

        # cat crawler.yml
        # cat /tmp/crawler-base-config-daily.yml
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
