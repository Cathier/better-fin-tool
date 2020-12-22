
better_fin = 
{
	fins = {},
	fin_idx = 0,
	models = {}
}

function better_fin.initialize_()
	better_fin.fins = {}	-- Global table of fins
	better_fin.fin_idx = 0	-- Index of the next fin to check

	better_fin.models = {}	-- Table of flight model functions

	print("[Better Fin] Initializing")
end
hook.Add("Initialize", "better_fininitialize_", better_fin.initialize_)

function better_fin.think_()
	better_fin.next_think = better_fin.next_think or CurTime()
	if CurTime() > better_fin.next_think then
		-- Update the ancestor of one fin per tick
		local fin = better_fin.fins[better_fin.fin_idx]
		if IsValid(fin) then 
			fin.ancestor = better_fin.getAncestor(fin) 	-- Update the ancestor
		else
			better_fin.remove_from_table(better_fin.fin_idx)	-- Fin was deleted
		end

		better_fin.fin_idx = better_fin.fin_idx + 1			-- Increment the index of the fin to check
		if better_fin.fin_idx > table.getn(better_fin.fins) then better_fin.fin_idx = 0 end	-- Loop around
	end
end
hook.Add("Think", "better_finthink_", better_fin.think_)

-- Adds a fin entity to the global table
function better_fin.add_to_table(fin)
	table.insert(better_fin.fins, better_fin.fin_idx+1, fin)
end
-- Removes a fin entity from the global table
function better_fin.remove_from_table(idx)
	table.remove(better_fin.fins, idx)
end

-- Returns the ancestor (parent of the parent...) of an entity
function better_fin.getAncestor(ent)
    if not ent:IsValid() then return nil end

    local ancestor = ent
    while ancestor:GetParent():IsValid() do
        ancestor = ancestor:GetParent()
    end
    return ancestor
end

-- Basic wing, starts stalling at roughly 15 degrees
-- Modeled after a real symmetrical airfoil, shifted by the zero lift angle
function better_fin.models.wing(phys_obj, fin, delta_t)
	local velocity = phys_obj:GetVelocityAtPoint(fin:GetPos())
	local wing_normal = fin:GetForward()



	-- https://www.desmos.com/calculator/mdhzwcpj2k
end

-- Simplified wing, works mostly like fin2
function better_fin.models.simplified(phys_obj, fin, delta_t)
	-- Get the linear velocity of the fin based on the linear and rotational velocities of the ancestor
	local velocity = phys_obj:GetVelocityAtPoint(fin:GetPos())
	local wing_normal = fin:GetForward()
	
	local lift_magnitude = math.Clamp(-wing_normal:Dot(velocity) * velocity:Length(), -1e6, 1e6)	-- Clamp the magnitude to avoid spazz
	local lift = wing_normal * lift_magnitude * fin.efficiency * phys_obj:GetMass() * delta_t * 3e-5
	
	phys_obj:ApplyForceOffset(lift, fin:GetPos())
end