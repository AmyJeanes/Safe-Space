-- Ghost

local model = "models/props_junk/PopCan01a.mdl"
function SafeSpace:CreateGhost()
    util.PrecacheModel(model)
    local exterior = ents.CreateClientProp(model)
    exterior:SetNoDraw(true)
    exterior.GetDimensions = function(ent)
        return {
            width = self:GetOption("exterior","width").value,
            height = self:GetOption("exterior","height").value,
            size = self:GetOption("global","size").value,
            texscale = self:GetOption("global","texscale").value
        }
    end
    exterior.GetLighting = function(ent)
        return self:GetExteriorLighting(ent)
    end
    exterior.GetPortalDimensions = function(ent)
        return self:GetExteriorPortalDimensions(ent)
    end
    exterior.UpdateModel = function(ent)
        self:MakeDoor(ent)
    end
    exterior:UpdateModel()
    
    self.GhostExterior = exterior
    
    local interior = ents.CreateClientProp(model)
    exterior.interior = interior
    interior.exterior = exterior
    interior:SetParent(exterior)
    interior:SetNoDraw(true)
    interior.GetDimensions = function(ent)
        return {
            width = self:GetOption("interior","width").value,
            height = self:GetOption("interior","height").value,
            length = self:GetOption("interior","length").value,
            size = self:GetOption("global","size").value
        }
    end
    interior.GetPortalDimensions = function(ent)
        return self:GetInteriorPortalDimensions(ent)
    end
    interior.GetLighting = function(ent)
        return self:GetInteriorLighting(ent)
    end
    interior.UpdateModel = function(ent)
        self:MakeInterior(ent)
    end
    interior:UpdateModel()
    
    self.GhostInterior = interior
    
    return exterior, interior
end