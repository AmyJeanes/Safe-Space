# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Garry's Mod (Lua) addon shipping a sandbox tool that spawns a "Safe Space" — a bigger-on-the-inside private build area built on top of the [Doors](https://github.com/AmyJeanes/Doors) addon's portal-based interior/exterior pair. The tool is registered under `Construction → Safe Space` and creates a `gmod_safespace` exterior + a `gmod_safespace_interior` interior; the player walks through the exterior's portal and is teleported into the interior, where the world outside is invisible. Sliders in the tool panel adjust frame and interior dimensions; presets are persisted to `data/safespace_presets.txt` via Doors's vendored vON serializer.

Loaded in-place at `garrysmod/addons/Safe-Space/`. No `addon.json` workflow beyond what Steam Workshop ingests, no CI, no build step.

## Architecture

### Loaders

- `lua/autorun/safespace.lua` defines `SafeSpace:LoadFolder(folder, addonly, noprefix)`. It scans `lua/safespace/<folder>/*.lua` and dispatches by realm-prefix (`sh_`, `sv_`, `cl_`). Called for `libraries/libraries`, `libraries`, then root.
- Each entity (`gmod_safespace`, `gmod_safespace_interior`) defines its own `ENT:LoadFolder` with the same shape, scanning `lua/entities/<class>/modules/`.

Both loaders rely on the realm-prefix in the *filename*. The static analyzer (`glua_ls`) recognizes the same convention.

### Entities

`gmod_safespace` extends `gmod_door_exterior` from the Doors addon; `gmod_safespace_interior` extends `gmod_door_interior`. Both classes annotate the inheritance with `---@class … : gmod_door_…` plus a `---@field BaseClass …` so calls like `self.BaseClass.Initialize(self)` and `self.BaseClass.CallHook(self,name,...)` type-check.

The exterior holds `self.dimensions` (computed from convars at spawn time on SERVER, replicated via `net` on the `PlayerInitialize` hook). `SafeSpace:MakeDoor(ent)` builds the procedural exterior frame mesh; `SafeSpace:MakeInterior(ent)` builds the interior box. Both call `SafeSpace:Init(ent)` to bind a single mesh + multi-convex physics from the section list.

### `lua/safespace/`

- `sh_settings.lua` — the `options` table (categories `global`, `exterior`, `interior` with their sliders), `SafeSpace:GetOption(category, option, ply)`, persistence, and `SafeSpace:OpenPresets()` (DFrame with the save/load/new/remove/rename UI). `GetOption` returns a `SafeSpaceOption` (annotated `---@class`) and `error()`s on an unknown key — the failure mode for a typo'd lookup is a clear stack trace, not a silent `false` that crashes downstream on `.value`.
- `sh_surface.lua` — `SafeSpace:AddCustomSurface(displayname, surfaceid, category, icon, categoryicon)` registry. Tool-panel surface picker reads from this.
- `sh_dynamic.lua` — `MakeCube` (procedural cube mesh with per-face UV scaling), `Make*Dimensions`, `Make*PortalDimensions`, `Make*Lighting`, `MakeDoor`, `MakeInterior`. `Init` builds the entity's mesh + multi-convex collisions and (CLIENT) installs the `CustomDrawModel` callback the Doors base entity dispatches into.
- `cl_ghost.lua` — `SafeSpace:CreateGhost()` builds two clientside `ents.CreateClientProp` doppelgangers (no-draw, no physics) that the tool draws via `PostDrawTranslucentRenderables`. Their `GetDimensions`/`GetPortalDimensions`/`GetLighting`/`UpdateModel` closures pull live values from the convars so the preview updates as sliders move.
- `cl_toolmenu.lua` — `SafeSpace:CreateToolMenu(panel)` builds the spawnmenu controls.

### `lua/weapons/gmod_tool/stools/safespace.lua`

The Construction tool. `LeftClick` traces forward and calls `MakeSafeSpace(ply, hitpos, ang)`; `Think` (CLIENT) keeps the ghost preview attached to the player's crosshair and calls `UpdateGhost`. `Holster` removes both ghosts.

## Conventions when adding code

- **Pure Lua syntax only — no GMod-Lua extensions.** No `//` comments, no `continue`, no `!=`, no `&&`/`||`. Use `--`, restructure to an `if … then … end`, `~=`, `and`/`or`. (The analyzer's parser does not understand GLua extensions; the runtime supports `continue` but the static check rejects it.)
- **Realm-prefix filenames.** `sh_`, `sv_`, `cl_` as prefixes — both the loaders and the static analyzer dispatch off the prefix.
- **For `pairs`/`ipairs` loops, drop the variable you don't use.** `for _, v in pairs(t)` discards the key. The `unused` lint is on; underscore-prefix or drop the binding.
- **Avoid local-variable shadowing in DButton callbacks.** The pattern `save.DoClick = function(save) … end` shadows the outer `save` local. Drop the unused parameter (`function() … end`) or rename it (`function(self)`).
- **`SafeSpace:GetOption(...)` is non-nullable.** Pass valid keys or get an `error()` — the contract is "always returns a `SafeSpaceOption`". Don't add `if o then` guards at lookup sites with hardcoded keys; do guard `o.convar` / `o.savedvalue` since those are optional fields populated lazily.

## Tooling

`.luarc.json` configures `glua_ls` / `glua_check` (both on EmmyLua-Analyzer-Rust) with `./.tools/glua-api` (GLua type stubs), `./.luatypes` (project-local glua-api stub overrides), and sibling addons (`../Doors`, `../world-portals`, `../wire`) as workspace libraries.

`ignoreGlobs` excludes `.tools/*.zip` (the API-stubs download archive).

### Optional dependencies via sibling addons

The addon **requires** Doors at runtime (per the README) — `gmod_safespace` extends `gmod_door_exterior`, the preset persistence uses `Doors.von.serialize`/`deserialize`, and the tool path runs through `Doors:SetupOwner`. There is no defensive `if Doors then` guard; if Doors is missing the addon does not work.

For static analysis, `.luarc.json` references the *real* sibling addons rather than carrying hand-written stubs:

- `../Doors` — provides `gmod_door_exterior`, `gmod_door_interior`, `Doors:SetupOwner`, `Doors.von`.
- `../world-portals` — Doors itself depends on this for portal rendering; carrying it on the analyzer side avoids cascading "missing library" warnings from Doors's source.
- `../wire` — Doors's exterior optionally bases on `base_wire_entity` when `WireLib` is present; carrying it avoids the `if WireLib` branch warning in Doors's source.

Workspace.library entries are *analysis sources*, not *diagnostic targets* — Doors's own warnings don't bleed into Safe-Space's output. If a contributor clones Safe-Space without those siblings present, glua_ls warns about missing library paths and base-class lookups go back to `undefined-field`, but the rest of the analysis is unaffected.

There is intentionally **no `diagnostics.disable` block in `.luarc.json`** — every rule earns its keep. Prefer code-level fixes or targeted annotations over global suppression.

### Type annotations

Patterns that matter for this codebase:

- **`---@class SafeSpaceOption`** in `sh_settings.lua` — keys callers care about (`id`, `name`, `min`, `max`, `default`, `value`) are required; `savedvalue`, `convar`, `slider` are optional because they are populated lazily (CLIENT-only `convar` setup, `value` mutates via `GetOption`, `slider` set when the tool panel is built). `GetOption` is annotated `@return SafeSpaceOption` (non-nullable) — see the convention note above.
- **Entity inheritance** — `---@class gmod_safespace : gmod_door_exterior` with an explicit `---@field BaseClass gmod_door_exterior` is needed because GMod sets `self.BaseClass` at runtime when `ENT.Base` is set, but the analyzer doesn't know that. The same pattern applies to `gmod_safespace_interior`.
- **`--[[@as DListView_Line]]` casts** on `presetlist:GetLine(...)` results — see the next section.
- **`trace.HitNormal` is nullable.** The glua-api types `TraceResult.HitNormal` as `Vector?` — at miss/world edge cases it can be nil. Extract to a local and guard rather than asserting with `--[[@as Vector]]`; see the two trace handlers in `lua/weapons/gmod_tool/stools/safespace.lua`.

### `.luatypes/glua_overrides.lua` — genuine glua-api stub fixes

Reserved for *real* gaps in the glua-api-snippets stubs. Things specific to Safe-Space code (project-local globals, etc.) belong with the code that uses them, not in this layer. Current contents:

- `Entity:EnableCustomCollisions(useCollisions)` — wiki documents a boolean parameter; the stub declares 0 args. Field-style override on `Entity` widens the signature.
- `DNumSlider.Label` — internal `DLabel` panel exposed by the runtime for callers that want to style the label directly. Not declared in the stub.

`DListView:GetLine` / `AddLine` / `GetSelectedLine` are typed `@return Panel` in the stub instead of `@return DListView_Line`. That makes `line:GetValue(1)` resolve to `Panel:GetValue()` (0-arg) and produce a spurious `redundant-parameter` warning. Neither field-style nor function-redeclaration overrides take precedence over the stub at the analyzer's lookup level, so the workaround is `--[[@as DListView_Line]]` casts at the two call sites in `sh_settings.lua` (the `OpenPresets` remove/rename buttons).

### Claude Code LSP integration (`glua-lsp` plugin)

Diagnostics, hover, and jump-to-definition are provided via the [`glua-lsp` plugin](https://github.com/AmyJeanes/gmod-claude-plugins) (marketplace: `AmyJeanes/gmod-claude-plugins`). The plugin wraps the [`glua_ls`](https://github.com/Pollux12/gmod-glua-ls) language server — same EmmyLua-Analyzer-Rust engine as `glua_check`, just running long-lived. Diagnostics arrive automatically after every edit; no hook involvement.

`.claude/settings.json` declares `extraKnownMarketplaces` so contributors get prompted to install the plugin on first open. The plugin itself ships only configuration — two per-machine pieces are still needed and are not in source control.

#### First-time setup (do this before doing other work)

If you (Claude) are operating in a fresh clone, **check both of these and install whichever is missing before touching `.lua` files**, otherwise diagnostics will be either absent or full of noise:

1. **`glua_ls` binary on PATH**
   ```bash
   glua_ls --version
   ```
   If missing → `cargo install glua_ls` (binary lands at `~/.cargo/bin/glua_ls`).

2. **GLua API stubs at `.tools/glua-api/`** — referenced by `.luarc.json` under `workspace.library`. Without them every GMod global (`IsValid`, `hook`, `ents`, `Color`, `LocalPlayer`, …) shows as `undefined-global`. `.tools/` is gitignored.
   ```bash
   ls .tools/glua-api/_globals.lua   # check
   ```
   If missing:
   ```bash
   mkdir -p .tools/glua-api
   url=$(gh api repos/luttje/glua-api-snippets/releases/latest \
       --jq '.assets[] | select(.name | endswith(".lua.zip")) | .browser_download_url')
   curl -sL -o .tools/glua-api.zip "$url"
   unzip -q -o .tools/glua-api.zip -d .tools/glua-api/
   ```

After installing either piece, ask the user to run `/reload-plugins` so Claude Code re-spawns the LSP.

The `glua-lsp:install-glua-ls` skill (auto-loaded with the plugin) covers the same recovery flow if symptoms appear later.

#### Workspace-wide scans with `glua_check`

`glua_ls` only analyzes files as they are opened/edited. To audit the whole repo at once:

```bash
glua_check .
```

Run from the project root. The `.` is required (no-arg fails on Windows), and the working directory must be the Safe-Space root so `.luarc.json`'s relative paths resolve.
