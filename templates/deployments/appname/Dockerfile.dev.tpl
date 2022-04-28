# syntax=docker/dockerfile:1.0-experimental
# This Dockerfile is used by Tilt currently. It should
# be kept in sync with the production one.
{{- $goVersion := semver (stencil.ApplyTemplate "goVersion") }}
FROM gcr.io/outreach-docker/golang:{{ $goVersion.Major }}.{{ $goVersion.Minor }}.{{ $goVersion.Patch }} as builder
FROM gcr.io/outreach-docker/alpine:3.12
WORKDIR "/app/bin"
ENTRYPOINT ["/app/bin/{{ .Config.Name }}"]

# Ensure that tilt can hot-swap
RUN chown systemuser:systemuser /app/bin

# Add timezone information.
COPY --from=builder /usr/local/go/lib/time/zoneinfo.zip /zoneinfo.zip
ENV ZONEINFO=/zoneinfo.zip

# Ensure we can use RDS
RUN apk add --no-cache curl \
    &&  curl "https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem" --output /usr/local/share/ca-certificates/rds-combined-ca-bundle.pem \
    &&  update-ca-certificates \
    &&  apk del --no-cache curl

###Block(afterBuild)
{{- if .afterBuild }}
{{ .afterBuild }}
{{- end }}
###EndBlock(afterBuild)
USER systemuser

COPY ./bin/{{ .Config.Name }} /app/bin/{{ .Config.Name }}
