AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include("shared.lua")

CreateClientConVar("fin2_delete_dup_onremove", 1, true, false, "Delete the duplication on remove or not (Fin II)")

function ENT:Initialize()
	math.randomseed(CurTime())
	self.Entity:SetMoveType( MOVETYPE_NONE )                 
end   

function ENT:OnRemove()
	if (GetConVar("fin2_delete_dup_onremove"):GetBool() == true) then
		duplicator.ClearEntityModifier(self.Entity:GetParent(), "better_fin")
		self.Entity:GetParent().better_fin = nil
	end
end

function ENT:Think()
	if not self.ancestor:IsValid() then 
		self.ancestor = BF_getAncestor(self)
	end

	local physObj = self.ancestor:GetPhysicsObject()
	
	local velocity = physObj:GetVelocity()
	local wingNormal = self:GetForward()	-- The forward of the fin entity is alligned with the normal
	
	local liftMagnitude = -wingNormal:Dot(velocity) * velocity:Length()
	local lift = wingNormal * liftMagnitude * self.efficiency * physObj:GetMass() * 1e-6
	
	physObj:ApplyForceOffset(lift, self:GetPos())
	
	self.Entity:NextThink( CurTime())
	return true 
 end
