AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

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
	
	local curvel = physobj:GetVelocity()
	local curup = self:GetForward()
	
	local vec1 = curvel
	local vec2 = curup
	vec1 = vec1 - 2*(vec1:Dot(vec2))*vec2
	local sped = vec1:Length()
	
	local finalvec = curvel
	local modf = math.abs(curup:Dot(curvel:GetNormalized()))
	local nvec = (curup:Dot(curvel:GetNormalized()))
	
	if (self.pln == 1) then
		
		if nvec > 0 then
			vec1 = vec1 + (curup * 10)
		else
			vec1 = vec1 + (curup * -10)
		end
		
		finalvec = vec1:GetNormalized() * (math.pow(sped, modf) - 1)
		finalvec = finalvec:GetNormalized()
		finalvec = (finalvec * self.efficiency) + curvel
	end
	
	if (self.lift != "lift_none") then
		if (self.lift == "lift_normal") then
			local liftmul = 1 - math.abs(nvec)
			finalvec = finalvec + (curup * liftmul * curvel:Length() * self.efficiency) / 700
		else
			local liftmul = (nvec / math.abs(nvec)) - nvec
			finalvec = finalvec + (curup * curvel:Length() * self.efficiency * liftmul) / 700
		end
	end
	
	finalvec = finalvec:GetNormalized()
	finalvec = finalvec * curvel:Length()
	
	if (self.wind == 1) then
		local wind = ((2 * (fintool.wind:Dot(curup)) * curup - fintool.wind)) * (math.abs(fintool.wind:Dot(curup)) / 10000)
		wind = wind * (self.efficiency / 50)
		finalvec = finalvec + wind
	end
	
	if (self.cline == 1) then
		local trace = {
			start = self.ent:GetPos(),
			endpos = self.ent:GetPos() + Vector(0, 0, -1000000),
			mask = 131083
		}
		local trc = util.TraceLine(trace)
		
		local MatType = trc.MatType
		
		if (MatType == 67 || MatType == 77) then
			local heatvec = Vector(0, 0, 100)
			local cline = ((2 * (heatvec:Dot(curup)) * curup - heatvec)) * (math.abs(heatvec:Dot(curup)) / 1000)
			finalvec = finalvec + (cline * (self.efficiency / 50))
		end
		
	end
	
	
	physobj:SetVelocity(finalvec)
	
	
	
	self.Entity:NextThink( CurTime())
	return true 
 end
