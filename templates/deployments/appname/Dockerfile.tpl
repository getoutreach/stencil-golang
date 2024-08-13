# syntax=docker/dockerfile:1.0-experimental
{{- $goVersion := semver (stencil.ApplyTemplate "goVersion" | trim) }}
{{- $_ := file.SetPath (printf "deployments/%s/%s" .Config.Name (base file.Path)) }}
{{- $_ := stencil.ApplyTemplate "skipIfNotService" }}
FROM {{ .Runtime.Box.Docker.ImagePullRegistry }}/golang:{{ $goVersion.Major }}.{{ $goVersion.Minor }}.{{ $goVersion.Patch }} as builder
ARG VERSION
ENV GOCACHE "/go-build-cache"
ENV GOPRIVATE github.com/{{ .Runtime.Box.Org }}/*
ENV CGO_ENABLED {{ stencil.ApplyTemplate "cgoEnabled" | trim }}
WORKDIR /src

# Copy our source code into the container for building
COPY . .

## <<Stencil::Block(beforeBuild)>>
{{ file.Block "beforeBuild" }}
## <</Stencil::Block>>

# Cache dependencies across builds
RUN --mount=type=ssh --mount=type=cache,target=/go/pkg go mod download

# Build our application, caching the go build cache, but also using
# the dependency cache from earlier.
RUN --mount=type=ssh --mount=type=cache,target=/go/pkg --mount=type=cache,target=/go-build-cache \
  mkdir -p bin; \
  go build -o /src/bin/ -ldflags "-X github.com/getoutreach/gobox/pkg/app.Version=$VERSION" -v ./cmd/...

FROM {{ .Runtime.Box.Docker.ImagePullRegistry }}:{{ stencil.Arg "versions.alpine" }}
ENTRYPOINT ["/usr/local/bin/{{ .Config.Name }}"]

LABEL "io.outreach.reporting_team"="{{ stencil.Arg "reportingTeam" }}"
LABEL "io.outreach.repo"="{{ .Config.Name }}"

# Add timezone information.
COPY --from=builder /usr/local/go/lib/time/zoneinfo.zip /zoneinfo.zip
ENV ZONEINFO=/zoneinfo.zip

# Install certificates for RDS connectivity.
RUN wget --output-document /usr/local/share/ca-certificates/global-bundle.pem \
  "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem" \
  && update-ca-certificates

## <<Stencil::Block(afterBuild)>>
{{ file.Block "afterBuild" }}
## <</Stencil::Block>>

COPY --from=builder /src/bin/{{ .Config.Name }} /usr/local/bin/{{ .Config.Name }}
{{- $afterBuildHook := stencil.GetModuleHook "Dockerfile.afterBuild" }}
{{- if $afterBuildHook }}

# Begin afterBuild module hook entries
{{- range $afterBuildHook }}
{{ . }}

{{- end }}
# End afterBuild module hook entries

{{- end }}
USER systemuser
