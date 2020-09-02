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
		duplicator.ClearEntityModifier(self.Entity:GetParent(), "fin2")
		self.Entity:GetParent().Fin2_Ent = nil
	end
end

 function ENT:Think()
	local physobj = self.ent:GetPhysicsObject()
	if !physobj:IsValid() then return end
	
	local velocity = physobj:GetVelocity()
	local wingNormal = self:GetUp()
	
	local liftMagnitude = -wingNormal:Dot(velocity) * velocity:Length()
	local lift = wingNormal * liftMagnitude * eff
	
	physobj:ApplyForceCenter(lift)
	
	self.Entity:NextThink( CurTime())
	return true 
 end
