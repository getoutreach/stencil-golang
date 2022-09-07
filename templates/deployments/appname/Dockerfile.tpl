# syntax=docker/dockerfile:1.0-experimental
{{- $goVersion := semver (stencil.ApplyTemplate "goVersion" | trim) }}
{{- $_ := file.SetPath (printf "deployments/%s/%s" .Config.Name (base file.Path)) }}
{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
FROM gcr.io/outreach-docker/golang:{{ $goVersion.Major }}.{{ $goVersion.Minor }}.{{ $goVersion.Patch }} as builder
ARG VERSION
ENV GOCACHE "/go-build-cache"
ENV GOPRIVATE github.com/{{ .Runtime.Box.Org }}/*
ENV CGO_ENABLED 0
WORKDIR /src

# Copy our source code into the container for building
COPY . .

###Block(beforeBuild)
{{ file.Block "beforeBuild" }}
###EndBlock(beforeBuild)

# Cache dependencies across builds
RUN --mount=type=ssh --mount=type=cache,target=/go/pkg make dep

# Build our application, caching the go build cache, but also using
# the dependency cache from earlier.
RUN --mount=type=ssh --mount=type=cache,target=/go/pkg --mount=type=cache,target=/go-build-cache \
    mkdir -p bin; \
    go build -o /src/bin/ -ldflags "-X github.com/getoutreach/gobox/pkg/app.Version=$VERSION" -v ./cmd/...

FROM gcr.io/outreach-docker/alpine:{{ stencil.Arg "versions.alpine" }}
ENTRYPOINT ["/usr/local/bin/{{ .Config.Name }}"]

LABEL "io.outreach.reporting_team"="{{ stencil.Arg "reportingTeam" }}"
LABEL "io.outreach.repo"="{{ .Config.Name }}"

# Add timezone information.
COPY --from=builder /usr/local/go/lib/time/zoneinfo.zip /zoneinfo.zip
ENV ZONEINFO=/zoneinfo.zip

# Install certificates for RDS connectivity.
RUN apk add --no-cache curl \
    &&  curl "https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem" --output /usr/local/share/ca-certificates/rds-combined-ca-bundle.pem \
    &&  update-ca-certificates \
    &&  apk del --no-cache curl

###Block(afterBuild)
{{ file.Block "afterBuild" }}
###EndBlock(afterBuild)

COPY --from=builder /src/bin/{{ .Config.Name }} /usr/local/bin/{{ .Config.Name }}
{{- $afterBuildHook := stencil.GetModuleHook "Dockerfile.afterBuild" }}
{{- if $afterBuildHook }}

# Begin afterBuild module hook entries
{{- range := $afterBuildHook }}
{{ . }}
{{- end }}
# End afterBuild module hook entries

{{- end }}
USER systemuser
