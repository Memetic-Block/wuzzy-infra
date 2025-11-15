job "wuzzy-elasticsearch-dump" {
  datacenters = [ "mb-hel" ]
  type = "batch"

  reschedule { attempts = 0 }

  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "memetic-hel-store-1"
  }

  group "wuzzy-elasticsearch-dump-group" {
    count = 1

    task "wuzzy-elasticsearch-dump-task" {
      driver = "docker"

      config {
        image = "elasticdump/elasticsearch-dump:v6.124.1"

        ## NB: Uncomment one of the below to choose between mapping or data 
        ##     import.  Mapping should be done first, followed by data.

        # args = [
        #   "--input=http://${ES_INPUT}/${ES_INDEX}",
        #   "--output=http://${ES_OUTPUT}/${ES_INDEX}",
        #   "--type=mapping"
        # ]

        args = [
          "--input=http://${ES_INPUT}/${ES_INDEX}",
          "--output=http://${ES_OUTPUT}/${ES_INDEX}",
          "--type=data"
        ]
      }

      env {
        ES_INDEX="permaweb-crawler-2025-10-17"
        ELASTICDUMP_INPUT_USERNAME="admin"
        ELASTICDUMP_OUTPUT_USERNAME="admin"
      }

      template {
        data = <<-EOF
        {{- range service "wuzzy-opensearch-stage-hel-1" }}
        ES_OUTPUT="{{ .Address }}:{{ .Port }}"
        {{- end }}
        {{- range service "wuzzy-opensearch-live-hel-1" }}
        ES_INPUT="{{ .Address }}:{{ .Port }}"
        {{- end }}
        EOF
        destination = "local/config.env"
        env = true
      }

      vault { policies = [ "wuzzy-opensearch-live", "wuzzy-opensearch-stage" ] }

      template {
        data = <<-EOF
        {{- with secret "kv/wuzzy/opensearch-live" }}
        ELASTICDUMP_INPUT_PASSWORD="{{ .Data.data.OPENSEARCH_INITIAL_ADMIN_PASSWORD }}"
        {{- end }}
        {{- with secret "kv/wuzzy/opensearch-stage" }}
        ELASTICDUMP_OUTPUT_PASSWORD="{{ .Data.data.OPENSEARCH_INITIAL_ADMIN_PASSWORD }}"
        {{- end }}
        EOF
        destination = "secrets/config.env"
        env = true
      }

      restart {
        attempts = 0
        mode = "fail"
      }
    }
  }
}
