# cc-animator

`cc-animator` is a modular CC: Tweaked animation wall for terminals and multi-monitor setups.
It renders themed real-time effects from `lib/animator/animations/*`, applies palettes from `lib/animator/themes/*`, and manages the control UI from `lib/animator/ui/*`.

## Features

- Modular runtime under `lib/animator`
- Per-animation folders with:
  - `logic.lua`
  - `config.json`
- Theme palette system under `lib/animator/themes/*`
- Built-in UI for animation, theme, layout, and performance control
- GPU-like adaptive rendering and quality scaling for larger monitor walls
- `install.lua` / `update.lua` workflow similar to `cc-atm10-music`
- Bootstrap install mode: if a remote `manifest.json` is not present yet, the installer generates a local one automatically

---

## Installation

### Requirements

You need:

- **CC: Tweaked** with **HTTP enabled**
- A normal computer or advanced computer
- One or more **advanced monitors** for the full wall mode

### Initial install

Run this on the ComputerCraft computer:

```sh
wget run https://raw.githubusercontent.com/kami-tsuki/cc-animator/master/install.lua
```

The installer will:

- download the runtime files
- create `lib/animator/*`
- preserve your local `config.json` if it already exists
- preserve `.animated_monitor_settings`
- generate a local `manifest.json` automatically if the repo does not have one yet

### Start the animator

After install:

```sh
startup
```

or:

```sh
animated_monitor
```

### Update later

To manually apply updates:

```sh
update
```

---

## Controls

### Keyboard

- `Q` — quit
- `R` — rescan monitors
- `Tab` — cycle selected monitor
- `A` — auto-arrange monitors in a row
- `C` — auto-arrange monitors in a column
- `P` — toggle layout preview
- `X` — reset layout
- Arrow keys — move selected monitor
- `1-0` — quick-switch animations

### UI pages

- **Home** — overview and renderer status
- **Animate** — select animation module
- **Themes** — switch color palettes
- **Layout** — arrange multi-monitor walls
- **Settings** — adjust runtime and GPU-style quality scaling

---

## Project structure

```text
animated_monitor.lua        Main launcher
startup.lua                 Startup entry
update.lua                  Update entry
install.lua                 Installer
manifest.json               Update manifest
config.json                 App config
lib/animator/
    app.lua
    bootstrap.lua
    config.lua
    http.lua
    manifest.lua
    render.lua
    updater.lua
    update_cli.lua
    util.lua
    animations/
        <name>/
            logic.lua
            config.json
    themes/
        *.lua
    ui/
        init.lua
        screens.lua
```

---

## Notes for development

- Add new effects in `lib/animator/animations/<name>/logic.lua`
- Add deep animation tuning in that animation's `config.json`
- Add color sets in `lib/animator/themes/*.lua`
- The original monolithic implementation is preserved as `animated_monitor_legacy.lua`
