-- Dynamic

function SafeSpace:MakeCube(pos,ang,length,width,height,texscale)
    pos=pos or Vector()
    length=length or 1
    width=width or 1
    height=height or 1
    
    -- http://wiki.unity3d.com/index.php/ProceduralPrimitives
    local p0 = Vector(-length*0.5,-width*0.5,height*0.5)+pos
    local p1 = Vector(length*0.5,-width*0.5,height*0.5)+pos
    local p2 = Vector(length*0.5,-width*0.5,-height*0.5)+pos
    local p3 = Vector(-length*0.5,-width*0.5,-height*0.5)+pos
    p0:Rotate(ang)
    p1:Rotate(ang)
    p2:Rotate(ang)
    p3:Rotate(ang)
     
    local p4 = Vector(-length*0.5,width*0.5,height*0.5)+pos
    local p5 = Vector(length*0.5,width*0.5,height*0.5)+pos
    local p6 = Vector(length*0.5,width*0.5,-height*0.5)+pos
    local p7 = Vector(-length*0.5,width*0.5,-height*0.5)+pos
    p4:Rotate(ang)
    p5:Rotate(ang)
    p6:Rotate(ang)
    p7:Rotate(ang)
     
    local vertices = {
        -- Left
        p0, p1, p2,
        p2, p3, p0,
     
        -- Back
        p7, p4, p0,
        p7, p0, p3,
     
        -- Top
        p4, p5, p1,
        p4, p1, p0,
     
        -- Bottom
        p3, p6, p7,
        p3, p2, p6,
     
        -- Front
        p5, p6, p2,
        p5, p2, p1,
     
        -- Right
        p6, p5, p7,
        p5, p4, p7,
    };

    local up = Vector(0,0,1)
    local down = Vector(0,0,-1)
    local front = Vector(1,0,0)
    local back = Vector(-1,0,0)
    local left = Vector(0,-1,0)
    local right = Vector(0,1,0)
     
    local normales = {
        -- Left
        left, left, left, left, left, left,
     
        -- Back
        back, back, back, back, back, back,
     
        -- Top
        up, up, up, up, up, up,
     
        -- Bottom
        down, down, down, down, down, down,
     
        -- Front
        front, front, front, front, front, front,
     
        -- Right
        right, right, right, right, right, right,
    };

    local _00 = {0,0}
    local _10 = {1,0}
    local _01 = {0,1}
    local _11 = {1,1}
     
    local uvs = {
        -- Left
        _10, _00, _01, _01, _11, _10,
     
        -- Back
        _11, _10, _00, _11, _00, _01,
     
        -- Top
        _00, _01, _11, _00, _11, _10,
     
        -- Bottom
        _00, _11, _10, _00, _01, _11, 
     
        -- Front
        _00, _01, _11, _00, _11, _10,
     
        -- Right
        _01, _00, _11, _00, _10, _11,
    }
    
    -- per-face texture-scale dimensions (matches the face order used in `normales`/`uvs`)
    local face_dims = {
        {height, length}, -- Left
        {height, width},  -- Back
        {length, width},  -- Top
        {length, width},  -- Bottom
        {height, width},  -- Front
        {height, length}, -- Right
    }

    -- scale textures correctly
    for i=1,6*6,6 do
        local n=((i-1)/6)+1
        local dims = assert(face_dims[n])
        local hm = dims[1]*(1/texscale)
        local wm = dims[2]*(1/texscale)
        for j=i,i+5 do
            local o=uvs[j]
            local uv = {0,0}
            if o==_10 then
                uv={1*wm,0}
            elseif o==_01 then
                uv={0,1*hm}
            elseif o==_11 then
                uv={1*wm,1*hm}
            end
            uvs[j]=uv
        end
    end

    local verts = {}
    for i=1,6*6 do
        local uv = assert(uvs[i])
        table.insert(verts,{pos = vertices[i], normal = normales[i], u = uv[1], v = uv[2] })
    end
    
    return verts,vertices
end

---@class SafeSpaceDimensions
---@field width number
---@field height number
---@field size number

---@class SafeSpaceExteriorDimensions : SafeSpaceDimensions
---@field texscale number

---@class SafeSpaceInteriorDimensions : SafeSpaceDimensions
---@field length number

---@return SafeSpaceExteriorDimensions
function SafeSpace:GetExteriorDimensions(ply)
    return {
        width = SafeSpace:GetOption("exterior","width",ply).value,
        height = SafeSpace:GetOption("exterior","height",ply).value,
        size = SafeSpace:GetOption("global","size",ply).value,
        texscale = SafeSpace:GetOption("global","texscale",ply).value
    }
end

function SafeSpace:GetExteriorPortalDimensions(ent)
    local dim=ent:GetDimensions()
    return {
        pos = Vector(0,0,dim.height/2),
        ang = Angle(0,0,0),
        width = dim.width-dim.size,
        height = dim.height
    }
end

---@return SafeSpaceInteriorDimensions
function SafeSpace:GetInteriorDimensions(ply)
    return {
        width = SafeSpace:GetOption("interior","width",ply).value,
        height = SafeSpace:GetOption("interior","height",ply).value,
        length = SafeSpace:GetOption("interior","length",ply).value,
        size = SafeSpace:GetOption("global","size",ply).value
    }
end

function SafeSpace:GetInteriorPortalDimensions(ent)
    local dim=ent:GetDimensions()
    local edim=ent.exterior:GetDimensions()
    return {
        pos = Vector(-((dim.width/2)-dim.size)+5-(edim.size/2),0,(-dim.height/2)+(edim.height/2)-(dim.size/2)),
        ang = Angle(0,0,0),
        width = edim.width-edim.size,
        height = edim.height
    }
end

function SafeSpace:GetExteriorLighting(ent)
    local dim=ent:GetDimensions()
    ---@cast ent.interior gmod_door_interior
    local idim=ent.interior:GetDimensions()
    local portal=ent:GetPortalDimensions()
    return {
        {
            color=Vector(1,1,1),
            pos=ent:LocalToWorld(Vector(-idim.width/2,0,((idim.height+idim.size)/2)+(((idim.height-idim.size)/2)*0.5))),
        },
        {
            color=Vector(1,1,1)*0.5,
            pos=ent:LocalToWorld(portal.pos+Vector(dim.size*5,0,0)),
        }
    }
end

function SafeSpace:GetInteriorLighting(ent)
    local dim=ent:GetDimensions()
    local edim=ent.exterior:GetDimensions()
    local portal=ent:GetPortalDimensions()
    return {
        {
            color=Vector(1,1,1),
            pos=ent:LocalToWorld(Vector(0,0,((dim.height-dim.size)/2)*0.5))
        },
        {
            color=Vector(1,1,1)*0.5,
            pos=ent:LocalToWorld(portal.pos+Vector(-edim.size*5,0,0))
        }
    }
end

function SafeSpace:GetTextureExterior(ply)
    local mat = ply:GetInfo("safespace_exterior_material")
    if list.Contains("OverrideMaterials",mat) then
        return mat
    else
        return "hunter/myplastic"
    end
end

function SafeSpace:GetTextureInterior(ply)
    local mat = ply:GetInfo("safespace_interior_material")
    if list.Contains("OverrideMaterials",mat) then
        return mat
    else
        return "hunter/myplastic"
    end
end

local wireframe=Material("models/wireframe")
local scale=Vector(1,1,1)

function SafeSpace:Init(ent)
    if CLIENT then
        local vertices={}
        for _,section in pairs(ent.sections) do
            for _,vert in pairs(section[1]) do
                table.insert(vertices,vert)
            end
        end
        ent.mesh=Mesh()
        ent.mesh:BuildFromTriangles(vertices)
    end
    local meshes={}
    for _,v in pairs(ent.sections) do
        table.insert(meshes,v[2])
    end
    ent:PhysicsInitMultiConvex(meshes)
    ent:EnableCustomCollisions(true)
    
    ent.phys = ent:GetPhysicsObject()
    if not IsValid(ent.phys) then
        ent:Remove()
        return
    end 
    
    ent.phys:SetMass(50000)
    ent.phys:SetMaterial(ent.surfacetype or "metal")
    ent.phys:EnableMotion(false)
    
    if CLIENT then
        -- https://facepunch.com/showthread.php?t=1459677
        if ent.AddHook then
            ent:AddHook("Think","phys",function(self)
                if IsValid(self.phys) then
                    self.phys:EnableMotion(false)
                    self.phys:SetPos(self:GetPos())
                    self.phys:SetAngles(self:GetAngles())
                end
            end)
        end
        
        ent.CustomDrawModel = function(self,ghost)
            if self.mesh then
                local mat = Matrix()
                local translate = self:GetPos()
                if ghost and self.exterior then
                    local dim = self:GetDimensions()
                    local edim = self.exterior:GetDimensions()
                    translate = self.exterior:LocalToWorld(Vector((-dim.width/2)+edim.size/2,0,(dim.height+dim.size)/2))
                end
                mat:Translate(translate)
                local rotate = self:GetAngles()
                if ghost and self.exterior then
                    rotate:RotateAroundAxis(rotate:Up(),180)
                end
                mat:Rotate(rotate)
                mat:Scale(scale)
                -- fixes it going black sometimes
                render.ResetModelLighting(0,0,0)
                render.SetLocalModelLights(self:GetLighting())
                if ghost then
                    render.SetMaterial(wireframe)
                else
                    render.SetMaterial(Material(self.material))
                end

                cam.PushModelMatrix(mat)
                    self.mesh:Draw()
                cam.PopModelMatrix()
                
                --[[
                -- draws 'Drawing' text in top left if drawing
                cam.Start2D()
                    draw.DrawText("Drawing","DermaLarge",0,0,Color(255,0,0,255))
                cam.End2D()
                
                -- draws wireframe around render bounds
                
                local mins,maxs=self:GetRenderBounds()
                render.SetMaterial(wireframe)
                render.DrawBox(self:GetPos(),self:GetAngles(),mins,maxs,Color(255,0,0,255),false)
                
                -- draws boxes around light sources
                for k,v in pairs(self:GetLighting()) do
                    local mins,maxs=self:WorldToLocal(v.pos)-Vector(1,1,1)*10,self:WorldToLocal(v.pos)+Vector(1,1,1)*10
                    render.SetMaterial(wireframe)
                    render.DrawBox(self:GetPos(),self:GetAngles(),mins,maxs,Color(255,0,0,255),false)
                end
                ]]--
            end
        end
    end
end

function SafeSpace:MakeDoor(ent)
    ent:SetRenderMode(RENDERMODE_TRANSALPHA)
    ent:SetColor(Color(255,255,255,255))
    
    local dim=ent:GetDimensions()
    ent.sections={
        {self:MakeCube(Vector(0,-dim.width/2,dim.height/2),Angle(0,0,0),dim.size,dim.size,dim.height,dim.texscale)},
        {self:MakeCube(Vector(0,0,dim.height+(dim.size/2)),Angle(0,0,0),dim.size,dim.width+dim.size,dim.size,dim.texscale)},
        {self:MakeCube(Vector(0,dim.width/2,dim.height/2),Angle(0,0,0),dim.size,dim.size,dim.height,dim.texscale)},
    }
    
    local mins,maxs=Vector(-dim.size/2,(-dim.width-dim.size)/2,0),Vector(dim.size/2,(dim.width+dim.size)/2,dim.height+dim.size)
    if CLIENT then
        ent:SetRenderBounds(mins,maxs)
    end
    
    self:Init(ent)
end

---@param ent gmod_safespace_interior
function SafeSpace:MakeInterior(ent)
    ent:SetRenderMode(RENDERMODE_TRANSALPHA)
    ent:SetColor(Color(255,255,255,255))

    local edim=ent.exterior:GetDimensions()
    local dim=ent:GetDimensions()
    local offset=Vector(dim.width/2,dim.length/2,(dim.height-dim.size)/2)
    ent.sections={
        {self:MakeCube(Vector(-dim.width/2,-dim.length/2,(-dim.size/2)-dim.height)+offset,Angle(0,0,0),dim.width,dim.length,dim.size,edim.texscale)}, -- floor
        {self:MakeCube(Vector(-dim.width/2,-dim.length/2,(dim.height-dim.size/2)-dim.height)+offset,Angle(0,0,0),dim.width,dim.length,dim.size,edim.texscale)}, -- ceiling
        {self:MakeCube(Vector(-dim.width/2,-dim.length+(dim.size/2),(dim.height/2-(dim.size/2))-dim.height)+offset,Angle(0,0,0),dim.width,dim.size,dim.height-dim.size,edim.texscale)}, -- right wall
        {self:MakeCube(Vector(-dim.width/2,-(dim.size/2),(dim.height/2-(dim.size/2))-dim.height)+offset,Angle(0,0,0),dim.width,dim.size,dim.height-dim.size,edim.texscale)}, -- left wall
        {self:MakeCube(Vector(-dim.size/2,(-dim.length/2),(dim.height/2-(dim.size/2))-dim.height)+offset,Angle(0,0,0),dim.size,dim.length-(dim.size*2),dim.height-dim.size,edim.texscale)}, -- front wall
        {self:MakeCube(Vector(-dim.width+(dim.size/2),(-dim.length/2),(dim.height/2-(dim.size/2))-(dim.height-(edim.height/2)))+offset,Angle(0,0,0),dim.size,dim.length-(dim.size*2),dim.height-dim.size-edim.height,edim.texscale)}, -- back wall top
        {self:MakeCube(Vector(-dim.width+(dim.size/2),(-dim.length/4)+(edim.width/4)-(edim.size/4)-(dim.size/2),((edim.height/2))-dim.height)+offset,Angle(0,0,0),dim.size,((dim.length-(edim.size*4))/2)-(edim.width/2)+(edim.size*2)+(edim.size/2)-(dim.size),edim.height,edim.texscale)}, -- back right wall
        {self:MakeCube(Vector(-dim.width+(dim.size/2),(-dim.length+dim.size)+((((dim.length-(dim.size*4))/2)-(edim.width/2)+(edim.size/2))/2)+(dim.size/2),((edim.height/2))-dim.height)+offset,Angle(0,0,0),dim.size,((dim.length-(edim.size*4))/2)-(dim.size)-(edim.width/2)+(edim.size*2)+(edim.size/2),edim.height,edim.texscale)}, -- back left wall
    }
    
    local mins,maxs=Vector(-dim.width/2,-dim.length/2,((-dim.height-dim.size)/2)-dim.size),Vector(dim.width/2,dim.length/2,(dim.height-dim.size)/2)
    ent.mins,ent.maxs=mins,maxs
    ent.ExitBox = {Min=mins,Max=maxs}
    if CLIENT then
        ent:SetRenderBounds(mins,maxs)
    end
    ent.Fallback={pos=Vector((-dim.width/2)+dim.size,0,((-dim.height-dim.size)/2))}
    
    self:Init(ent)
end