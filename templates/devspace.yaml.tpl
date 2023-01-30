{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
version: v1beta11

# `vars` specifies variables which may be used as ${VAR_NAME} in devspace.yaml
vars:
  # These env vars are passed in automatically by devenv

  # ================================================
  # ========== DO NOT REORDER THESE VARS! ==========
  # ================================================
  # The vars are used to switch service label selectors in profiles
  # It's probably not the best approach, but it works well.
  - name: DEVENV_DEPLOY_APPNAME
    source: env
    default: {{ .Config.Name }}

  - name: DEVENV_DEPLOY_LABELS
    value:
      app: ${DEVENV_DEPLOY_APPNAME}

  - name: DEV_CONTAINER_EXECUTABLE
    value: ${DEVENV_DEPLOY_APPNAME}
  # ================================================

  - name: DEPLOY_TO_DEV_VERSION
    source: env
    default: "latest"
  - name: DEVENV_DEPLOY_VERSION
    source: env
    default: "latest"
  - name: DEVENV_DEPLOY_IMAGE_SOURCE
    source: env
    default: local
  - name: DEVENV_DEPLOY_DEV_IMAGE_REGISTRY
    source: env
    default: devenv.local
  - name: DEVENV_DEPLOY_BOX_IMAGE_REGISTRY
    source: env
    default: gcr.io/outreach-docker
  - name: DEVENV_DEPLOY_IMAGE_REGISTRY
    source: env
    default: ${DEVENV_DEPLOY_BOX_IMAGE_REGISTRY}
  - name: DEVENV_TYPE
    source: env
  - name: DEVENV_DEV_TERMINAL
    source: env
    default: "false"
  - name: DEVENV_DEV_SKIP_PORTFORWARDING
    source: env
    default: "false"
  - name: DEVENV_DEV_DEPLOYMENT_PROFILE
    source: env
    default: deployment__{{ .Config.Name }}
  

  # devenv passes in paths to binaries it uses (ensuring the supported versions are used)
  # devenv bin that triggered devspace
  # orc setup installs devenv bin so we can fallback to that if needed
  - name: DEVENV_BIN
    source: env
    default: devenv
  # devspace bin for running devspace commands (e.g. devspace run build-jsonnet)
  # orc setup installs devspace bin so we can fallback to that if needed
  - name: DEVENV_DEVSPACE_BIN
    source: env
    default: devspace
  # kind bin for loading images into local dev-environment
  # this var is passed in only when deploying to local dev-environment
  - name: DEVENV_KIND_BIN
    source: env

  # This var isn't produced by devenv, but can be produced by user scripts to override the namespace.
  - name: DEVENV_DEPLOY_NAMESPACE
    source: env
    default: ${DEVENV_DEPLOY_APPNAME}--bento1a

  - name: GH_TOKEN
    source: command
    command: yq -r '.["github.com"].oauth_token' "$HOME/.config/gh/hosts.yml"
  - name: NPM_TOKEN
    source: command
    command: grep -E "registry.npmjs.org(.+)_authToken=(.+)" $HOME/.npmrc | sed 's/.*=//g'
  - name: APP_VERSION
    source: command
    command: make version
  - name: BOX_REPOSITORY_URL
    source: command
    command: yq -r '.storageURL' "$HOME/.outreach/.config/box/box.yaml"

  - name: DLV_PORT
    value: 42097
  - name: DEV_CONTAINER_WORKDIR
    value: /home/dev/app
  - name: DEV_CONTAINER_IMAGE
    value: gcr.io/outreach-docker/bootstrap/dev:stable
  - name: DEV_CONTAINER_LOGFILE
    value: /tmp/app.log
  - name: DEV_CONTAINER_CACHE
    value: /tmp/cache

images:
  app:
    image: ${DEVENV_DEPLOY_IMAGE_REGISTRY}/${DEVENV_DEPLOY_APPNAME}
    dockerfile: deployments/${DEVENV_DEPLOY_APPNAME}/Dockerfile
    context: ./
    createPullSecret: true
    build:
      buildKit:
        args:
          - "--ssh"
          - default
          - "--build-arg"
          - VERSION=${APP_VERSION}
        inCluster:
          namespace: ${DEVENV_DEPLOY_NAMESPACE}

# `deployments` tells DevSpace how to deploy this project
deployments:
  - name: app
    namespace: ${DEVENV_DEPLOY_NAMESPACE}
    # This deployment uses `kubectl` but you can also define `helm` deployments
    kubectl:
      manifests:
        - deployments/${DEVENV_DEPLOY_APPNAME}.yaml

# `dev` only applies when you run `devspace dev`
dev:
  # `dev.ports` specifies all ports that should be forwarded while `devspace dev` is running
  # Port-forwarding lets you access your application via localhost on your local machine
  ports:
    - name: app
      labelSelector: ${DEVENV_DEPLOY_LABELS}
      namespace: ${DEVENV_DEPLOY_NAMESPACE}
      forward:
        - port: 8000
{{- if (has "grpc" (stencil.Arg "serviceActivities")) }}
        - port: 5000
{{- end }}
{{- if (has "http" (stencil.Arg "serviceActivities")) }}
        - port: 8080
{{- end }}
        # Remote debugging port
        - port: ${DLV_PORT}

  # `dev.sync` configures a file sync between our Pods in k8s and your local project files
  sync:
    - name: app
      labelSelector: ${DEVENV_DEPLOY_LABELS}
      namespace: ${DEVENV_DEPLOY_NAMESPACE}
      localSubPath: ./
      containerPath: ${DEV_CONTAINER_WORKDIR}
      waitInitialSync: true
      excludePaths:
        - bin
        - ./vendor
        - node_modules
        {{- if (has "node" (stencil.Arg "grpcClients")) }}
        - api/clients/node/node_modules/
        {{- end }}
    {{- range (stencil.GetModuleHook "devspace.sync") }}
    - name: {{ .name }}
      labelSelector: {{ .labelSelector }}
      namespace: {{ .namespace }}
      localSubPath: {{ .localSubPath }}
      containerPath: {{ .containerPath }}
      waitInitialSync: true
      {{- if .excludePaths }}
      excludePaths:
{{ toYaml .excludePaths | indent 8 }}
      {{- end }}
    {{- end }}

  # Since our Helm charts and manifests deployments are often optimized for production,
  # DevSpace let's you swap out Pods dynamically to get a better dev environment
  replacePods:
    - name: app
      labelSelector: ${DEVENV_DEPLOY_LABELS}
      namespace: ${DEVENV_DEPLOY_NAMESPACE}
      replaceImage: ${DEV_CONTAINER_IMAGE}
      patches:
        - op: replace
          path: spec.containers[0].command
          value:
            - bash
        - op: replace
          path: spec.containers[0].args
          value:
            - "-c"
            - "while ! tail -f ${DEV_CONTAINER_LOGFILE} 2> /dev/null; do sleep 1; done"
        - op: replace
          path: spec.containers[0].imagePullPolicy
          value: Always
        - op: remove
          path: spec.containers[0].securityContext
        - op: remove
          path: spec.containers[0].resources
        - op: remove
          path: spec.containers[0].livenessProbe
        - op: remove
          path: spec.containers[0].readinessProbe

        # credentials for package managers
        - op: add
          path: spec.containers[0].env
          value:
            name: GH_TOKEN
            value: ${GH_TOKEN}
        - op: add
          path: spec.containers[0].env
          value:
            name: NPM_TOKEN
            value: ${NPM_TOKEN}

        # variables for scripts
        - op: add
          path: spec.containers[0].env
          value:
            name: DEVENV_DEV_TERMINAL
            value: "$!{DEVENV_DEV_TERMINAL}"
        - op: add
          path: spec.containers[0].env
          value:
            name: DEV_CONTAINER_LOGFILE
            value: ${DEV_CONTAINER_LOGFILE}
        - op: add
          path: spec.containers[0].env
          value:
            name: SKIP_DEVCONFIG
            value: "true"
        - op: add
          path: spec.containers[0].env
          value:
            name: DLV_PORT
            value: "$!{DLV_PORT}"
        - op: add
          path: spec.containers[0].env
          value:
            name: DEV_CONTAINER_EXECUTABLE
            value: ${DEV_CONTAINER_EXECUTABLE}
        - op: add
          path: spec.containers[0].env
          value:
            name: BOX_REPOSITORY_URL
            value: ${BOX_REPOSITORY_URL}

        # Package caching
        - op: add
          path: spec.volumes
          value:
            name: pkgcache
            persistentVolumeClaim:
              claimName: pkgcache
        - op: add
          path: spec.containers[0].volumeMounts
          value:
            mountPath: ${DEV_CONTAINER_CACHE}
            name: pkgcache

        - op: add
          path: spec.containers[0].env
          value:
            name: GOCACHE
            value: ${DEV_CONTAINER_CACHE}/go/build
        - op: add
          path: spec.containers[0].env
          value:
            name: GOMODCACHE
            value: ${DEV_CONTAINER_CACHE}/go/mod

        # Lint caching
        - op: add
          path: spec.containers[0].env
          value:
            name: GOLANGCI_LINT_CACHE
            value: ${DEV_CONTAINER_CACHE}/golangci-lint

        # Storage for sources - this way we don't have to sync everything every time, makes startup faster
        - op: add
          path: spec.volumes
          value:
            name: appcache
            persistentVolumeClaim:
              claimName: appcache
        - op: add
          path: spec.containers[0].volumeMounts
          value:
            mountPath: ${DEV_CONTAINER_WORKDIR}
            name: appcache

commands:
  - name: build-jsonnet
    # The image tags get replaced by devspace automatically.
    command: ./scripts/shell-wrapper.sh build-jsonnet.sh show > deployments/${DEVENV_DEPLOY_APPNAME}.yaml

hooks:
  - name: render-manifests
    command: "${DEVENV_DEVSPACE_BIN} run build-jsonnet"
    events: ["before:deploy"]
  - name: delete-jobs
    command: |-
      "$DEVENV_BIN" --skip-update k --namespace "${DEVENV_DEPLOY_NAMESPACE}" delete jobs --all
    events: ["before:deploy"]
  - name: auth-refresh
    command: "${DEVENV_BIN} --skip-update auth refresh"
    events: ["before:build"]

profiles:
  - name: devTerminal
    description: dev command opens a terminal into dev container. Automatically activated based on $DEVENV_DEV_TERMINAL == true var.
    activation:
      - vars:
          DEVENV_DEV_TERMINAL: "true"
    patches:
      - op: add
        path: hooks
        value:
          name: reset-dev
          events: ["devCommand:after:execute"]
          command: |-
            "${DEVENV_DEVSPACE_BIN}" reset pods -s
    merge:
      dev:
        terminal:
          labelSelector: ${DEVENV_DEPLOY_LABELS}
          namespace: ${DEVENV_DEPLOY_NAMESPACE}
          workDir: ${DEV_CONTAINER_WORKDIR}
          command:
            - ./scripts/shell-wrapper.sh devspace_start.sh

  - name: devStartService
    description: dev command starts service in dev container. Automatically activated based on $DEVENV_DEV_TERMINAL == false var.
    activation:
      - vars:
          DEVENV_DEV_TERMINAL: "false"
    patches:
      - op: add
        path: hooks
        value:
          name: reset-dev-interrupt
          events: ["devCommand:interrupt"]
          command: |-
            "${DEVENV_DEVSPACE_BIN}" reset pods -s
      - op: add
        path: hooks
        value:
          name: reset-dev-error
          events: ["error:sync:app"]
          command: |-
            "${DEVENV_DEVSPACE_BIN}" reset pods -s
      - op: add
        path: hooks
        value:
          name: make-dev
          events: ["after:initialSync:app"]
          command: |-
            cd "${DEV_CONTAINER_WORKDIR}"
            "${DEV_CONTAINER_WORKDIR}/scripts/shell-wrapper.sh" devspace_start.sh
          container:
            labelSelector: ${DEVENV_DEPLOY_LABELS}

  - name: remoteAppImages
    description: Use app images built in CI. Automatically activated based on $DEVENV_DEPLOY_IMAGE_SOURCE == remote var.
    activation:
      - vars:
          DEVENV_DEPLOY_IMAGE_SOURCE: remote
    patches:
      - op: replace
        path: images.app.build.disabled
        value: true
      - op: replace
        path: deployments[0].kubectl.replaceImageTags
        value: false

  - name: KiND
    description: Enables deploying to KiND dev-environment. Automatically activated based on $DEVENV_TYPE var.
    activation:
      - vars:
          DEVENV_TYPE: kind
    patches:
      - op: replace
        path: images.app.build.buildKit.skipPush
        value: true
      - op: remove
        path: images.app.build.buildKit.inCluster
      - op: add
        path: hooks
        value:
          name: kind-load-image
          command: "${DEVENV_KIND_BIN} load docker-image --name dev-environment ${runtime.images.app}"
          events: ["after:build:app"]

  - name: Loft
    description: Enables deploying to loft dev-environment. Automatically activated based on $DEVENV_TYPE var.
    activation:
      - vars:
          DEVENV_TYPE: loft
    patches:
      - op: add
        path: dev.replacePods.name=app.patches
        value:
          op: add
          path: spec.containers[0].nodeSelector
          value:
            cloud.google.com/gke-nodepool: devspace
      - op: add
        path: dev.replacePods.name=app.patches
        value:
          op: add
          path: spec.tolerations
          value:
            - key: "devspace"
              operator: "Equal"
              value: "true"
              effect: "NoSchedule"
      - op: add
        path: dev.replacePods.name=app.patches
        value:
          op: add
          path: spec.securityContext
          value:
            runAsUser: 1000
            fsGroup: 1000
            runAsGroup: 1000

  - name: skipPortForwarding
    activation:
      - vars:
          DEVENV_DEV_SKIP_PORTFORWARDING: "true"
    patches:
      - op: remove
        path: dev.ports

  - name: e2e
    activation:
      - env:
          E2E: "true"
    patches:
      - op: add
        path: dev.replacePods.name=app.patches
        value:
          op: replace
          path: spec.serviceAccountName
          value: "{{ .Config.Name }}-e2e-client-svc"
      - op: add
        path: dev.replacePods.name=app.patches
        value:
          op: add
          path: spec.containers[0].env
          value:
            name: E2E
            value: "true"

  # App Profiles
  # Profiles starting with deployment__ are treated specially by devenv.
  # You get to choose from them which app you want to substitute with the dev container.
  - name: deployment__{{ .Config.Name }}
    description: Default app profile. This doesn't change configuration, because it's set by default.
    activation:
      - vars:
          DEVENV_DEV_DEPLOYMENT_PROFILE: deployment__{{ .Config.Name }}

{{- range (stencil.GetModuleHook "devspace.profiles") }}
  - name: {{ .name }}
    {{- if .description }}
    description: {{ .description }}
    {{- end }}
    activation:
      {{- if .activation }}
{{ toYaml .activation | indent 6 }}
      {{- end }}
    {{- if .patches }}
    patches:
{{ toYaml .patches | indent 6 }}
    {{- end }}
{{- end }}

  ## <<Stencil::Block(profiles)>>
{{ file.Block "profiles" }}
  ## <</Stencil::Block>>
