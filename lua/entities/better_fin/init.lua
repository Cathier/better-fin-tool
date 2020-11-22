AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include("shared.lua")

-- Networks key variables onto the fin's parent
function ENT:setNetworkVariables()
	local parent = self:GetParent()
	parent:SetNWFloat("efficiency", self.efficiency)
end

-- Removes the network variables from the fin's parent
function ENT:removeNetworkVariables()
	local parent = self:GetParent()
	parent:SetNWFloat("efficiency", -1)		-- To signal removal of fin (nil does not work for some reason)
end

function ENT:Initialize()
	self.Entity:SetMoveType( MOVETYPE_NONE )   
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
		self.ancestor = BF_getAncestor(self)				-- Find the new ancestor
	end

	local physObj = self.ancestor:GetPhysicsObject()

	-- Get the linear velocity of the fin based on the linear and rotational velocities of the ancestor
	local velocity = physObj:GetVelocityAtPoint(self:GetPos())
	local wingNormal = self:GetForward()	-- The forward of the fin entity is alligned with the normal
	
	local liftMagnitude = -wingNormal:Dot(velocity) * velocity:Length()
	local lift = wingNormal * liftMagnitude * self.efficiency * physObj:GetMass() * 5e-7
	
	physObj:ApplyForceOffset(lift, self:GetPos())
	
	self.Entity:NextThink(CurTime())
	return true 
end



