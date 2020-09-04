AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include("shared.lua")

CreateClientConVar("better_fin_delete_dup_onremove", 1, true, false, "Delete the duplication on remove or not (Fin II)")

function ENT:Initialize()
	math.randomseed(CurTime())
	self.Entity:SetMoveType( MOVETYPE_NONE )                 
end   

function ENT:OnRemove()
	if (GetConVar("better_fin_delete_dup_onremove"):GetBool() == true) then
		duplicator.ClearEntityModifier(self.Entity:GetParent(), "better_fin")
		self.Entity:GetParent().better_fin_Ent = nil
	end
end

 function ENT:Think()
	local physobj = self.ent:GetPhysicsObject()
	if !physobj:IsValid() then return end
	
	local velocity = physobj:GetVelocity()
	local wingNormal = self:GetForward()
	
	local liftMagnitude = -wingNormal:Dot(velocity) * velocity:Length()
	local lift = wingNormal * liftMagnitude * self.coefficient / 100.0
	
	physobj:ApplyForceCenter(lift)
	
	self.Entity:NextThink( CurTime())
	return true 
 end
