-- Safe Space

TOOL.Category = "Construction"
TOOL.Name = "Safe Space"

cleanup.Register( "safespace" )

if CLIENT then
    language.Add("tool.safespace.name", "Safe Space")
    language.Add("tool.safespace.desc", "Create your own private areas")
    language.Add("tool.safespace.0", "Left click to create a Safe Space")
    language.Add("Undone_safespaces", "Undone Safe Space")
    language.Add("Cleanup_safespaces", "Safe Spaces")
    language.Add("SBoxLimit_safespaces", "You've hit Safe Spaces limit!")
end

---@param trace TraceResult
function TOOL:LeftClick( trace )
    if IsValid(trace.Entity) and trace.Entity:IsPlayer() then return false end
    if CLIENT then return true end
    local ang
    if self:GetOwner():KeyDown(IN_WALK) then
        ang=Angle(0, (self:GetOwner():GetPos()-trace.HitPos):Angle().y, 0)
    else
        local hitNormal = trace.HitNormal
        if not hitNormal then return false end
        ang = hitNormal:Angle()
        ang.pitch = ang.pitch + 90
    end
    local ent = MakeSafeSpace(self:GetOwner(),trace.HitPos,ang)
    if not IsValid(ent) then return false end
    return true
end

if SERVER then
    CreateConVar("sbox_maxsafespaces",5)
    ---@param ply Player
    ---@param pos Vector
    ---@param ang Angle
    function MakeSafeSpace(ply,pos,ang)
        if IsValid(ply) and (not ply:CheckLimit("safespaces")) then return false end
    
        local ent = ents.Create("gmod_safespace")
        if not IsValid(ent) then return false end
        
        ent:SetPos(pos)
        ent:SetAngles(ang)
        Doors:SetupOwner(ent,ply)
        ent:Spawn()
        ent:Activate()
        
        if IsValid(ply) then
            ply:AddCount("safespaces", ent)
            undo.Create("safespaces")
                undo.AddEntity(ent)
                undo.SetPlayer(ply)
            undo.Finish()
        end

        return ent
    end
    --duplicator.RegisterEntityClass( "gmod_safespace", MakeSafeSpace, "Model", "Ang", "Pos", "key", "description", "toggle", "Vel", "aVel", "frozen" )
else
    function TOOL:MakeGhostEntity()
        self.GhostExterior,self.GhostInterior = SafeSpace:CreateGhost()
    end
    
    hook.Add("PostDrawTranslucentRenderables","safespace-ghost",function()
        if not SafeSpace.showghost then
            SafeSpace.showghost = GetConVar("safespace_showghost")
        end
        if not SafeSpace.showghostint then
            SafeSpace.showghostint = GetConVar("safespace_showghostint")
        end
        local ext = SafeSpace.GhostExterior
        local int = SafeSpace.GhostInterior
        if IsValid(ext) and IsValid(int) and ext.shoulddraw then
            --[[
            cam.Start2D()
                draw.DrawText(tostring(ext:GetPos()),"DermaLarge",ScrW(),0,Color(255,255,255),TEXT_ALIGN_RIGHT)
                draw.DrawText(tostring(int:GetPos()),"DermaLarge",ScrW(),50,Color(255,255,255),TEXT_ALIGN_RIGHT)
            cam.End2D()
            ]]--
            if SafeSpace.showghost:GetBool() then
                ext:CustomDrawModel(true)
                if SafeSpace.showghostint:GetBool() then
                    int:CustomDrawModel(true)
                end
            end
        end
    end)
    
    ---@param ent Entity
    ---@param ply Player
    function TOOL:UpdateGhost( ent, ply )
        if not IsValid(ent) then return end

        local tr = util.GetPlayerTrace(ply)
        local trace = util.TraceLine(tr)
        if not trace.Hit then return end
        
        if IsValid(trace.Entity) and (trace.Entity:IsPlayer()) then
            ent.shoulddraw = false
            return
        end
        
        ent:SetPos(trace.HitPos)
        
        local ang
        if LocalPlayer():KeyDown(IN_WALK) then
            ang=Angle(0, (self:GetOwner():GetPos()-trace.HitPos):Angle().y, 0)
        else
            local hitNormal = trace.HitNormal
            if not hitNormal then return end
            ang = hitNormal:Angle()
            ang.pitch = ang.pitch + 90
        end
        ent:SetAngles(ang)
        
        if not ent.shoulddraw then
            ent.shoulddraw = true
        end
    end

    function TOOL:Think()
        if not (IsValid(self.GhostExterior) or IsValid(self.GhostInterior)) then
            self:MakeGhostEntity()
        end
        self:UpdateGhost( self.GhostExterior, self:GetOwner() )
    end
    
    function TOOL:Holster()
        if IsValid(self.GhostExterior) then
            self.GhostExterior:Remove()
            self.GhostExterior = nil
        end
        if IsValid(self.GhostInterior) then
            self.GhostInterior:Remove()
            self.GhostInterior = nil
        end
    end

    ---@param panel Panel
    function TOOL.BuildCPanel(panel)
        SafeSpace:CreateToolMenu(panel)
    end
end