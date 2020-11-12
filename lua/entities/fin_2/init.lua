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
	-- Find the ancestor
	local physObj = self.ent
	while IsValid(physObj:GetParent()) do
		physObj = physObj:GetParent()
	end
	physObj = physObj:GetPhysicsObject()
	if not physObj:IsValid() then return end
	
	local velocity = physObj:GetVelocity()
	local wingNormal = self:GetForward()	-- The forward of the fin entity is alligned with the normal
	
	local liftMagnitude = -wingNormal:Dot(velocity) * velocity:Length()
	local efficency = self.ent:GetNWFloat("efficency", -99999999)
	local lift = wingNormal * liftMagnitude * efficency * 1e-3
	
	print(physObj:GetPos() - self:GetPos())
	physObj:ApplyForceOffset(lift, self:GetPos())
	
	self.Entity:NextThink( CurTime())
	return true 
 end
