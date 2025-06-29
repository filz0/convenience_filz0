local ENT = FindMetaTable("Entity")

local function isTE(self, ent)
    return ent == self && "valid" || "invalid"
end

CONV_CALLON_FILTER = {
    ['Generic'] = function(self, ...)
        return {}
    end,

    ['EntityEmitSound'] = function(self, ...)
        local data = ...
        return { data }
    end,

    ['EntityFireBullets'] = function(self, ...)
        local ent, data = ...
        return { valid = isTE(self, ent), data }
    end,

    ['PostEntityFireBullets'] = function(self, ...)
        local ent, data = ...
        return { valid = isTE(self, ent), data }
    end,

    ['OnEntityCreated'] = function(self, ...)
        local ent = ... 
        return { ent }
    end,

    ['EntityTakeDamage'] = function(self, ...)
        local ent, dmginfo = ...
        return { valid = isTE(self, ent), dmginfo }
    end,

    ['EntityDealDamage'] = function(self, ...)
        local ent1, ent2, dmginfo = ...
        return { valid = isTE(self, ent1), ent2, dmginfo }
    end,

    ['OnNPCKilled'] = function(self, ...)
        local ent, attacker, inflictor = ...
        return { valid = isTE(self, ent), attacker, inflictor }
    end,

    ['OnKilledNPC'] = function(self, ...)
        local ent, npc, inflictor = ...
        return { valid = isTE(self, ent), npc, inflictor }
    end,

    ['ScaleNPCDamage'] = function(self, ...)
        local ent, hitgroup, dmginfo = ...
        return { valid = isTE(self, ent), hitgroup, dmginfo }
    end,

    ['NPCDamageScale'] = function(self, ...)
        local ent, npc, hitgroup, dmginfo = ...
        return { valid = isTE(self, ent), npc, hitgroup, dmginfo }
    end,

    ['GravGunOnDropped'] = function(self, ...)
        local ply, ent = ...
        return { valid = isTE(self, ent), ply }
    end,

    ['GravGunOnPickedUp'] = function(self, ...)
        local ply, ent = ...
        return { valid = isTE(self, ent), ply }
    end,

    ['GravGunPickupAllowed'] = function(self, ...)
        local ply, ent = ...
        return { valid = isTE(self, ent), ply }
    end,

    ['GravGunPunt'] = function(self, ...)
        local ply, ent = ...
        return { valid = isTE(self, ent), ply }
    end,

    ['EntityRemoved'] = function(self, ...)
        local ent, bool = ...
        return { valid = isTE(self, ent), bool }
    end,
}

--[[
==================================================================================================
					SHARED VERSION OF CONV CALLONLIB
==================================================================================================
--]]

--local hookName = "EntityEmitSound"
function ENT:CONV_CallOnHook( hookName, name, func )

    local mytable = self:GetTable()

    if !mytable then return end

    local callback = "CONVCallOn_" .. hookName

    mytable[callback] = mytable[callback] || {}

    if isfunction(func) then
      
        mytable[callback][ name ] = { Name = name, Function = func }

    else

        mytable[callback][ name ] = nil

    end

    local function callOnFunction( ... )    

        --local hookData = {...} 
        --local thisEnt = table.Flip( hookData )[self]
        --thisEnt = hookData[thisEnt] || self

        local data = isfunction(CONV_CALLON_FILTER[hookName]) && CONV_CALLON_FILTER[hookName](self, ...) || CONV_CALLON_FILTER['Generic'](self, ...)       

        if ( !IsValid(self) || !self[callback] || ( data.valid && data.valid == "invalid" ) ) then return end
                
        return self[callback][ name ].Function(unpack(data))        

    end

    hook.Add( hookName, "CONV_CALLONLIB", callOnFunction )

end

------------------------------------------------------------------------------------------------------