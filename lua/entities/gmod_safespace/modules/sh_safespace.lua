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

-- Doors networks a copy of the doorway to the client by itself, so this override exists for the one
-- reason that copy is not enough: ours is user-resizable from 50 to 5000 a side, and a value sent
-- once at player init would be wrong the moment it changed. Answer from the live dimensions instead.
---@return doors_portal_side
function ENT:GetDoorway()
    return self:GetPortalDimensions()
end
