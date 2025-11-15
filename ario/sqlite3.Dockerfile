FROM alpine:3.19
RUN apk add --no-cache sqlite
RUN mkdir -p /data
WORKDIR /data
CMD ["sqlite3"]
