fintool = {}

function fintool.initialize_()
	fintool.maxwind = 360
	fintool.minwind = 0
	fintool.wind = Vector(math.Rand(fintool.minwind, fintool.maxwind), math.Rand(fintool.minwind, fintool.maxwind), 0)
end

hook.Add("Initialize", "finitialize_", fintool.initialize_ )

function fintool.think_()
	fintool.nextthink = fintool.nextthink or CurTime()
	if CurTime() > fintool.nextthink then
		local minwind = fintool.minwind or 0
		local maxwind = fintool.maxwind or 360

		fintool.maxdelay = fintool.maxdelay or 120
		fintool.wind = Vector(math.Rand(minwind, maxwind), math.Rand(minwind, maxwind), 0)
		fintool.nextthink = fintool.nextthink + math.Rand(0, fintool.maxdelay)

        fintool.maxeff = fintool.maxeff or 250
	end
end
hook.Add( "Think", "finthink_", fintool.think_ )

-- Min/Max delay
function fintool.setmaxdelay(player, command, arg)
	if player:IsAdmin() or player:IsSuperAdmin() then fintool.maxdelay = arg[1] end
end 
concommand.Add("fintool_setmaxwinddelay",fintool.setmaxdelay)

-- Min/Max wind
function fintool.setmaxwind(player, command, arg)
	if player:IsAdmin() or player:IsSuperAdmin() then fintool.maxwind = arg[1] or 360 end
end 

concommand.Add("fintool_setmaxwind",fintool.setmaxwind)

function fintool.setminwind(player, command, arg)
	if player:IsAdmin() or player:IsSuperAdmin() then fintool.minwind = arg[1] or 0 end
end 

concommand.Add("fintool_setminwind",fintool.setminwind)

-- Max eff.
function fintool.setmaxeff(player, command, arg)
	if player:IsAdmin() or player:IsSuperAdmin() then fintool.maxeff = arg[1] end
end 

concommand.Add("fintool_setmaxeff", fintool.setmaxeff)