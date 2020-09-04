TOOL.Category		= "Construction"
TOOL.Name			= "#Tool.better_fin.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar = {
    coef		        = 0.5,
    surf_area           = 1.0,
    norm_x              = 0.0,
    norm_y              = 0.0,
    norm_z              = 1.0,
    auto_norm           = 0,
    auto_surf_area      = 0,
}

cleanup.Register( "better_fin" )

-- // Add Default Language translation (saves adding it to the txt files)
if CLIENT then
    language.Add( "Tool.better_fin.name", "Better Fin Tool" )
    language.Add( "Tool.better_fin.desc", "Make a Fin out of a physics-prop." )
    language.Add( "Tool.better_fin.0", "Left-Click to apply settings; Right-Click to copy" )
    language.Add( "Tool.better_fin.coef", "Lift coefficient of Fin:" )
    language.Add( "Undone_better_fin", "Undone Fin" )
    language.Add( "Cleanup_better_fin", "Fin" )
    language.Add( "Cleaned_better_fin", "Cleaned up all Fins" )
    language.Add( "sboxlimit_better_fin", "You've reached the Fin-limit!" )
end

if SERVER then
    CreateConVar("sbox_max_better_fin", 20)
end

function networked(Entity, Data)
    Entity:SetNWBool("Active", true)
    Entity:SetNWFloat("coefficient", Data.coefficient)
    Entity:SetNWFloat("surface_area", Data.surface_area)
    Entity:SetNWVector("normal", Data.normal)
end
function networked_remove_partially(Entity)
    Entity:SetNWBool("Active", true)
    Entity:SetNWFloat("coefficient", -99)
    Entity:SetNWFloat("surface_area", -99)
    Entity:SetNWVector("normal", Vector(-99, -99, -99))
end
function networked_remove(Entity)
    Entity:SetNWBool("Active", false)
    Entity:SetNWFloat("coefficient", -99999999)
    Entity:SetNWFloat("surface_area", -99999999)
    Entity:SetNWVector("normal", Vector(-99999999, -99999999, -99999999))
end

if CLIENT then
    -- Print screen
    function showValuesFinHUD()
        local Player   = LocalPlayer()
        local Entity   = Player:GetEyeTrace().Entity
        local Weapon   = Player:GetActiveWeapon()
        if (!Player:IsValid() or !Entity:IsValid() or !Weapon:IsValid()) then return end
        
        local position = (Entity:LocalToWorld(Entity:OBBCenter())):ToScreen()
        
        if Weapon:GetClass() != "gmod_tool" or Player:GetInfo("gmod_toolmode") != "better_fin" then return end
        
        -- -99/nil = partially removed
        -- -99999999/-nil = undefined
        
        -- Get networked values of Entity
        local Active            = Entity:GetNWBool("Active", false)
        local coefficient         = Entity:GetNWFloat("coefficient", -99999999)
        local surface_area         = Entity:GetNWFloat("surface_area", -99999999)
        --
        if (Active) then
            -- Display values
            if (Entity:IsValid()) then
                local on = "On"
                local off = "Off"
                
                -- Set text-string for display
                local text_coef     = "Lift coefficient: "..coefficient
                local text_area     = "Surface area: "..surface_area
                local text_lift     = "Total lift constant: "..(coefficient * surface_area)

                -- Draw template Text for width- and height-calculations
                surface.SetFont("Trebuchet18")
                surface.SetTextColor(255, 255, 255, 0)
                surface.SetTextPos(position.x, position.y)
                surface.DrawText(text_coef)
                local width_text, height_text = surface.GetTextSize(text_coef)

                -- Text-dimensions
                local positionX_text = (position.x - (width_text / 2) - 30)
                local positionY_text = (position.y - (height_text / 2))

                -- Box-dimensions
                local width_box = width_text * 1.5 -- Change this value for box-size
                local height_box = height_text * 2 -- Change this value for box-size
                local positionX_box = position.x - (width_box / 2)
                local positionY_box = position.y - (height_box / 2)

                -- Draw Rounded Box
                draw.RoundedBox(3, (positionX_box * 0.994), (positionY_box * 0.99), ((width_box * 1.22) * 1.09), ((height_box * 4.5) * 1.065), Color(000, 000, 000, 197))
                draw.RoundedBox(3, positionX_box, positionY_box, (width_box * 1.22), (height_box * 4.5), Color(29, 167, 209, 197))
                -- Draw real Text
                surface.SetFont("Trebuchet18")
                surface.SetTextColor(255, 255, 255, 255)
                -- Text 0
                surface.SetTextPos(positionX_text, positionY_text)
                surface.DrawText(text_coef)

                surface.SetTextPos(positionX_text, positionY_text + height_text)
                surface.DrawText(text_area)

                surface.SetTextPos(positionX_text, positionY_text + height_text * 2)
                surface.DrawText(text_lift)
            end
        else return end
    end
    
    hook.Add("HUDPaint", "showValuesFinHUD", showValuesFinHUD)
end

function TOOL:LeftClick( trace )
    if (!trace.Hit or !trace.Entity:IsValid() or trace.Entity:GetClass() != "prop_physics") then return false end
    if (SERVER and !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone )) then return false end
    if CLIENT then return true end
    
    local coef = self:GetClientNumber("coef")
    
    if (trace.Entity.better_fin_Ent != nil) then
        local Data = {
            coefficient = coef,
            surface_area = surf_area,
            normal = Vector(norm_x, norm_y, norm_z),
        }
        table.Merge(trace.Entity.better_fin_Ent:GetTable(), Data)
        duplicator.StoreEntityModifier(trace.Entity, "better_fin", Data)
        
        -- Access on server- and client-side
        networked(trace.Entity, Data)
        
        return true
    end
    
    if !self:GetSWEP():CheckLimit("better_fin") then return false end
    
    local Data = {}
    Data = {
        coefficient = coef,
        surface_area = surf_area,
        normal = Vector(norm_x, norm_y, norm_z),
        pos		    = trace.Entity:WorldToLocal(trace.HitPos + trace.HitNormal * 4),
        ang		    = trace.Entity:WorldToLocalAngles(trace.HitNormal:Angle())
    }
    PrintTable(Data)
    local fin = MakeBetterFinEnt(self:GetOwner(), trace.Entity, Data)
    
    -- Remove
    undo.Create("better_fin")   
        undo.AddFunction(function()
            -- Remove networked-settings for Entity
            networked_remove(trace.Entity)
        end)
        undo.AddEntity(fin)
        undo.SetPlayer(self:GetOwner())
    undo.Finish()
    
    return true
end

--Copy fin
function TOOL:RightClick( trace )
    if (trace.Entity.better_fin_Ent != nil) then
        local fin = trace.Entity.better_fin_Ent
        local ply = self:GetOwner()
        ply:ConCommand("better_fin_coef "..fin.coefficient)
        ply:ConCommand("better_fin_surf_area "..fin.surface_area)
        return true
    end
end

function TOOL:Reload( trace )
    if (trace.Entity.better_fin_Ent != nil) then
        trace.Entity.better_fin_Ent:Remove()
        trace.Entity.better_fin_Ent = nil
        -- Remove networked-settings for Entity
        networked_remove_partially(trace.Entity)
        
        return true
    end
end

if SERVER then
    function MakeBetterFinEnt( Player, Entity, Data )
        if !Data then return end
        if !Player:CheckLimit("better_fin") then return false end

        PrintTable(Data)

        local fin = ents.Create( "better_fin" )
        if (Data.pos != nil) then fin:SetPos(Entity:LocalToWorld(Data.pos)) end
        fin:SetAngles(Entity:LocalToWorldAngles(Data.ang))
        fin.ent			= Entity
        fin.coefficient  = Data.coefficient
        fin.surface_area = Data.surface_area
        fin.normal = Data.normal
        fin:Spawn()
        fin:Activate()
        --
        fin:SetParent(Entity)
        Entity:DeleteOnRemove(fin)
        -- Set
        Entity.better_fin_Ent = fin

        duplicator.StoreEntityModifier(Entity, "better_fin", Data)
        Player:AddCount("better_fin", fin)
        Player:AddCleanup("better_fin", fin)
        
        -- Access on server- and client-side
        networked(Entity, Data)
        
        return fin
    end
    duplicator.RegisterEntityModifier("better_fin", MakeBetterFinEnt)
end


function TOOL.BuildCPanel(CPanel)
    -- Options	
    CPanel:AddControl("Header", {Text = "#Tool.better_fin.name"})
    
    CPanel:AddItem(left2, ctrl2)
    -- Slider
    CPanel:NumSlider("#Tool.better_fin.coef", "better_fin_coef", 0, 2, nil)
    CPanel:NumSlider("#Tool.better_fin.surf_area", "better_fin_surf_area", 0, 10, nil)
end