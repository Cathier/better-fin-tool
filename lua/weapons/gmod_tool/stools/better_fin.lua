
TOOL.Category		= "Construction"
TOOL.Name			= "#Tool.better_fin.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar = {
	efficiency = 70,
	zla = 10,           -- Zero lift angle
    show_HUD_always = 0,
    model = "wing"
}

-- These must have the same name as the respective function, as the client ConVar uses this value to find the respective function
local models_text = 
{
    wing = "Realistic wing model. Good lift-to-drag ratio when not stalling. Stalls at around 20 degrees of angle of attack",
    simplified = "Simplified \"air deflector\". Works simmiarly to fin2. Bad lift-to-drag ratio, but does not stall"
}

CreateClientConVar("show_HUD_always", "0", true, false)

cleanup.Register( "better_fin" )

-- // Add Default Language translation (saves adding it to the txt files)
if CLIENT then
	language.Add( "Tool.better_fin.name", "Better Fin Tool" )
	language.Add( "Tool.better_fin.desc", "Make a Fin out of a physics-prop." )
	language.Add( "Tool.better_fin.0", "Left-Click to apply settings, Right-Click to copy" )
	language.Add( "Undone_better_fin", "Undone Fin" )
	language.Add( "Cleanup_better_fin", "Better fin" )
	language.Add( "Cleaned_better_fin", "Cleaned up all Fins" )
	language.Add( "sboxlimit_better_fin", "You've reached the Fin-limit!" )
end

if SERVER then
    CreateConVar("sbox_max_better_fin", 20)
end

if CLIENT then
    -- Print screen
    function showValuesFinHUD()
        local Player   = LocalPlayer()
        local entity   = Player:GetEyeTrace().Entity
        local Weapon   = Player:GetActiveWeapon()
        if (not IsValid(Player) or not IsValid(entity) or not IsValid(Weapon)) then return end
        
        -- Check if the toolgun is in hand, and if the better fin tool is selected
        local show_HUD_always = GetConVar("show_HUD_always", 0):GetBool()
        if not show_HUD_always then
            if Weapon:GetClass() != "gmod_tool" or Player:GetInfo("gmod_toolmode") != "better_fin" then return end
        end
        
        local efficiency = entity:GetNWFloat("efficiency", -1)
        local model = entity:GetNWString("model", "")

        if efficiency != -1 && efficiency != nil then
            -- Set text-string for display
            local header = "Fin Properties"
            local text = 
            {
                "Efficiency:    "..efficiency,
                "Flight model:  "..model
            }

            -- Box size and pos
            local screen_pos = entity:GetPos():ToScreen()
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
    
    hook.Add("HUDPaint", "showValuesFinHUD", showValuesFinHUD)
end

function TOOL:LeftClick( trace )
	if not trace.Hit or not trace.Entity:IsValid() or trace.Entity:GetClass() != "prop_physics" then return false end
	if SERVER and !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end
	if CLIENT then return true end
	
	local entity = trace.Entity
    local data = 
    {
        -- Load and validate the data
        pos         = trace.Entity:GetPos(),
        ang         = trace.HitNormal:Angle(),
        efficiency  = math.Clamp(self:GetClientNumber("efficiency"), 0, 100),    -- Clamp so people can't make trillion efficiency fins
        zla         = math.Clamp(self:GetClientNumber("zla"), 0, 10),
        model       = self:GetClientInfo("model")
    }
    -- Validate some extra data
    if not models_text[data.model] then data.model = "wing" end

    if entity.better_fin == nil then    -- If entity does not have a fin
        if !self:GetSWEP():CheckLimit("better_fin") then return false end
	    makeBetterFinEnt(self:GetOwner(), entity, data) -- Create a new one
    else
        updateBetterFinEnt(entity.better_fin, data)     -- Else, update the existing one
    end
	
    -- Remove
	undo.Create("better_fin")
        undo.AddFunction(function()
            if IsValid(entity.better_fin) then entity.better_fin:Remove() end
        end)
        undo.AddEntity(fin)
        undo.SetPlayer(self:GetOwner())
	undo.Finish()
	
	return true
end

-- Copy the settings from the target fin
function TOOL:RightClick( trace )
	if (trace.Entity.better_fin != nil) then
		local fin = trace.Entity.better_fin
		local ply = self:GetOwner()
        ply:ConCommand("better_fin_efficiency "..fin.efficiency)
        ply:ConCommand("better_fin_model "..fin.model)
		return true
	end
end

-- Remove the fin from the target prop
function TOOL:Reload( trace )
    if (trace.Entity.better_fin != nil) then
        trace.Entity.better_fin:Remove()    -- Delete the fin (OnRemove handles everything else, like NetVar removal)
		return true
	end
end

if SERVER then
	function makeBetterFinEnt(Player, ent, data)
		if !Player:CheckLimit("better_fin") then return false end

		local fin = ents.Create("better_fin")   -- Create a fin  
        fin:Spawn()                             -- Spawn, parent, etc.
		fin:Activate()
		fin:SetParent(ent)
        ent:DeleteOnRemove(fin)

        updateBetterFinEnt(fin, data)   -- Update it with the data
		ent.better_fin = fin            -- Assign the new entity to the phys_prop

        better_fin.add_to_table(fin)    -- Add the fin to the global table
		duplicator.StoreEntityModifier(ent, "better_fin", data)
		Player:AddCount("better_fin", fin)
		Player:AddCleanup("better_fin", fin)
	end

    function updateBetterFinEnt(fin, data)
        fin:SetPos(data.pos)                            -- Set it at the parent's position
        fin:SetAngles(data.ang)                         -- With the same angle
        fin.ancestor    = better_fin.getAncestor(fin)   -- Find the ancestor
        fin.efficiency  = data.efficiency               -- Set the efficiency
        fin.model       = data.model                    -- Set the flight model
        fin.model_func  = better_fin.models[data.model] `
        print(model)
        print(model_func)
        -- Network the necessary variables
        fin:setNetworkVariables()
    end

	duplicator.RegisterEntityModifier("better_fin", makeBetterFinEnt)
end



if CLIENT then
    function TOOL.BuildCPanel(CPanel)
        -- Flight model selector
        local cbox = CPanel:ComboBox("Flight model", "better_fin_model")
        cbox:AddChoice("Wing", "wing", true)
        cbox:AddChoice("Simplified", "simplified", false)
        local model_explanation = CPanel:ControlHelp(models_text.wing)

        function cbox:OnSelect(index, text, data)
            model_explanation:SetText(models_text[data])
            GetConVar("better_fin_model"):SetString(data)
        end

        -- Slider to select the efficiency
        CPanel:NumSlider("Efficiency", "better_fin_efficiency", 0, 100, 0)
        CPanel:ControlHelp("Controls how much force (both lift and drag) the fin produces")
        -- Slider for the zero-lift angle
        CPanel:NumSlider("Zero-lift angle", "better_fin_zla", 0, 10, 0)
        CPanel:ControlHelp("The negative angle of attack at which the fin produces no lift. When flying level, setting this high will provide more lift, setting it to zero will provide none")
        -- Checkbox to select wether the HUD always shows, or only with the toolgun
        CPanel:CheckBox("Always show the HUD", "show_HUD_always")
    end
end