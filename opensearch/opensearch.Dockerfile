FROM opensearchproject/opensearch:3.3.1
RUN /usr/share/opensearch/bin/opensearch-plugin install --batch query-insights
