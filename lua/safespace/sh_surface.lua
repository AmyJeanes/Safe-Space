-- Surface

local custom_surfacetypes = {}
local valid_surfacetypes = {} --a confirmation global list to make sure the client doesn't load in surface types not on the list
---@param displayname string
---@param surfaceid string
---@param category string?
---@param icon string?
---@param categoryicon string?
function SafeSpace:AddCustomSurface(displayname, surfaceid, category, icon, categoryicon)
    if not surfaceid or not displayname then return end

    if util.GetSurfaceIndex( surfaceid )==-1 then 
        print("\n-----------------\nSafe Space: The SurfaceID \""..surfaceid.."\" provided for \""..displayname.."\" is invalid.\n")
        print("For a complete list of valid surfaces, please visit:\n")
        print("https://developer.valvesoftware.com/wiki/Material_surface_properties\n\n-----------------")
        return
    end

    category = category or "Unspecified"

    if not custom_surfacetypes[category] then
        custom_surfacetypes[category] = {}
    end

    custom_surfacetypes[category].icon = categoryicon or custom_surfacetypes[category].icon or ""

    custom_surfacetypes[category][displayname] = {}
    custom_surfacetypes[category][displayname].icon = icon or custom_surfacetypes[category].icon or "" --Set it to the parent icon if not specified
    custom_surfacetypes[category][displayname].real = surfaceid
    table.insert(valid_surfacetypes,surfaceid)
end

function SafeSpace:GetCustomSurfaces()
    return custom_surfacetypes
end

--Surface Reference: https://developer.valvesoftware.com/wiki/Material_surface_properties
--Icon Reference: http://www.famfamfam.com/lab/icons/silk/previews/index_abc.png
--Usage: SafeSpace:AddCustomSurface(string DisplayName, string SurfaceString, string Category, string Icon=parenticon, string CategoryIcon)
--Note: Only need to set category icon once per/each; however individual icons are supported

SafeSpace:AddCustomSurface("Basic Metal","metal","Metals","shape_handles","shape_handles")
--SafeSpace:AddCustomSurface("Alternative Metal","rollermine","Metals") -- doesn't seem to work?
SafeSpace:AddCustomSurface("Metal Barrel","metal_barrel","Metals")
SafeSpace:AddCustomSurface("Chainlink","chainlink","Metals")
SafeSpace:AddCustomSurface("Slippery Metal","slipperymetal","Metals")

SafeSpace:AddCustomSurface("Sticky Walls","ladder","Fun","rainbow","rainbow")
SafeSpace:AddCustomSurface("Ice","ice","Fun")
SafeSpace:AddCustomSurface("Dense Ice","gmod_ice","Fun")
SafeSpace:AddCustomSurface("Think Plastic","item","Fun")
SafeSpace:AddCustomSurface("Snow","snow","Fun")
SafeSpace:AddCustomSurface("Bouncy","metal_bouncy","Fun")

SafeSpace:AddCustomSurface("Brick","brick","Concrete / Rock","lorry","lorry")
SafeSpace:AddCustomSurface("Gravel","gravel","Concrete / Rock")
SafeSpace:AddCustomSurface("Rock","rock","Concrete / Rock")
SafeSpace:AddCustomSurface("Concrete","concrete","Concrete / Rock")

SafeSpace:AddCustomSurface("Water","water","Liquid","anchor","anchor")
SafeSpace:AddCustomSurface("Slime","slime","Liquid")
SafeSpace:AddCustomSurface("Wade","wade","Liquid")

SafeSpace:AddCustomSurface("Dirt","dirt","Nature","world","world")
SafeSpace:AddCustomSurface("Wood","wood","Nature","world","world")
SafeSpace:AddCustomSurface("Grass","grass","Nature")
SafeSpace:AddCustomSurface("Mud","mud","Nature")
SafeSpace:AddCustomSurface("Sand","sand","Nature")

SafeSpace:AddCustomSurface("Paper","paper","Misc","chart_pie","chart_pie")
SafeSpace:AddCustomSurface("Plastic","plastic","Misc")
SafeSpace:AddCustomSurface("Cardboard","cardboard","Misc")
SafeSpace:AddCustomSurface("Glass","glass","Misc")

---@param ply Player
function SafeSpace:GetSurfaceProperty(ply)
    local surfacetype = ply:GetInfo("safespace_global_surface")
    if table.HasValue(valid_surfacetypes,surfacetype) and util.GetSurfaceIndex(surfacetype) ~= -1 then
        return surfacetype
    else
        return "metal"
    end
end