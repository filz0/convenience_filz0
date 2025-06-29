--[[
==================================================================================================
					HOOK EXPANSION
==================================================================================================
--]]

hook.Add("OnNPCKilled", "CONV_COMPATIBILITY", function(npc, attacker, inflictor)    
    hook.Run( "OnKilledNPC", attacker, npc, inflictor )
    hook.Run( "OnKilledNPC", inflictor, npc, attacker )
end)

hook.Add("EntityTakeDamage", "CONV_COMPATIBILITY", function(ent, dmginfo) 
    local attacker = dmginfo:GetAttacker()
    if IsValid(attacker) then return hook.Run( "EntityDealDamage", attacker, ent, dmginfo ) end

    local inflictor = dmginfo:GetInflictor()
    if IsValid(inflictor) then return hook.Run( "EntityDealDamage", inflictor, ent, dmginfo ) end
end)

hook.Add("ScaleNPCDamage", "CONV_COMPATIBILITY", function(npc, hitgroup, dmginfo) 
    local attacker = dmginfo:GetAttacker()
    if IsValid(attacker) then return hook.Run( "NPCDamageScale", attacker, npc, hitgroup, dmginfo ) end

    local inflictor = dmginfo:GetInflictor()
    if IsValid(inflictor) then return hook.Run( "NPCDamageScale", inflictor, npc, hitgroup, dmginfo ) end
end)