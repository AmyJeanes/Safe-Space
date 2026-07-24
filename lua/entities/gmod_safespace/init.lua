AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

ENT:AddHook("PlayerInitialize", "interior", function(self)
    net.WriteTable(self.dimensions)
    net.WriteString(self.material)
    net.WriteString(self.surfacetype)
end)

function ENT:Initialize()
    self.dimensions=SafeSpace:GetExteriorDimensions(self:GetCreator())
    self.Portal=self:GetPortalDimensions()
    self.material = SafeSpace:GetTextureExterior(self:GetCreator())
    self.surfacetype = SafeSpace:GetSurfaceProperty(self:GetCreator())
    -- glua_ls 1.1.1: a base method defined with `:` has no declared self, so the analyzer
    -- infers its type from what we pass and flags its own guess. Declaring ours doesn't help.
    ---@diagnostic disable-next-line: infer-unknown
    self.BaseClass.Initialize(self)
end
