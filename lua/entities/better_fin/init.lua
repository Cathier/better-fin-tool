AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include("shared.lua")

-- Networks key variables onto the fin's parent
function ENT:setNetworkVariables()
    local parent = self:GetParent()
    -- Variables to display in the HUD
    parent:SetNWFloat("efficiency", self.efficiency)
    parent:SetNWString("model", self.model)
    -- Orientation of the fin to display the orientation arrows
    local local_ang = parent:WorldToLocalAngles(self:GetAngles())
    parent:SetNWAngle("angle", local_ang)
end

-- Removes the network variables from the fin's parent
function ENT:removeNetworkVariables()
    local parent = self:GetParent()
    parent:SetNWFloat("efficiency", -1)		-- To signal removal of fin (nil does not work for some reason)
end

function ENT:Initialize()
    self:SetMoveType( MOVETYPE_NONE )
    self.last_think = CurTime()
end

function ENT:OnRemove()
    local parent = self:GetParent()

    duplicator.ClearEntityModifier(parent, "better_fin")	-- Clear the duplicator's entity modifier
    parent.better_fin:removeNetworkVariables()				-- Remove the networked variables from the parent
    parent.better_fin = nil									-- Remove the reference to the fin entity
end

function ENT:Think()
    if not IsValid(self.ancestor) then
        self.ancestor = better_fin.getAncestor(self)	-- Find the new ancestor
    end

    local phys_obj = self.ancestor:GetPhysicsObject()
    local delta_t = CurTime() - self.last_think

    self.model_func(phys_obj, self, delta_t)	-- Call the flight model function

    self.last_think = CurTime()
    self:NextThink(CurTime())
    return true
end



