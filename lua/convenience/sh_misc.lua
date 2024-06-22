// Uncategorized...



--[[
==================================================================================================
                    LOCALS (IGNORE)
==================================================================================================
--]]


local Developer = GetConVar("developer")
local PLY = FindMetaTable("Player")
local MaxAmmoCvar = GetConVar("gmod_maxammo")


--[[
==================================================================================================
                    PLAYER
==================================================================================================
--]]


    -- Check if the player can see this position
function PLY:PosInView( pos )

    local eyePos = self:GetShootPos()
    local eyeAngles = self:EyeAngles()
    local direction = (pos - eyePos):GetNormalized() -- Get the direction from player's eye to the position
    local angleDifference = math.deg(math.acos(eyeAngles:Forward():Dot(direction))) -- Calculate angle difference

    local tr = util.TraceLine({
        start = eyePos,
        endpos = pos,
        mask = MASK_VISIBLE,
    })


    return angleDifference <= self:GetFOV() && !tr.Hit

end



--[[
==================================================================================================
                    TABLE
==================================================================================================
--]]


    -- Insert an entity into a table, which is later removed once it is no longer valid
function table.InsertEntity( tbl, ent )

    if !IsValid(ent) then return end -- Must be ent

    table.insert(tbl, ent)
    ent:CallOnRemove("RemoveFrom_"..tostring(tbl), function()
        table.RemoveByValue(tbl, ent)
    end)

end



--[[
==================================================================================================
                    DEBUG
==================================================================================================
--]]



    -- debug.Trace but you can choose which level to start from
function debug.ConvTraceFrom(level)
	while true do

		local info = debug.getinfo( level, "Sln" )
		if ( !info ) then break end

		if ( info.what ) == "C" then
			MsgN( string.format( "\t%i: C function\t\"%s\"", level, info.name ) )
		else
			MsgN( string.format( "\t%i: Line %d\t\"%s\"\t\t%s", level, info.currentline, info.name, info.short_src ) )
		end

		level = level + 1

	end
end


--[[
==================================================================================================
                    GAME
==================================================================================================
--]]

    -- Just like https://wiki.facepunch.com/gmod/game.GetAmmoMax
    -- But it respects the gmod_maxammo cvar
function game.GetCurrentAmmoMax(id)
    local cvarMax = MaxAmmoCvar:GetInt()


    if cvarMax <= 0 then
        return game.GetAmmoMax(id)
    else
        return cvarMax
    end

end