{{- $_ := stencil.ApplyTemplate "skipIfNotService" -}}
# Config file for [Air](https://github.com/cosmtrek/air) in TOML format

# Working directory
# . or absolute path, please note that the directories following must be under root.
root = "."

[build]
# Just plain old shell command. You could use `make` as well.
cmd = "make devspace"

# Binary file yields from `cmd`.
bin = ".bootstrap/shell/air-runner.sh"

# Watch these filename extensions.
include_ext = ["go", "tpl", "tmpl", "html"]

# Ignore these filename extensions or directories.
exclude_dir = ["api", "node_modules", "vendor"]

# do not exclude anything (also tests, as by default)
exclude_regex = []

# Watch these directories if you specified.
include_dir = []

# Exclude unchanged files.
exclude_unchanged = true

# It's not necessary to trigger build each time file changes if it's too frequent.
delay = 1000 # ms

# Stop running old binary when build errors occur.
stop_on_error = true
# Send Interrupt signal before killing process (windows does not support this feature)
send_interrupt = true

[color]
# Customize each part's color. If no color found, use the raw app log.
main = "magenta"
watcher = "cyan"
build = "yellow"
runner = "green"
