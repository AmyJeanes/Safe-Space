-- Ghost

local model = "models/props_junk/PopCan01a.mdl"
function SafeSpace:CreateGhost()
    util.PrecacheModel(model)
    local exterior = ents.CreateClientProp(model) --[[@as gmod_safespace]]
    exterior:SetNoDraw(true)
    ---@param ent gmod_safespace
    exterior.GetDimensions = function(ent)
        return {
            width = self:GetOption("exterior","width").value,
            height = self:GetOption("exterior","height").value,
            size = self:GetOption("global","size").value,
            texscale = self:GetOption("global","texscale").value
        }
    end
    ---@param ent gmod_safespace
    exterior.GetLighting = function(ent)
        return self:GetExteriorLighting(ent)
    end
    ---@param ent gmod_safespace
    exterior.GetPortalDimensions = function(ent)
        return self:GetExteriorPortalDimensions(ent)
    end
    ---@param ent Entity
    exterior.UpdateModel = function(ent)
        self:MakeDoor(ent --[[@as gmod_safespace]])
    end
    exterior:UpdateModel()
    
    self.GhostExterior = exterior
    
    local interior = ents.CreateClientProp(model) --[[@as gmod_safespace_interior]]
    exterior.interior = interior
    interior.exterior = exterior
    interior:SetParent(exterior)
    interior:SetNoDraw(true)
    ---@param ent gmod_safespace_interior
    interior.GetDimensions = function(ent)
        return {
            width = self:GetOption("interior","width").value,
            height = self:GetOption("interior","height").value,
            length = self:GetOption("interior","length").value,
            size = self:GetOption("global","size").value
        }
    end
    ---@param ent gmod_safespace_interior
    interior.GetPortalDimensions = function(ent)
        return self:GetInteriorPortalDimensions(ent)
    end
    ---@param ent gmod_safespace_interior
    interior.GetLighting = function(ent)
        return self:GetInteriorLighting(ent)
    end
    ---@param ent Entity
    interior.UpdateModel = function(ent)
        self:MakeInterior(ent --[[@as gmod_safespace_interior]])
    end
    interior:UpdateModel()
    
    self.GhostInterior = interior
    
    return exterior, interior
end