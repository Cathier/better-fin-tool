better_fin =
{
    fins = {},      -- Global table of fins
    fin_idx = 0,    -- Index of the next fin to check
    models = {}     -- Table of flight model functions
}

function better_fin.initialize_()
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

-- Why did I have to do this?
function better_fin.sign(val)
    if val < 0 then return -1 else return 1 end
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

-- Filters (to avoid spazz) and clamps the fin acceleration
local function filterAcceleration(fin, accel)
    -- Filter
    accel = fin.last_accel and fin.last_accel * 0.6 + accel * 0.4 or accel
    -- Clamp
    accel = accel:Length() > 200 and accel:GetNormalized() * 200 or accel
    fin.last_accel = accel

    return accel
end

-- Basic wing, starts stalling at roughly 15 degrees
-- Modeled after a real symmetrical airfoil, shifted by the zero lift angle
-- https://www.desmos.com/calculator/mdhzwcpj2k
function better_fin.models.wing(phys_obj, fin, delta_t)
    local vel = phys_obj:GetVelocityAtPoint(fin:GetPos())
    local vel_normalized = vel:GetNormalized()
    local wing_normal = fin:GetUp()
    local wing_forward = fin:GetForward()
    local wing_right = fin:GetRight()
    -- The lift vector is perpendicular to the velocity and coplanar with the wing's normal vector
    local lift_vec = wing_right:Cross(vel):GetNormalized()
    local drag_vec = -vel_normalized

    -- Get the angle of attack
    local aoa = -math.asin(wing_normal:Dot(vel_normalized))
    -- 0.40404372 is equal to the 23.15 degrees seen in the desmos link, in radians
    local lift_coef = math.abs(aoa) < 0.40404372 and 1.1*math.sin(6*aoa) or math.sin(2*aoa)
    local drag_coef = 0.9*(1.1 - math.cos(2*aoa))

    local lift_magnitude = lift_coef * vel:LengthSqr()
    local drag_magnitude = drag_coef * vel:LengthSqr()


    local acceleration = (lift_vec*lift_magnitude + drag_vec*drag_magnitude) * fin.efficiency * 1e-6
    acceleration = filterAcceleration(fin, acceleration)
    local force = acceleration * phys_obj:GetMass() * delta_t

    phys_obj:ApplyForceOffset(force, fin:GetPos())
end

-- Simplified wing, works mostly like fin2
function better_fin.models.simplified(phys_obj, fin, delta_t)
    -- Get the linear velocity of the fin based on the linear and rotational velocities of the ancestor
    local velocity = phys_obj:GetVelocityAtPoint(fin:GetPos())
    local wing_normal = fin:GetUp()

    local lift_magnitude = -wing_normal:Dot(velocity) * velocity:Length()

    local acceleration = wing_normal * lift_magnitude * fin.efficiency * 1e-6
    acceleration = filterAcceleration(fin, acceleration)
    local force = acceleration * phys_obj:GetMass() * delta_t

    phys_obj:ApplyForceOffset(force, fin:GetPos())
end