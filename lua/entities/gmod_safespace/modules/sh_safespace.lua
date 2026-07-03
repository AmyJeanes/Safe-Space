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