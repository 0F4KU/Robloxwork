# Sell a car

Roblox vehicle project. Scripts are stored as text files and synced to Roblox Studio with [Rojo](https://rojo.space).

## Setup (once per machine)

1. Install [Git](https://git-scm.com) and [Rokit](https://github.com/rojo-rbx/rokit).
2. Clone the repo and run `rokit install` in its folder. This installs the Rojo version pinned in `rokit.toml`.
3. Install the Rojo plugin in Roblox Studio.

## Working on the project

1. Open the shared **Sell a car** place in Studio (Team Create).
2. Run `rojo serve`, then click **Connect** in the Rojo plugin in Studio.
3. Edit files in `src/` in VS Code. Changes sync to Studio automatically.
4. Commit only text files. Do not commit `.rbxl` files (they are ignored).

## Layout

```
src/
  server/
    vehicles/CarController.server.luau   -> Workspace.Car.CarController
```

## Limitations

- The car geometry (chassis, cabin, wheels, seat) is **not** in this repo. It lives only in the Studio place. Rojo is configured with `$ignoreUnknownInstances`, so it will not delete it.
- The car controller has not been playtested yet.
