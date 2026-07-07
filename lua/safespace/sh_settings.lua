-- Settings

local options={
    {
        id = "global",
        name = "Global",
        {
            id = "size",
            name = "Size",
            min = 10,
            max = 1000,
            default = 25
        },
        {
            id = "texscale",
            name = "Texture Scaling",
            min = 10,
            max = 1000,
            default = 25
        }
    },
    {
        id = "exterior",
        name = "Frame",
        {
            id = "width",
            name = "Width",
            min = 50,
            max = 5000,
            default = 100
        },
        {
            id = "height",
            name = "Height",
            min = 50,
            max = 5000,
            default = 150
        }
    },
    {
        id = "interior",
        name = "Interior",
        {
            id = "width",
            name = "Width",
            min = 50,
            max = 5000,
            default = 300
        },
        {
            id = "height",
            name = "Height",
            min = 50,
            max = 5000,
            default = 250
        },
        {
            id = "length",
            name = "Length",
            min = 50,
            max = 5000,
            default = 300
        }
    }
}

function SafeSpace:GetOptions()
    return options
end

---@class safespace_option
---@field id string
---@field name string
---@field min integer
---@field max integer
---@field default integer
---@field value integer
---@field savedvalue integer?
---@field convar ConVar?
---@field slider DNumSlider?

---@param category string
---@param option string
---@param ply Player?
---@return safespace_option
function SafeSpace:GetOption(category,option,ply)
    for _,cat in ipairs(options) do
        if cat.id==category then
            for _,opt in ipairs(cat) do
                if opt.id==option then
                    if SERVER and ply then
                        opt.value = ply:GetInfoNum(self:GetOptionConVarName(cat.id,opt.id),opt.default)
                    elseif opt.convar then
                        opt.value = opt.convar:GetInt()
                    end
                    if not opt.value then
                        opt.value = opt.default
                    end
                    opt.value = math.max(opt.min,math.min(opt.max,opt.value))
                    if CLIENT and (not opt.savedvalue) then
                        opt.savedvalue = opt.value
                    end
                    return opt
                end
            end
        end
    end
    error(string.format("Unknown SafeSpace option: %s.%s", category, option))
end

function SafeSpace:SaveOptions()
    for _,cat in ipairs(options) do
        for _,opt in ipairs(cat) do
            self:GetOption(cat.id,opt.id)
            opt.savedvalue = opt.value
        end
    end
end

function SafeSpace:ResetOptionChanges()
    for _,cat in ipairs(options) do
        for _,opt in ipairs(cat) do
            self:GetOption(cat.id,opt.id)
            if opt.convar and opt.savedvalue then
                opt.convar:SetInt(opt.savedvalue)
            end
        end
    end
end

function SafeSpace:SetDefaultOptions()
    for _,cat in ipairs(options) do
        for _,opt in ipairs(cat) do
            opt.value = opt.default
            if opt.convar then
                opt.convar:SetInt(opt.value)
            end
        end
    end
end

---@param category string
---@param option string
function SafeSpace:GetOptionConVarName(category,option)
    return "safespace_".. category .. "_" .. option
end

if CLIENT then
    CreateClientConVar("safespace_exterior_material","",true,true)
    CreateClientConVar("safespace_interior_material","",true,true)
    CreateClientConVar("safespace_global_surface","",true,true)
    CreateClientConVar("safespace_showghost","1")
    CreateClientConVar("safespace_showghostint","1")
    for _,cat in ipairs(options) do
        for _,opt in ipairs(cat) do
            opt.convar = CreateClientConVar(SafeSpace:GetOptionConVarName(cat.id,opt.id), opt.default, true, true)
        end
    end
end

function SafeSpace:UpdateGhost()
    if IsValid(SafeSpace.GhostExterior) and IsValid(SafeSpace.GhostInterior) then
        SafeSpace.GhostExterior:UpdateModel()
        SafeSpace.GhostInterior:UpdateModel()
    end
end

function SafeSpace:OpenPresets()
    local frame=vgui.Create("DFrame")
    frame:SetSize(ScrW()*0.15,ScrH()*0.4)
    frame:SetTitle("Presets")
    frame:SetDraggable(true)
    frame:Center()
    frame.OldClose = frame.Close

    local removed={}
    local changed=false

    local panel=vgui.Create("DPanel",frame)
    panel:SetSize(frame:GetWide()-4,frame:GetTall()-27)
    panel:SetPos(2,25)

    local presetlist = vgui.Create("DListView",panel) --[[@as DListView]]
    presetlist:SetWide(panel:GetWide())
    presetlist:SetTall(panel:GetTall()-45)
    presetlist:SetMultiSelect(false)
    presetlist:AddColumn( "Preset" )
    local initdata=file.Read("safespace_presets.txt","DATA")
    if initdata then
        local data=Doors.von.deserialize(initdata)
        if data then
            for k,v in pairs(data) do
                presetlist:AddLine(k).data=v
            end
        end
    end
    presetlist:SelectFirstItem()

    local save=vgui.Create("DButton",panel)
    save:SetSize(35,20)
    save:SetPos(panel:GetWide()-save:GetWide(),panel:GetTall()-save:GetTall())
    save:SetText("Save")
    save.DoClick = function()
        local data={}
        for _,v in ipairs(presetlist:GetLines()) do
            data[v:GetValue(1)] = v.data
        end
        file.Write("safespace_presets.txt",Doors.von.serialize(data))
        changed = false
    end

    local load=vgui.Create("DButton",panel)
    local sx,sy = save:GetPos()
    load:SetSize(35,20)
    load:SetPos(sx-load:GetWide()-5,sy)
    load:SetText("Load")
    load.DoClick = function()
        local selected = presetlist:GetSelectedLine()
        if selected then
            local line = presetlist:GetLine(selected) --[[@as DListView_Line]]
            if line then
                local data=line.data
                if data then
                    for _,cat in ipairs(options) do
                        local catdata = data[cat.id]
                        if catdata then
                            for _,opt in ipairs(cat) do
                                local o = SafeSpace:GetOption(cat.id,opt.id)
                                local o2 = catdata[opt.id]
                                if o and o.convar and o.value and o2 and o.value ~= o2 then
                                    o.convar:SetInt(o2)
                                end
                            end
                        end
                    end
                end
                SafeSpace:ResetOptionChanges()
                frame:Close()
            end
        end
    end

    local new=vgui.Create("DButton",panel)
    local lx,ly = load:GetPos()
    new:SetSize(35,20)
    new:SetPos(lx-new:GetWide()-5,ly)
    new:SetText("New")
    new.DoClick = function()
        Derma_StringRequest("New preset", "Please enter a name for your preset", "", function(name)
            local data={}
            for _,cat in ipairs(options) do
                data[cat.id]={}
                for _,opt in ipairs(cat) do
                    local o=SafeSpace:GetOption(cat.id,opt.id)
                    if o then
                        data[cat.id][opt.id]=o.value
                    end
                end
            end
            presetlist:AddLine(name).data=data
            if removed[name] then
                removed[name] = nil
            end
            changed = true
        end)
    end

    local remove=vgui.Create("DButton",panel)
    remove:SetSize(50,20)
    remove:SetPos(panel:GetWide()-remove:GetWide(),panel:GetTall()-remove:GetTall()-new:GetTall()-2)
    remove:SetText("Remove")
    remove.DoClick = function()
        local selected = presetlist:GetSelectedLine()
        if selected then
            local line=presetlist:GetLine(selected) --[[@as DListView_Line]]
            if line then
                removed[line:GetValue(1)] = true
                presetlist:RemoveLine(selected)
                changed = true
            end
        end
        presetlist:SelectFirstItem()
    end

    local rename=vgui.Create("DButton",panel)
    local rx,ry = remove:GetPos()
    rename:SetSize(50,20)
    rename:SetPos(rx-rename:GetWide()-5,ry)
    rename:SetText("Rename")
    rename.DoClick = function()
        local selected = presetlist:GetSelectedLine()
        if selected then
            local line = presetlist:GetLine(selected) --[[@as DListView_Line]]
            if line then
                local old=line:GetValue(1)
                Derma_StringRequest("Rename preset", "Please enter a new name for your preset", old, function(name)
                    if old ~= name then
                        line:SetValue(1,name)
                        removed[old] = true
                        changed = true
                    end
                end)
            end
        end
    end

    frame.Close = function(self)
        if changed then
            Derma_Query(
                "You have unsaved changes, do you want to save?",
                "Unsaved changes",
                "Yes",
                function() save:DoClick() self:OldClose() end,
                "No",
                function() self:OldClose() end,
                "Cancel"
            )
        else
            self:OldClose()
        end
    end

    frame:MakePopup()
end
