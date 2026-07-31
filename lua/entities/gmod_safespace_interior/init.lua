AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

ENT:AddHook("PlayerInitialize", "interior", function(self)
    net.WriteTable(self.dimensions)
    net.WriteString(self.material)
    net.WriteString(self.surfacetype)
    net.WriteVector(self.mins)
    net.WriteVector(self.maxs)
end)

function ENT:Initialize()
    self.dimensions=SafeSpace:GetInteriorDimensions(self:GetCreator())
    self.Portal=self:GetPortalDimensions()
    self.material = SafeSpace:GetTextureInterior(self:GetCreator())
    self.surfacetype = SafeSpace:GetSurfaceProperty(self:GetCreator())
    self.BaseClass.Initialize(self)
end