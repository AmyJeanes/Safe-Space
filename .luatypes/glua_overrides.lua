---@meta

-- The glua-api-snippets stub for `Entity:EnableCustomCollisions` declares no parameters,
-- but the wiki and runtime accept a boolean toggle. A function-level redeclaration with
-- `duplicate-set-field` doesn't widen the existing signature, so use a field-style
-- override on the Entity class instead.
-- https://wiki.facepunch.com/gmod/Entity:EnableCustomCollisions
---@class Entity
---@field EnableCustomCollisions fun(self: Entity, useCollisions: boolean)

-- `DNumSlider.Label` is the internal `DLabel` panel exposed for callers that want to
-- style the label directly (e.g. `slider.Label:SetDark(true)`). The stub doesn't
-- declare it as a field on DNumSlider.
---@class DNumSlider
---@field Label DLabel

-- The glua-api-snippets stub declares only the 3-arg `table.insert(tbl, position, value)`
-- form, so calls like `table.insert(t, x)` against a narrowly-typed `t` mis-resolve and
-- treat `x` as the position. Add the 2-arg append-only overload.
---@diagnostic disable-next-line: duplicate-set-field
---@overload fun(tbl: table, value: any): integer
---@param tbl table
---@param position integer
---@param value any
---@return integer
function table.insert(tbl, position, value) end
