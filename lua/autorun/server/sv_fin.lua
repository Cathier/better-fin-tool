--[[

Fin tool II

by Austin "Q42" Fox

This addon is not for stealing. K THX.

---
#1
---
Edited : 01.10.2017
File: fin2.lua
By : ravo Norway

Changes :
        Added support for viewing settings when hovering over a
        prop with Fin 2 attached to it.
---
#2
---
Edited : 02.10.2017
File: init.lua
By : ravo Norway

Changes :
        Replaced "DotProduct" with "Dot" for future support.
---
#3
---
Edited : 07.02.2017
File: fin2.lua and init.lua
By : ravo Norway

Changes :
        Updated the VGUI. Fixed the "ULib-bug". Fixed pos. and angle, and added another option to that to activate or not in the VGUI.
]]

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
		fintool.maxdelay = fintool.maxdelay or 120
		fintool.wind = Vector(math.Rand(fintool.minwind, fintool.maxwind), math.Rand(fintool.minwind, fintool.maxwind), 0)
		fintool.nextthink = fintool.nextthink + math.Rand(0, fintool.maxdelay)
        --
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
	if player:IsAdmin() or player:IsSuperAdmin() then fintool.maxwind = arg[1] end
end 

concommand.Add("fintool_setmaxwind",fintool.setmaxwind)

function fintool.setminwind(player, command, arg)
	if player:IsAdmin() or player:IsSuperAdmin() then fintool.minwind = arg[1] end
end 

concommand.Add("fintool_setminwind",fintool.setminwind)

-- Max eff.
function fintool.setmaxeff(player, command, arg)
	if player:IsAdmin() or player:IsSuperAdmin() then fintool.maxeff = arg[1] end
end 

concommand.Add("fintool_setmaxeff", fintool.setmaxeff)