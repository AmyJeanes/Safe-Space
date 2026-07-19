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

-- Doors networks a copy of the doorway to the client by itself, so this override exists for the one
-- reason that copy is not enough: ours is user-resizable from 50 to 5000 a side, and a value sent
-- once at player init would be wrong the moment it changed. Answer from the live dimensions instead.
---@return doors_portal_side
function ENT:GetDoorway()
    return self:GetPortalDimensions()
end
