# mise-en-place Commands

`mise` is a development environment manager. Run `mise --help` for the full command reference.

## Common Workflows

### Tools (language runtimes, CLIs)

```bash
mise use node@22          # Install and pin a tool version in mise.toml
mise install              # Install all tools listed in mise.toml
mise ls                   # List installed/active tool versions
mise outdated             # Show outdated tools
mise upgrade              # Upgrade outdated tools
mise uninstall node@20    # Remove an installed version
```

### Tasks

```bash
mise tasks                # List available tasks and their description
mise run <task>           # Run a task
mise watch <task>         # Run a task and re-run on file changes
```

### Environment Variables

```bash
mise set KEY=value        # Set an env var in mise.toml
mise unset KEY            # Remove an env var from mise.toml
mise env                  # Print env vars mise would export
```

### Shell Integration

```bash
mise activate zsh         # Print activation script (add to ~/.zshrc)
mise deactivate           # Disable mise in the current shell session
mise shell node@22        # Set a tool version for the current shell only
```

### Configuration

```bash
mise config               # Show active config files
mise edit                 # Edit mise.toml interactively
mise fmt                  # Format mise.toml
mise trust                # Trust a config file (required before mise runs it)
mise doctor               # Diagnose installation issues
```

## Configuration Files

| File | Scope |
|------|-------|
| `mise.toml` | Project-local (checked in) |
| `~/.config/mise/config.toml` | User global |

## References

- Docs: <https://mise.en.dev>
- `mise <command> --help` for per-command details
