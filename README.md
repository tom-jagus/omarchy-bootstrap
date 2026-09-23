# Omarchy bootstrap

Personal post-install setup for a fresh Omarchy machine. Installs selected apps and packages, configures desktop defaults and webapps, sets up shell plugins, and applies Hyprland dotfiles.

## Install

Run as your regular user in an interactive Omarchy Hyprland session:

```bash
git clone https://github.com/tom-jagus/omarchy-bootstrap.git ~/src/personal/omarchy-bootstrap
cd ~/src/personal/omarchy-bootstrap
./setup.sh
```

Edit the files in `config/` before running the setup if you want different selections. The setup may prompt for sudo, dictation setup, and removals. Log out and back in when it finishes.

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

`setup.sh` is intended for a fresh installation, not for ongoing configuration synchronization.
