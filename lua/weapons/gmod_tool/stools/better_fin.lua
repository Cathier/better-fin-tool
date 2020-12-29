TOOL.Category		= "Construction"
TOOL.Name			= "#Tool.better_fin.name"
TOOL.Command		= nil

cleanup.Register( "better_fin" )

------------------- SERVER -------------------
if SERVER then

    CreateConVar("sbox_max_better_fin", 20)

    local function updateBetterFinEnt(ent, fin, data)
        fin:SetPos(ent:LocalToWorld(data.pos))          -- Set it at the parent's position
        fin:SetAngles(ent:LocalToWorldAngles(data.ang)) -- Set it's angle
        fin.ancestor    = better_fin.getAncestor(fin)   -- Find the ancestor
        fin.efficiency  = data.efficiency               -- Set the efficiency
        fin.model       = data.model                    -- Set the flight model
        fin.model_func  = better_fin.models[data.model]
        fin.zla         = data.zla
        -- Network the necessary variables
        fin:setNetworkVariables()
    end

    local function makeBetterFinEnt(Player, ent, data)
        if !Player:CheckLimit("better_fin") then return false end

        local fin = ents.Create("better_fin")   -- Create a fin
        fin:Spawn()                             -- Spawn, parent, etc.
        fin:Activate()
        fin:SetParent(ent)
        ent:DeleteOnRemove(fin)

        updateBetterFinEnt(ent, fin, data)   -- Update it with the data
        ent.better_fin = fin            -- Assign the new entity to the phys_prop

        better_fin.add_to_table(fin)    -- Add the fin to the global table
        duplicator.StoreEntityModifier(ent, "better_fin", data)
        Player:AddCount("better_fin", fin)
        Player:AddCleanup("better_fin", fin)
    end

    duplicator.RegisterEntityModifier("better_fin", makeBetterFinEnt)

    -- Create or update a fin
    function TOOL:LeftClick( trace )
        if not trace.Hit then return false end

        -- Stage 0, fin parent entity not yet select it
        if self:GetStage() == 0 then
            if not trace.Entity:IsValid() or trace.Entity:GetClass() ~= "prop_physics" then return false end
            if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end
            self.trace_ent = trace.Entity
            self.trace_normal = trace.HitNormal
            self:SetStage(1)
            return true
        -- Stage 1, parent entity selected, selecting the forward vector
        else
            local entity = self.trace_ent
            local up = self.trace_normal
            local forward = trace.HitNormal
            forward = (forward -  up * up:Dot(forward)):GetNormalized()    -- Getting a vector perpendicular to the wing normal
            local right = forward:Cross(up)
            -- Get the orientation of the fin based on the forward vector and the angle to the right
            local angle = forward:Angle()
            -- Orient it to alight the forward and up vectors
            angle:RotateAroundAxis(forward, -math.deg(math.asin(math.Clamp(angle:Up():Dot(right), -1, 1))))
            -- Rotate it to match the selected zero lift angle
            local zla = math.Clamp(self:GetClientNumber("zla"), 0, 10)
            angle:RotateAroundAxis(right, zla)
            local data =
            {
                -- Load and validate the data
                pos         = Vector(0, 0, 0),  -- This might change in the future, but for now it's the local position of the parent entity's center
                ang         = entity:WorldToLocalAngles(angle),
                efficiency  = math.Clamp(self:GetClientNumber("efficiency"), 0, 100),    -- Clamp so people can't make trillion efficiency fins
                zla         = zla,
                model       = self:GetClientInfo("model")
            }
            -- Validate some extra data
            if not better_fin.models[data.model] then data.model = "wing" end   -- If flight model function doesn't exist, replace by a default one`

            -- If the entity does not have a fin
            if entity.better_fin == nil then
                if !self:GetSWEP():CheckLimit("better_fin") then return false end
                makeBetterFinEnt(self:GetOwner(), entity, data) -- Create a new one
                -- Add an undo
                undo.Create("better_fin")
                    undo.AddFunction(function()
                        if IsValid(entity.better_fin) then entity.better_fin:Remove() end
                    end)
                    undo.AddEntity(fin)
                    undo.SetPlayer(self:GetOwner())
                undo.Finish()
            else
                updateBetterFinEnt(entity, entity.better_fin, data)     -- Otherwise update the existing one
            end

            self:SetStage(0)
            return true
        end
    end

    -- Copy the settings from the target fin
    function TOOL:RightClick( trace )
        if self:GetStage() == 0 then
            if trace.Entity.better_fin ~= nil then
                local fin = trace.Entity.better_fin
                local ply = self:GetOwner()
                ply:ConCommand("better_fin_efficiency "..fin.efficiency)
                ply:ConCommand("better_fin_model "..fin.model)
                ply:ConCommand("better_fin_zla "..fin.zla)
                return true
            end
        else
            self:SetStage(0)
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

------------------- CLIENT---------------------
else
    function TOOL:LeftClick(trace)
        return true
    end

    function TOOL:RightClick(trace)
        return true
    end

    function TOOL:Reload(trace)
        return true
    end

    language.Add( "Tool.better_fin.name", "Better Fin Tool" )
    language.Add( "Tool.better_fin.desc", "Create fins that produce lift" )
    language.Add( "Undone_better_fin", "Undone Fin" )
    language.Add( "Cleanup_better_fin", "Better fin" )
    language.Add( "Cleaned_better_fin", "Cleaned up all Fins" )
    language.Add( "sboxlimit_better_fin", "You've reached the Fin-limit!" )

    TOOL.Information = {
        { name = "left_select",         stage = 0 },
        { name = "right_copy",          stage = 0 },
        { name = "reload_remove",       stage = 0 },
        { name = "left_get_forward",    stage = 1 },
        { name = "right_cancel",        stage = 1 }
    }

    language.Add("tool.better_fin.left_select",     "Left click to select the fin entity and define the normal vector")
    language.Add("tool.better_fin.right_copy",      "Right click to copy a fin's settings")
    language.Add("tool.better_fin.reload_remove",   "Press R to remove a fin from an entity")
    language.Add("tool.better_fin.left_get_forward","Left click to define the forward vector")
    language.Add("tool.better_fin.right_cancel",    "Right click to cancel")

    TOOL.ClientConVar = {
        efficiency      = 70,
        zla             = 10,       -- Zero lift angle
        show_HUD_always = 0,
        model           = "wing"
    }

    -- These must have the same name as the respective function, as the client ConVar uses this value to find the respective function
    local models_text =
    {
        wing =
        {
            name = "Wing",
            explanation = "Realistic wing model. Good lift-to-drag ratio when not stalling. Stalls at around 20 degrees of angle of attack"
        },
        simplified =
        {
            name = "Simplified",
            explanation = "Simplified \"air deflector\". Works simmiarly to fin2. Bad lift-to-drag ratio, but does not stall"
        }
    }

    -- Show information about the fin if the player hovers over it
    function showValuesFinHUD()
        local Player   = LocalPlayer()
        local entity   = Player:GetEyeTrace().Entity
        local Weapon   = Player:GetActiveWeapon()
        if (not IsValid(Player) or not IsValid(entity) or not IsValid(Weapon)) then return end

        -- Check if the toolgun is in hand, and if the better fin tool is selected
        local show_HUD_always = GetConVar("better_fin_show_HUD_always", 0):GetBool()
        if not show_HUD_always then
            if Weapon:GetClass() != "gmod_tool" or Player:GetInfo("gmod_toolmode") != "better_fin" then return end
        end

        local efficiency = entity:GetNWFloat("efficiency", -1)
        local model = entity:GetNWString("model", "")

        if efficiency != -1 and efficiency != nil then
            -- Set text-string for display
            local header = "Fin Properties"
            local text =
            {
                "Efficiency:    "..efficiency,
                "Flight model:  "..models_text[model].name
            }

            -- Box size and pos
            local box_w = 200
            local box_h = 120
            local screen_pos = Vector(ScrW()+box_w, ScrH()-box_h, 0) / 2
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

    function drawFinOrientation()
        local Player   = LocalPlayer()
        local entity   = Player:GetEyeTrace().Entity
        local Weapon   = Player:GetActiveWeapon()
        if (not IsValid(Player) or not IsValid(entity) or not IsValid(Weapon)) then return end
        -- Check if the toolgun is in hand, and if the better fin tool is selected
        local show_HUD_always = GetConVar("better_fin_show_HUD_always", 0):GetBool()
        if not show_HUD_always then
            if Weapon:GetClass() != "gmod_tool" or Player:GetInfo("gmod_toolmode") != "better_fin" then return end
        end

        local efficiency = entity:GetNWFloat("efficiency", -1)
        if efficiency != -1 and efficiency != nil then
            local angle = entity:LocalToWorldAngles(entity:GetNWAngle("angle", Angle( 0, 0, 0 )))
            render.SetColorMaterialIgnoreZ()
            render.DrawBeam(entity:GetPos(), entity:GetPos() + angle:Up()*20,       1, 30, 30, Color(0,0,255))  -- Up beam
            render.DrawBeam(entity:GetPos(), entity:GetPos() + angle:Forward()*20,  1, 30, 30, Color(255,0,0))  -- Forward beam
        end
    end
    hook.Add("PostDrawTranslucentRenderables", "draw_fin_orientation", drawFinOrientation)

    function TOOL.BuildCPanel(CPanel)
        -- Flight model selector
        local cbox = CPanel:ComboBox("Flight model", "better_fin_model")
        cbox:AddChoice("Wing", "wing", true)
        cbox:AddChoice("Simplified", "simplified", false)
        local model_explanation = CPanel:ControlHelp(models_text.wing.explanation)

        function cbox:OnSelect(index, text, data)
            model_explanation:SetText(models_text[data].explanation)
            GetConVar("better_fin_model"):SetString(data)
        end

        -- Slider to select the efficiency
        CPanel:NumSlider("Efficiency", "better_fin_efficiency", 0, 100, 0)
        CPanel:ControlHelp("Controls how much force (both lift and drag) the fin produces")
        -- Slider for the zero-lift angle
        CPanel:NumSlider("Zero-lift angle", "better_fin_zla", 0, 10, 0)
        CPanel:ControlHelp("The negative angle of attack at which the fin produces no lift. When the fin is level, a high ZLA will provide more lift, while setting it to zero will provide none")
        -- Checkbox to select wether the HUD always shows, or only with the toolgun
        CPanel:CheckBox("Always show the HUD", "better_fin_show_HUD_always")
    end
end













