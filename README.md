# Omarchy bootstrap

Personal post-install setup for a fresh Omarchy 4.5 machine. Installs selected
apps and packages, configures desktop defaults and webapps, sets up shell plugins,
and delegates Hyprland configuration to
[omarchy-hypr-dotfiles](https://github.com/tom-jagus/omarchy-hypr-dotfiles).
The two repositories configure one desktop.

## Install

Run as your regular user in an interactive Omarchy Hyprland session:

```bash
git clone https://github.com/tom-jagus/omarchy-bootstrap.git ~/src/default/omarchy-bootstrap
cd ~/src/default/omarchy-bootstrap
./setup.sh
```

Edit the files in `config/` before running setup if you want different selections.
Run with the standard `~/.config` location and an existing regular
`~/.config/omarchy/shell.json`, not a symlink. Setup may prompt for sudo, dictation
setup, and removals. Log out and back in when it finishes.

## Repository layout

| Path | Contents |
| --- | --- |
| `setup.sh` | Runs the complete setup |
| `config/defaults.json` | Agent, terminal, browser, dictation, and Hyprland dotfiles source |
| `config/packages.json` | Packages to install or remove |
| `config/plugins.json` | Shell plugins to install or remove |
| `config/webapps.json` | Webapps to install or remove |
| `config/shell-overrides.json` | Shell bar layout and enabled plugins |
| `scripts/` | Scripts for each setup step, plus an optional `bootstrap.sh` for a commit-pinned checkout |

`setup.sh` is intended for a fresh installation, not for ongoing configuration
synchronization.

## Hyprland and shell integration

The shell setup installs missing entries from `config/plugins.json` using
`omarchy plugin add <url> --yes`, then applies `config/shell-overrides.json` to
select the bar widgets and enabled plugins. New plugin installs use the source
repository's current HEAD. Existing plugin directories with matching manifest
IDs are left untouched, not updated. Plugins run unsandboxed inside the shell;
only list repositories you trust.

The configured workspace widget is `tomjagus.legacy-workspace-plus`. It replaces
Omarchy 4.5's per-monitor widget to match the dotfiles' global workspace numbers.
Do not restore the stock widget without also reconsidering the Hyprland workspace
configuration.

`scripts/setup-hypr.sh` obtains the dotfiles source and ref from
`config/defaults.json`, clones it into `~/src/default/omarchy-hypr-dotfiles` when
missing, and runs its `setup.sh`. An existing checkout must have the expected
origin and HEAD matching the configured local ref. It is never pulled or reset;
local edits are preserved and used during setup.

The dotfiles installer owns the Hyprland loaders, console override, display
settings, window rules, and shortcuts. It requires stock user templates or an
exact supported generated main config. Existing manual changes or older template
versions need a separate migration. See the
[dotfiles installation instructions](https://github.com/tom-jagus/omarchy-hypr-dotfiles#install)
before re-running setup on a customized machine.

The configured Herdr agent launchers require an existing `~/Work` directory.
Bootstrap creates the source and development directory layout, but not `~/Work`.
Create it with `mkdir -p ~/Work` if it is missing. The dotfiles README describes
the agent sessions, workspace 11 for Proton Pass, and streaming shortcut.
