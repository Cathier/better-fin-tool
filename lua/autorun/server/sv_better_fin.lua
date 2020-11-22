
better_fin = 
{
	fins = {},
	fin_idx = 0
}

function better_fin.initialize_()
	better_fin.fins = {}	-- Global table of fins
	better_fin.fin_idx = 0	-- Index of the next fin to check

	print("[Better Fin] Initializing")
end
hook.Add("Initialize", "better_fininitialize_", better_fin.initialize_)

function better_fin.think_()
	better_fin.next_think = better_fin.next_think or CurTime()
	if CurTime() > better_fin.next_think then
		-- Update the ancestor of one fin per tick
		local fin = better_fin.fins[better_fin.fin_idx]
		if IsValid(fin) then 
			fin.ancestor = BF_getAncestor(fin) 	-- Update the ancestor
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
function BF_getAncestor(ent)
    if not ent:IsValid() then return nil end

    local ancestor = ent
    while ancestor:GetParent():IsValid() do
        ancestor = ancestor:GetParent()
    end
    return ancestor
end