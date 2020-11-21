
TOOL.Category		= "Construction"
TOOL.Name			= "#Tool.better_fin.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar = {
	efficiency = 70,
    show_HUD_always = 0
}

cleanup.Register( "better_fin" )

-- // Add Default Language translation (saves adding it to the txt files)
if CLIENT then
	language.Add( "Tool.better_fin.name", "Better Fin Tool" )
	language.Add( "Tool.better_fin.desc", "Make a Fin out of a physics-prop." )
	language.Add( "Tool.better_fin.0", "Left-Click to apply settings, Right-Click to copy" )
	language.Add( "Undone_fin_2", "Undone Fin" )
	language.Add( "Cleanup_fin_2", "Fin" )
	language.Add( "Cleaned_fin_2", "Cleaned up all Fins" )
	language.Add( "sboxlimit_fin_2", "You've reached the Fin-limit!" )
end

if SERVER then
    CreateConVar("sbox_maxfin_2", 20)
end

-- Setting network variables needed for the HUD
local function setNetVariables(ent, data)
    ent:SetNWFloat("efficiency", data.efficiency)
end
function removeNetVariables(ent)
    ent:SetNWFloat("efficiency", -1)    -- Meant to signal the removal of the fin, for some reason nil doesn't work
end

if CLIENT then
    -- Print screen
    function showValuesFinHUD()
        local Player   = LocalPlayer()
        local Entity   = Player:GetEyeTrace().Entity
        local Weapon   = Player:GetActiveWeapon()
        if (not Player:IsValid() or not Entity:IsValid() or not Weapon:IsValid()) then return end
        
        -- Check that the tool-gun is active with the fin-tool on
        local show_HUD_always = GetConVar("git"):GetBool()
        if not show_HUD_always then
            if Weapon:GetClass() != "gmod_tool" or Player:GetInfo("gmod_toolmode") != "better_fin" then return end
        end
        
        -- Get networked values of Entity
        local net_vars  = Entity:GetNWVarTable()
        local efficiency = net_vars.efficiency
        
        local screen_pos = Entity:GetPos():ToScreen()

        --PrintTable(net_vars)
        if efficiency != -1 then
            -- Set text-string for display
            local header = "Fin Properties"
            local text = 
            {
                "Efficiency:  "..efficiency,
            }

            -- Box size and pos
            local box_w = 200
            local box_h = 120
            local box_x = screen_pos.x - (box_w / 2)
            local box_y = screen_pos.y - (box_h / 2)

            local offset_x = 10
            local offset_y = 35

            -- Draw Rounded Box
            draw.RoundedBox(6, box_x, box_y, box_w, box_h, Color(000, 000, 000, 197))
            -- Draw the header box
            draw.RoundedBox(6, box_x+3, box_y+3, box_w-6, 30, Color(255, 255, 255, 197))
            -- Header text
            surface.SetFont("Trebuchet24")
            surface.SetTextColor(0, 0, 0, 255)
            surface.SetTextPos(box_x+10, box_y+6)
            surface.DrawText(header)
            -- Body text
            surface.SetFont("Trebuchet18")
            surface.SetTextColor(255, 255, 255, 255)
            for _, v in pairs(text) do
                surface.SetTextPos(box_x + offset_x, box_y + offset_y)
                surface.DrawText(v)
                offset_y = offset_y + 20
            end

        end
    end
    
    hook.Add("HUDPaint", "showValuesFinHUD", showValuesFinHUD)  -- This should probably moved elsewhere (where it'll run once)
end

function TOOL:LeftClick( trace )
	if (not trace.Hit or not trace.Entity:IsValid() or trace.Entity:GetClass() != "prop_physics") then return false end
	if (SERVER and !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone )) then return false end
	if CLIENT then return true end
	
    local efficiency = self:GetClientNumber("efficiency")

    -- If the trace hits an entity with a fin already applied
	if (trace.Entity.better_fin != nil) then
		local data = 
        {
            efficiency = efficiency
		}
		table.Merge(trace.Entity.better_fin:GetTable(), data)   -- Apply the new settings
		duplicator.StoreEntityModifier(trace.Entity, "better_fin", data)
        setNetVariables(trace.Entity, data)
        
		return true
	end
	
	if !self:GetSWEP():CheckLimit("better_fin") then return false end
    -- If the entity doesn't have a fin
    local data = 
    {
        pos         = trace.Entity:GetPos(),
        ang         = trace.HitNormal:Angle(),
        efficiency  = efficiency
    }
	local fin = MakeBetterFinEnt(self:GetOwner(), trace.Entity, data)
    PrintTable(fin:GetTable())

    -- Network some of the variables
    setNetVariables(trace.Entity, data)
	
    -- Remove
	undo.Create("better_fin")
        undo.AddFunction(function()
            -- Remove networked-settings for Entity
            removeNetVariables(trace.Entity)
        end)
        undo.AddEntity(fin)
        undo.SetPlayer(self:GetOwner())
	undo.Finish()
	
	return true
end

--Copy fin
function TOOL:RightClick( trace )
	if (trace.Entity.better_fin != nil) then
		local fin = trace.Entity.better_fin
		local ply = self:GetOwner()
        ply:ConCommand("better_fin_efficiency "..fin.efficiency)
		return true
	end
end

function TOOL:Reload( trace )
    if (trace.Entity.better_fin != nil) then
        removeNetVariables(trace.Entity)
        trace.Entity.better_fin:Remove()
		trace.Entity.better_fin = nil
		return true
	end
end

if SERVER then
	function MakeBetterFinEnt(Player, ent, data)
		if !data then return end
		if !Player:CheckLimit("better_fin") then return false end

		local fin = ents.Create("better_fin")
        fin:SetPos(data.pos)                    -- Set it at the parent's position
        fin:SetAngles(data.ang)                 -- With the same angle
        fin.ancestor    = BF_getAncestor(ent)   -- Find the ancestor
        fin.efficiency  = data.efficiency

        fin:Spawn()
		fin:Activate()
		fin:SetParent(ent)
        ent:DeleteOnRemove(fin)

        -- Assign the new entity to the phys_prop
		ent.better_fin = fin

		duplicator.StoreEntityModifier(ent, "better_fin", data)
		Player:AddCount("better_fin", fin)
		Player:AddCleanup("better_fin", fin)

		return fin
	end
	duplicator.RegisterEntityModifier("better_fin", MakeBetterFinEnt)
end

if CLIENT then
    function TOOL.BuildCPanel(CPanel)
        -- Slider to select the efficiency
        CPanel:NumSlider("Efficiency", "better_fin_efficiency", 0, 100, 0)
        -- Checkbox to select wether the HUD always shows, or only with the toolgun
        CPanel:CheckBox("Always show the HUD", "show_HUD_always")
    end
end