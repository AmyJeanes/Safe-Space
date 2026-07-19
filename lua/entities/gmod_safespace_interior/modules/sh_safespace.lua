-- Safe Space

ENT:AddHook(SERVER and "PreInitialize" or "Initialize","safespace",function(self)
    SafeSpace:MakeInterior(self)
end)

---@return safespace_interior_dimensions
function ENT:GetDimensions()
    return self.dimensions
end

function ENT:GetPortalDimensions()
    return SafeSpace:GetInteriorPortalDimensions(self)
end

function ENT:GetLighting()
    return SafeSpace:GetInteriorLighting(self)
end

-- Doors reads the doorway on the client too, where anything reasoning about the boundary runs, and
-- `Portal` is only filled in server-side. Answering from the live dimensions rather than that stored
-- copy also keeps it right through a resize, which is the whole point of a resizable doorway.
---@return doors_portal_side
function ENT:GetDoorway()
    return self:GetPortalDimensions()
end
