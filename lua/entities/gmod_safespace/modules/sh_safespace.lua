-- Safe Space

ENT:AddHook("InteriorReady","safespace",function(self,interior)
    if not IsValid(interior) then
        self:Remove() -- cannot function at all without interior
    end
end)

ENT:AddHook("Initialize","safespace",function(self)
    SafeSpace:MakeDoor(self)
end)

---@return safespace_exterior_dimensions
function ENT:GetDimensions()
    return self.dimensions
end

function ENT:GetPortalDimensions()
    return SafeSpace:GetExteriorPortalDimensions(self)
end

function ENT:GetLighting()
    return SafeSpace:GetExteriorLighting(self)
end

-- Doors reads the doorway on the client too, where anything reasoning about the boundary runs, and
-- `Portal` is only filled in server-side. Answering from the live dimensions rather than that stored
-- copy also keeps it right through a resize, which is the whole point of a resizable doorway.
---@return doors_portal_side
function ENT:GetDoorway()
    return self:GetPortalDimensions()
end
