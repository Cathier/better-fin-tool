TOOL.Category		= "Construction"
TOOL.Name			= "#Tool.better_fin.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar = {
	coef		        = 0.5,
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

-- Console Varibles
CreateClientConVar("show_HUD_always", 0, true, false, "Show the HUD always or not (Better Fin Tool)")

-- Storing HUD settings for each Entity with Fin 2 applied to
function networked(Entity, Data)
    Entity:SetNWBool("Active", true)
    Entity:SetNWFloat("efficency", Data.efficiency)
end
function networked_remove_partially(Entity)
    Entity:SetNWBool("Active", true)
    Entity:SetNWFloat("efficency", -99)
end
function networked_remove(Entity)
    Entity:SetNWBool("Active", false)
    Entity:SetNWFloat("efficency", -99999999)
end

if CLIENT then
    -- Print screen
    function showValuesFinHUD()
        local Player   = LocalPlayer()
        local Entity   = Player:GetEyeTrace().Entity
        local Weapon   = Player:GetActiveWeapon()
        if (!Player:IsValid() or !Entity:IsValid() or !Weapon:IsValid()) then return end
        
        local position = (Entity:LocalToWorld(Entity:OBBCenter())):ToScreen()
        
        -- Check that the tool-gun is active with the fin-tool on
        --local TOOL = LocalPlayer():GetTool("fin2")
        local show_HUD_always = GetConVar("show_HUD_always", 0):GetInt()
        --
        if (show_HUD_always == 0) then
            if Weapon:GetClass() != "gmod_tool" or Player:GetInfo("gmod_toolmode") != "fin2" then return end
        end
        
        -- -99/nil = partially removed
        -- -99999999/-nil = undefined
        
        -- Get networked values of Entity
        local Active            = Entity:GetNWBool("Active", false)
        local efficency         = Entity:GetNWFloat("efficency", -99999999)
        --
        if (Active) then
            -- Display values
            if (Entity:IsValid()) then
                local on = "On"
                local off = "Off"
                
                
                -- Partially removed (using reload (R)) fin
                if ((lift == "nil") and (efficency == -99) and (pos_ang_opt == "-nil") and (pln == -99) and (wind == -99) and (cline == -99)) then
                    efficency   = "nil"
                    pos_ang_opt = pos_ang_opt
                    lift        = lift
                    pln         = "nil"
                    wind        = "nil"
                    cline       = "nil"
                end
                -- For old dupes
                if ((lift == "nil") and (efficency == -99) and (pos_ang_opt == "-") and (pln == -99) and (wind == -99) and (cline == -99)) then
                    efficency   = "nil"
                    pos_ang_opt = "-"
                    lift        = lift
                    pln         = "nil"
                    wind        = "nil"
                    cline       = "nil"
                end
                --
                if ((lift == "nil") and (efficency == -99) and (pos_ang_opt == off) and (pln == -99) and (wind == -99) and (cline == -99)) then
                    efficency   = "nil"
                    pos_ang_opt = "nil"
                    lift        = lift
                    pln         = "nil"
                    wind        = "nil"
                    cline       = "nil"
                end
                
                -- Set text-string for display
                local text0     = "Effic.: "..efficency
                local text1     = "Lift: "..lift
                local text2     = "F.S.D: "..pln
                local text3     = "Wind: "..wind
                local text4     = "Th. Cline: "..cline
                local text5     = "Pos. & Ang. r. to Prop: "..pos_ang_opt
                local text6_a   = "F"
                local text6_b   = "i"
                local text6_c   = "n"
                local text6_d   = "II"
                local text6_e   = "::"

                -- Draw template Text for width- and height-calculations
                surface.SetFont("Trebuchet18")
                surface.SetTextColor(255, 255, 255, 0)
                surface.SetTextPos(position.x, position.y)
                surface.DrawText(text0)
                local width_text, height_text = surface.GetTextSize(text0)

                -- Text-dimensions
                local positionX_text = (position.x - (width_text / 2) - 30)
                local positionY_text = (position.y - (height_text / 2))

                -- Box-dimensions
                local width_box = width_text * 3 -- Change this value for box-size
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
                surface.DrawText(text0)
                -- Text 1
                surface.SetTextPos(positionX_text, (positionY_text + height_text + 3))
                surface.DrawText(text1)
                -- Text 2
                surface.SetTextPos(positionX_text, (positionY_text + (height_text * 2 + 6)))
                surface.DrawText(text2)
                -- Text 3
                surface.SetTextPos(positionX_text, (positionY_text + (height_text * 3 + 9)))
                surface.DrawText(text3)
                -- Text 4
                surface.SetTextPos(positionX_text, (positionY_text + (height_text * 4 + 12)))
                surface.DrawText(text4)
                -- Text 5
                surface.SetTextPos(positionX_text, (positionY_text + (height_text * 5 + 15)))
                surface.DrawText(text5)
                -- Text 6
                surface.SetFont("Trebuchet24")
                -- 6a
                surface.SetTextPos(positionX_text + (width_text * 3) + 12, (positionY_text + height_text) - 31)
                surface.DrawText(text6_a)
                -- 6b
                surface.SetTextPos(positionX_text + (width_text * 3) + 12, (positionY_text + height_text) - 13)
                surface.DrawText(text6_b)
                -- 6c
                surface.SetTextPos(positionX_text + (width_text * 3) + 12, (positionY_text + height_text) + 2)
                surface.DrawText(text6_c)
                -- 6d
                surface.SetTextPos(positionX_text + (width_text * 3) + 11, (positionY_text + height_text) + 28)
                surface.DrawText(text6_d)
                -- 6e
                surface.SetTextPos(positionX_text + (width_text * 3) + 12, (positionY_text + height_text) + 45)
                surface.DrawText(text6_e)
            end
        else return end
    end
    
    hook.Add("HUDPaint", "showValuesFinHUD", showValuesFinHUD)
end

function TOOL:LeftClick( trace )
	if (!trace.Hit or !trace.Entity:IsValid() or trace.Entity:GetClass() != "prop_physics") then return false end
	if (SERVER and !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone )) then return false end
	if CLIENT then return true end
	
    local coef         = self:GetClientNumber("coef")
	
	if (trace.Entity.better_fin_Ent != nil) then
		local Data = {
			coefficient = coef
		table.Merge(trace.Entity.Fin2_Ent:GetTable(), Data)
		duplicator.StoreEntityModifier(trace.Entity, "fin2", Data)
        
        -- Access on server- and client-side
        networked(trace.Entity, Data)
        
		return true
	end
	
	if !self:GetSWEP():CheckLimit("fin_2") then return false end
    
    local Data = {}
    if (pos_ang_opt == "0") then
        Data = {
            pos		    = trace.Entity:WorldToLocal(trace.HitPos + trace.HitNormal * 4),
            ang		    = trace.Entity:WorldToLocalAngles(trace.HitNormal:Angle()),
            lift	    = lft,
            pln		    = pln,
            wind	    = wnd,
            cline	    = cln,
            efficiency  = eff,
            pos_ang_opt = pos_ang_opt
        }
    else
        Data = {
            pos         = trace.Entity:WorldToLocal(trace.Entity:GetPos()),
            ang         = trace.Entity:WorldToLocalAngles(trace.Entity:GetAngles()),
            lift        = lft,
            pln		    = pln,
            wind	    = wnd,
            cline	    = cln,
            efficiency  = eff,
            pos_ang_opt = pos_ang_opt
        }
    end
	
	local fin = MakeFin2Ent(self:GetOwner(), trace.Entity, Data)
	
    -- Remove
	undo.Create("fin_2")
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
	if (trace.Entity.Fin2_Ent != nil) then
		local fin = trace.Entity.better_fin_Ent
		local ply = self:GetOwner()
        ply:ConCommand("fin2_coef "..fin.coefficient)
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
	function MakeFin2Ent( Player, Entity, Data )
		if !Data then return end
		if !Player:CheckLimit("better_fin") then return false end

		local fin = ents.Create( "better_fin" )
			if (Data.pos != nil) then fin:SetPos(Entity:LocalToWorld(Data.pos)) end
			fin:SetAngles(Entity:LocalToWorldAngles(Data.ang))
			fin.ent			= Entity
            fin.coefficient  = Data.coefficient
		fin:Spawn()
		fin:Activate()
        --
		fin:SetParent(Entity)
        Entity:DeleteOnRemove(fin)
        -- Set
		Entity.Fin2_Ent = fin

		duplicator.StoreEntityModifier(Entity, "fibetter_finn2", Data)
		Player:AddCount("better_fin", fin)
		Player:AddCleanup("better_fin", fin)
        
        -- Access on server- and client-side
        networked(Entity, Data)
		
		return fin
	end
	duplicator.RegisterEntityModifier("better_fin", MakeFin2Ent)
end


function TOOL.BuildCPanel(CPanel)
    -- Options	
	CPanel:AddControl("Header", {Text = "#Tool.better_fin.name"})
    
    CPanel:AddItem(left2, ctrl2)
    -- Slider
	CPanel:NumSlider("#Tool.better_fin.eff", "better_fin_eff", 0, 250, nil)
end