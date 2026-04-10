# cc-animator

`cc-animator` is a modular CC: Tweaked animation wall for terminals and multi-monitor setups.
It renders themed real-time effects from `lib/animator/animations/*`, applies palettes from `lib/animator/themes/*`, and manages the control UI from `lib/animator/ui/*`.

## Features

- Modular runtime under `lib/animator`
- Per-animation folders with:
  - `logic.lua`
  - `config.json`
- Theme palette system under `lib/animator/themes/*`
- Modernized control UI with richer status panels, metadata, and an About page
- Built-in UI for animation, theme, layout, and performance control
- GPU-like adaptive rendering and quality scaling for larger monitor walls
- `install.lua` / `update.lua` workflow similar to `cc-atm10-music`
- Optional external disk/shared-storage runtime installs while keeping local launchers on the PC
- First install fetches `manifest.json` from the repo and then installs the listed runtime files

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

- download `manifest.json` first
- validate the manifest and then download the runtime files
- ask whether the runtime should stay local or be stored on a floppy/shared disk path
- keep local launch files on the computer even when the runtime is stored externally
- create `lib/animator/*`
- preserve your local `config.json` if it already exists
- preserve `.animated_monitor_settings`

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

- **Home** — overview, runtime status, and project identity
- **Animate** — select animation modules
- **Themes** — switch color palettes
- **Layout** — arrange multi-monitor walls
- **Settings** — adjust runtime and GPU-style quality scaling
- **About** — view author, credits, and license information

---

## Project structure

```text
animated_monitor.lua        Main launcher
startup.lua                 Startup entry
update.lua                  Update entry
install.lua                 Installer
manifest.json               Update manifest
config.json                 App config
LICENSE                     Attribution license
lib/animator/
    app.lua
    bootstrap.lua
    config.lua
    http.lua
    manifest.lua
    render.lua
    updater.lua
    update.lua
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
- The modular runtime under `lib/animator/*` is the only maintained code path

## License / credit

This project is free to use and edit.
Edited, forked, or inspired versions should continue to mention the author `tsuki_kami_` and preserve credits where practical.
