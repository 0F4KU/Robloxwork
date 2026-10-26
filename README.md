# Obby Simplu

Roblox obby with Halloween theme. Scripts are stored as text files and synced to Roblox Studio with [Rojo](https://rojo.space).

## Setup (once per machine)

1. Install [Git](https://git-scm.com) and [Rokit](https://github.com/rojo-rbx/rokit).
2. Clone the repo and run `rokit install` in its folder. This installs the Rojo version pinned in `rokit.toml`.
3. Install the Rojo plugin in Roblox Studio (Rojo's documentation describes the plugin install step).

## Working on the project

1. Open a new empty place in Studio, or the shared place file.
2. Run `rojo serve`, then click **Connect** in the Rojo plugin in Studio.
3. Edit files in `src/` in VS Code. Changes sync to Studio automatically.
4. Commit only text files. Do not commit `.rbxl` files (they are ignored).

## Layout

- `src/server/` → `ServerScriptService` (scripts and the `Feedback` module)
- `src/shared/` → `ReplicatedStorage.Shared`
- `src/client/` → `LocalScript`s inside `StarterGui`

## Limitations

- Map geometry (`Workspace`) and GUI layout (frames, buttons) are **not** in this repo yet. They live only in the `.rbxl` file. Rojo is configured with `$ignoreUnknownInstances`, so it will not delete them.
- The Halloween fences, decor and lava are only in Studio for now.
