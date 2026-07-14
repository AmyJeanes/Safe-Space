# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Garry's Mod (Lua) addon shipping a sandbox tool that spawns a "Safe Space" — a bigger-on-the-inside private build area built on top of the [Doors](https://github.com/AmyJeanes/Doors) addon's portal-based interior/exterior pair. The tool is registered under `Construction → Safe Space` and creates a `gmod_safespace` exterior + a `gmod_safespace_interior` interior; the player walks through the exterior's portal and is teleported into the interior, where the world outside is invisible. Sliders in the tool panel adjust frame and interior dimensions; presets are persisted to `data/safespace_presets.txt` via Doors's vendored vON serializer.

Loaded in-place at `garrysmod/addons/Safe-Space/`; GMod loads `lua/` at server start, no build step. CI runs GLua Check + typing checks on push/PR, and a full GitHub release publishes the addon to its Steam Workshop item - see [Build / publish](#build--publish).

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

## Build / publish

No local build step - GMod loads `lua/` in place. CI runs GLua Check + typing check on push/PR and publishes the addon to its Steam Workshop item via the shared `gmod-addon-tools/publish-workshop.yml` reusable workflow:

- **Stable (`210294043`)** - publishing a full GitHub **release** fires `release.yml`, which publishes behind a phone-gated Steam Guard prompt (`mfa: true`). A **bare tag ships nothing** (the trigger is `release: published`, not the tag) - cut a release to publish.

Unlike the base addons, Safe Space has **no beta channel**: a push to `main` runs the checks but never publishes. Only a GitHub release ships to the Workshop.

**Change notes.** The Steam note is composed from the release body: the **first paragraph** of a `## Summary` section becomes the note (Steam is BBCode, not Markdown - keep it plain prose), under an automatic version link. Draft releases from `RELEASE_TEMPLATE.md`.

Test without shipping via `release.yml`'s `workflow_dispatch`: `dry_run: true` (real pack + Steam login, skip upload) or `tag: <version>` (preview - log the composed note only, no login). Note `dry_run` still fires the phone (the Steam Guard step gates on `mfa`, not `dry_run`); use `tag:` for a phone-free note preview.

## Conventions when adding code

- **Realm-prefix filenames.** `sh_`, `sv_`, `cl_` as prefixes — both the loaders and the static analyzer dispatch off the prefix.
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

The `.luarc.json` carries **no `diagnostics.disable` block** — every rule earns its keep. When a rule looks like it's misfiring, prefer a code-level fix or a targeted annotation over disabling. The one historical exception (`undefined-field` flooding on the variant-shape table `ENT:GetDimensions()` returns) is now solved with named dimension classes and a cast — see the Type annotations section.

### Type annotations

Patterns that matter for this codebase:

- **`---@class SafeSpaceOption`** in `sh_settings.lua` — keys callers care about (`id`, `name`, `min`, `max`, `default`, `value`) are required; `savedvalue`, `convar`, `slider` are optional because they are populated lazily (CLIENT-only `convar` setup, `value` mutates via `GetOption`, `slider` set when the tool panel is built). `GetOption` is annotated `@return SafeSpaceOption` (non-nullable) — see the convention note above.
- **Entity inheritance** — `---@class gmod_safespace : gmod_door_exterior` with an explicit `---@field BaseClass gmod_door_exterior` is needed because GMod sets `self.BaseClass` at runtime when `ENT.Base` is set, but the analyzer doesn't know that. The same pattern applies to `gmod_safespace_interior`.
- **Dimension shapes** — `ENT:GetDimensions()` returns one of two variant shapes: exterior dims (`SafeSpaceExteriorDimensions`: `width`/`height`/`size`/`texscale`) or interior dims (`SafeSpaceInteriorDimensions`: `width`/`height`/`size`/`length`), both extending `SafeSpaceDimensions`. The classes and the `GetExteriorDimensions`/`GetInteriorDimensions` producers are annotated in `sh_dynamic.lua`; each entity's `GetDimensions` carries the matching `@return`. The shared `sh_dynamic.lua` functions take an untyped `ent` (they touch many runtime-only fields like `.exterior`/`.sections`/`.phys` that aren't on the classes — typing `ent` would cascade `undefined-field`), so `MakeInterior` casts its local with `--[[@as SafeSpaceInteriorDimensions]]` to access `dim.length`.
- **`--[[@as DListView_Line]]` casts** on `presetlist:GetLine(...)` results — see the next section.
- **`trace.HitNormal` is nullable.** The glua-api types `TraceResult.HitNormal` as `Vector?` — at miss/world edge cases it can be nil. Extract to a local and guard rather than asserting with `--[[@as Vector]]`; see the two trace handlers in `lua/weapons/gmod_tool/stools/safespace.lua`.

### `.luatypes/glua_overrides.lua` — genuine glua-api stub fixes

Reserved for *real* gaps in the glua-api-snippets stubs. Things specific to Safe-Space code (project-local globals, etc.) belong with the code that uses them, not in this layer. Current contents:

- `Entity:EnableCustomCollisions(useCollisions)` — wiki documents a boolean parameter; the stub declares 0 args. Field-style override on `Entity` widens the signature.
- `DNumSlider.Label` — internal `DLabel` panel exposed by the runtime for callers that want to style the label directly. Not declared in the stub.

`DListView:GetLine` / `AddLine` / `GetSelectedLine` are typed `@return Panel` in the stub instead of `@return DListView_Line`. That makes `line:GetValue(1)` resolve to `Panel:GetValue()` (0-arg) and produce a spurious `redundant-parameter` warning. Neither field-style nor function-redeclaration overrides take precedence over the stub at the analyzer's lookup level, so the workaround is `--[[@as DListView_Line]]` casts at the two call sites in `sh_settings.lua` (the `OpenPresets` remove/rename buttons).

<!-- >>> GENERATED shared conventions (gmod-addon-tools) - do not edit; regen: scripts/generate-claude-md.ps1 >>> -->

_Shared conventions for my GMod addons - generated from [`gmod-addon-tools/docs/gmod-addon-conventions.md`](https://github.com/AmyJeanes/gmod-addon-tools/blob/main/docs/gmod-addon-conventions.md). Edit it there, not in this file; the block below is overwritten by CI. Addon-specific guidance lives outside the markers._

## Code style

- **Pure Lua syntax only - no GMod-Lua extensions.** No `//` comments, no `continue`, no `!=`, no `&&`/`||`. Use `--`, `goto continue`, `~=`, `and`/`or`.
- **Comments: concise, the _why_ not the _what_.** A couple of lines at most; reserve length for genuinely non-obvious rationale and bias toward cutting - match the surrounding density, don't pad to essay length. Don't restate the code, don't explain it by what it replaced, and keep the _why_ self-contained (no pointers to external docs or fragile cross-file references). Keep comments ASCII: `->` not an arrow, a single spaced hyphen for a dash (never a double `--`, which reads as a second comment marker, nor an em-dash).
- **Drop the loop variable you don't use** rather than naming it: `for _, v in pairs(t)`, `for k in pairs(t)`, `for _ = 1, n do`. The `unused` lint is on - keep the noise floor at zero.
- **Every `---@diagnostic disable` needs a paired reason** on the same or preceding line naming _why_ the rule is suppressed. The default is to fix the issue, not suppress it.

## First-time setup (before touching `.lua` files)

The tooling (`glua_check`, `glua_ls`, the GLua API stubs, and the wiki/typing type-model) is provisioned by the shared [`gmod-addon-tools`](https://github.com/AmyJeanes/gmod-addon-tools) module, cloned **beside this addon**. `scripts/install-tools.ps1` is a thin wrapper - `scripts/bootstrap.ps1` resolves the sibling module and it calls `Initialize-GmodTools`, so the version pins live once in the module and every addon runs the exact same engine.

```bash
git clone https://github.com/AmyJeanes/gmod-addon-tools ../gmod-addon-tools
pwsh -File scripts/install-tools.ps1
```

It is idempotent - re-running is a no-op when the pinned versions are already present, so it is also the recovery path when diagnostics look wrong. After a fresh install, run `/reload-plugins` so Claude Code re-launches the LSP against the new binary.

## Claude Code LSP integration (`glua-lsp` plugin)

Diagnostics, hover, and jump-to-definition come from the [`glua-lsp` plugin](https://github.com/AmyJeanes/gmod-claude-plugins) (marketplace `AmyJeanes/gmod-claude-plugins`), which wraps the [`glua_ls`](https://github.com/Pollux12/gmod-glua-ls) server - the same EmmyLua-Analyzer-Rust engine as `glua_check`, running long-lived. Diagnostics arrive automatically after every edit; no hook involvement. `.claude/settings.json` declares the marketplace so contributors get prompted to install on first open, and the plugin auto-resolves `glua_ls` from this project's `.tools/bin/` at launch (no global install, no PATH plumbing). The `glua-lsp:install-glua-ls` skill covers the same recovery flow if symptoms appear later. Treat reported diagnostics as actionable only if your edit caused them - pre-existing noise on unrelated lines is not in scope for the current change.

## Whole-repo scans (`scripts/glua-check.ps1`)

`glua_ls` only analyzes files as they are opened or edited. To audit the whole repo at once, run `pwsh -File scripts/glua-check.ps1` - it provisions tooling on demand (no-op when present) and runs `glua_check --warnings-as-errors` against the workspace root. It takes no path filter, so it always scans everything; CI runs the same script. Useful after a fix ripples across the tree, or when picking the project up to surface latent issues the LSP hasn't opened yet.

## Typing enforcement (`scripts/typing-check.ps1`)

`glua_check` catches _wrong_ types but not _missing_ ones - an untyped param is a silent `any` it never flags. `Test-GmodTyping` (CI: `typing-check.yml`) closes that gap, failing the build on any of: an untyped param, annotation rot (a `---@param` for a param that no longer exists), a modeled function whose resolved return type contains `unknown`, a hook fire-site argument that resolves to `unknown`, or a `:CallHook`-style hook whose receiver resolves to `unknown` (so its "Fired on" column would render _Unknown_ - usually fixed with a `---@param self <class>` on the enclosing function). Satisfy it at the **source** - prefer a `---@param` / `---@return` / `---@class` annotation over a per-callsite `---@cast`, since annotations propagate to every caller. The only accepted escapes are explicit and greppable: `---@param x any` (a reviewed, genuine `any`), an `_` discard for a deliberately-unused arg, and a file-level `---@vendored` marker on third-party code.

Where an addon fires its own hooks, callback payload params are typed by a generated `---@overload` catalogue (`scripts/generate-hook-types.ps1`, CI: `generate-hook-types.yml`) - do not hand-edit it; retype a payload at its `CallHook` / `hook.Run` site instead. Custom global-hook overloads are spliced into the provisioned `hook.lua` by `Initialize-GmodTools`, so after pulling a change to a generated fragment mid-session, re-run `scripts/install-tools.ps1` (it re-syncs) then `/reload-plugins` to refresh live types.

## Bumping the shared tooling

Tool versions and this conventions block are pinned to a `gmod-addon-tools` tag. Bump the version constants in `gmod-addon-tools/src/install.ps1` (or edit the shared docs); merging to the module's `main` auto-cuts a new tag, and Renovate then raises a pin-bump PR here that regenerates the affected artifacts and runs GLua Check before it merges. CI pins the module by tag (the `ref:` in each workflow); a local sibling checkout uses whatever branch it is on, so keep it on the pinned tag to mirror CI exactly.

<!-- <<< END GENERATED shared conventions <<< -->
