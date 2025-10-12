local ENT = FindMetaTable("Entity")
local PLAYER = FindMetaTable("Player")


--[[
==================================================================================================
                    DAMAGE
==================================================================================================
--]]

-- Returns an CTakeDamageInfo object with some basic values set
function conv.damageBasic(damage, dmgtype, pos, attacker)
    local dmginfo = DamageInfo()
    dmginfo:SetAttacker(attacker)
    dmginfo:SetInflictor(attacker)
    dmginfo:SetDamage(damage)
    dmginfo:SetDamageType(dmgtype)
    dmginfo:SetDamagePosition(pos)
    return dmginfo
end

--[[
==================================================================================================
                    NPC SPAWNING
==================================================================================================
--]]

-- Spawn a NPC from the spawn menu
function conv.createSpawnMenuNPC( SpawnMenuClass, pos, wep, beforeSpawnFunc )
    -- Find NPC in spawn menu
    local SpawnMenuTable = ents._SpawnMenuNPCs[SpawnMenuClass]

    -- Check if zbase npc
    local isZBaseNPC = ZBaseInstalled and ZBaseNPCs[SpawnMenuClass]
    
    -- No such NPC
    if not SpawnMenuTable then
        ErrorNoHaltWithStack("No such NPC found: '", SpawnMenuClass, "'\n")
        return
    end

    -- Create NPC
    local NPC = ents.Create( isZBaseNPC and SpawnMenuClass or SpawnMenuTable.Class )

    -- No such NPC
    if not IsValid(NPC) then
        ErrorNoHaltWithStack("No such NPC found: '", SpawnMenuTable.Class, "'\n")
        return
    end

    -- Position
    if isvector(pos) then
        NPC:SetPos(pos)
    end

    -- Default weapons if none if provided
    wep = wep or (SpawnMenuTable.Weapons and table.Random(SpawnMenuTable.Weapons))
    if isstring(wep) then
        NPC:Give( wep )
    end

    -- Key values
    if SpawnMenuTable.KeyValues then
        for key, value in pairs(SpawnMenuTable.KeyValues) do
            NPC:SetKeyValue(key, value)
        end
    end

    -- Set stuff
    if SpawnMenuTable.Model then NPC:SetModel(SpawnMenuTable.Model) end
    if SpawnMenuTable.Skin then NPC:SetSkin(SpawnMenuTable.Skin) end
    if SpawnMenuTable.Health then NPC:SetMaxHealth(SpawnMenuTable.Health) NPC:SetHealth(SpawnMenuTable.Health) end
    if SpawnMenuTable.Material then NPC:SetMaterial(SpawnMenuTable.Material) end
    if SpawnMenuTable.SpawnFlags then NPC:SetKeyValue("spawnflags", SpawnMenuTable.SpawnFlags) end

    if isfunction(beforeSpawnFunc) then
        beforeSpawnFunc( NPC )
    end

    -- Spawn and Activate
    NPC:Spawn()
    NPC:Activate()

    return NPC
end


-- Spawns an entity for a short duration allowing you to obtain info about it
function conv.getEntInfo( cls, func )
    local ent = ents.Create(cls)
    if not IsValid(ent) then
        ErrorNoHaltWithStack("No such ENT found: '", cls, "'\n")
        return
    end

    ent:CONV_AddHook( "EntityEmitSound", function() return false end )

    ent:Spawn()
    ent:Activate()

    conv.callNextTick(function( Ent )
        func(Ent)
        Ent:Remove()
    end, ent)
end


--[[
==================================================================================================
                    Spawnflags
==================================================================================================
--]]

function ENT:CONV_SetSpawnFlags(...)
    self:SetKeyValue("spawnflags", bit.bor(...))
end

function ENT:CONV_AddSpawnFlags(...)
    self:SetKeyValue("spawnflags", bit.bor(self:GetSpawnFlags(), ...))
end

function ENT:CONV_RemoveSpawnFlags(...)
    self:SetKeyValue("spawnflags", bit.band(self:GetSpawnFlags(), bit.bnot(...)))
end


--[[
==================================================================================================
                                           CALL ON CLIENT
==================================================================================================
--]]

-- Used to call a function on a client from the server -- 
function conv.callOnClient( ply, ent, functionName, ... )
	if not isstring(functionName) then return end

	local data = {...} or {}
    
    data = conv.tableToString( data )
    ent = IsValid(ent) and tostring( ent:EntIndex() ) or ent or ""
    
    net.Start( "CONV_CallOnClient" )
    net.WriteString( ent )
    net.WriteString( functionName )
    net.WriteString( data )

    if ply and ( IsValid(ply) and ply:IsPlayer() or istable(ply) ) then
        net.Send( ply )
    else
        net.Broadcast()
    end
end


--[[
==================================================================================================
                    LUA RUN
==================================================================================================
--]]

-- Creates the lua_run entity to be used with related functions -- 
function conv.createLuaRun()
	CONV_LUA_RUN_ENT = ents.Create( "lua_run" )
	if IsValid(CONV_LUA_RUN_ENT) then
		CONV_LUA_RUN_ENT:SetName( "CONV_LUA_RUN_ENT" )
		CONV_LUA_RUN_ENT:Spawn()
	end
end

-- Creates a hook that runs whenever the set entity fires the specified output. -- 
function ENT:CONV_CreateOutputHook(entOutput, eventName, delay, repetitions)
	if not IsValid(CONV_LUA_RUN_ENT) then conv.createLuaRun() end
	
	delay = delay or 0
	repetitions = repetitions or -1
	
	self:Fire( "AddOutput", entOutput .. " CONV_LUA_RUN_ENT:RunPassedCode:hook.Run( '" .. eventName .. "' ):" .. delay .. ":" .. repetitions .. "" )
end

-- Creates a function that runs whenever the set entity fires the specified output. -- 
function ENT:CONV_CreateOutputFunction(entOutput, func, delay, repetitions)
	if not self or not IsValid(self) then return end
	if not IsValid(CONV_LUA_RUN_ENT) then conv.createLuaRun() end
	
	delay = delay or 0
	repetitions = repetitions or -1

	local hookID = entOutput .. self:GetClass() .. self:EntIndex()

	hook.Add(hookID, self, function() 

		local activator, caller = ACTIVATOR, CALLER
		func(self, activator, caller)

	end)

	self:Fire( "AddOutput", entOutput .. " CONV_LUA_RUN_ENT:RunPassedCode:hook.Run( '" .. hookID .. "' ):" .. delay .. ":" .. repetitions .. "" )
end

--[[
==================================================================================================
					UI
==================================================================================================
--]]

local scrWidth = 1920
local scrHeight = 1080

-- Used to get the width of the player's screen.
function conv.ScrW(ply)
    return ply.CONV_SCRNW
end

-- Used to get the height of the player's screen.
function conv.ScrH(ply)
    return ply.CONV_SCRNH
end

-- Used to properly scale position and width of an UI elemet to different screen resolutions.
function conv.ScrWScale(ply)
	return conv.ScrW(ply) / scrWidth
end

-- Used to properly scale position and height of an UI elemet to different screen resolutions.
function conv.ScrHScale(ply)
	return conv.ScrH(ply) / scrHeight
end

-- Returns the central point of the horizontal axis.
function conv.ScrWCenter(ply)
	return conv.ScrW(ply) / 2
end

-- Returns the central point of the vertical axis.
function conv.ScrHCenter(ply)
	return conv.ScrH(ply) / 2
end

function conv.displayOnEntity( name, ent, tab, dur, x, y, xAlign, yAlign )
    if not ent then return end
    conv.callOnClient( false, "conv", "displayOnEntity", name, ent, tab, dur, x, y, xAlign, yAlign )
end

--[[
==================================================================================================
					SKYBOX EDIT
==================================================================================================
--]]

-- Creates env_skypaint and sets the skybox texture to "painted" if not set currently
function conv.createSkyPaint()
    if CONV_SKYPAINT then return end

    CONV_SKYPAINT = ents.Create( "env_skypaint" )

    if CONV_SKYPAINT then
        CONV_SKYPAINT:Spawn()
        CONV_SKYPAINT:Activate()

        CONV_SKYPAINT.TopColor = Vector( 0.220000, 0.510000, 1.000000 )
        CONV_SKYPAINT.BottomColor = Vector( 0.919000, 0.929000, 0.992000 )
        CONV_SKYPAINT.FadeBias = 0.10000000149012
        CONV_SKYPAINT.HDRScale = 0.56000000238419

        CONV_SKYPAINT.StarLayers = 1
        CONV_SKYPAINT.DrawStars = true
        CONV_SKYPAINT.StarTexture = "skybox/clouds"
        CONV_SKYPAINT.StarSpeed = 0.029999999329448
        CONV_SKYPAINT.StarFade = 0.5
        CONV_SKYPAINT.StarScale = 2

        CONV_SKYPAINT.DuskIntensity = 2
        CONV_SKYPAINT.DuskScale = 0.5
        CONV_SKYPAINT.DuskColor = Vector( 1.000000, 1.000000, 1.000000 )

        CONV_SKYPAINT.SunSize = 0
        CONV_SKYPAINT.SunColor = Vector( 0.000000, 0.000000, 0.000000 )

        conv.editSkyPaintMain()
        conv.editSkyPaintStars()
        conv.editSkyPaintDusk()
        conv.editSkyPaintSun()

        RunConsoleCommand( "sv_skyname", "painted" )
    end
end 

-- Removes user created env_skypaint and restores the original skybox texture. Does nothing to the map spawned env_skypaint
function conv.removeSkyPaint()
    if not CONV_SKYPAINT or CONV_DEFAULT_SKYBOX == "painted" then return end
    CONV_SKYPAINT:Remove()
    CONV_SKYPAINT = nil
    RunConsoleCommand( "sv_skyname", CONV_DEFAULT_SKYBOX )
end

-- Allows to edit main atributes of the env_skypaint
function conv.editSkyPaintMain( TopColor, BottomColor, FadeBias, HDRScale )
    if not CONV_SKYPAINT then return end
    
    local TopColor = IsColor(TopColor) and TopColor:ToVector() or TopColor
    local BottomColor = IsColor(BottomColor) and BottomColor:ToVector() or BottomColor

    CONV_SKYPAINT:SetTopColor( TopColor or CONV_SKYPAINT.TopColor )
	CONV_SKYPAINT:SetBottomColor( BottomColor or CONV_SKYPAINT.BottomColor )
	CONV_SKYPAINT:SetFadeBias( FadeBias or CONV_SKYPAINT.FadeBias )
	CONV_SKYPAINT:SetHDRScale( HDRScale or CONV_SKYPAINT.HDRScale )
end

-- Allows to edit star atributes of the env_skypaint
function conv.editSkyPaintStars( DrawStars, StarTexture, StarLayers, StarScale, StarFade, StarSpeed )
    if not CONV_SKYPAINT then return end
    CONV_SKYPAINT:SetDrawStars( DrawStars or CONV_SKYPAINT.DrawStars )
    CONV_SKYPAINT:SetStarLayers( StarLayers or CONV_SKYPAINT.StarLayers )
    CONV_SKYPAINT:SetStarTexture( StarTexture or CONV_SKYPAINT.StarTexture )
	CONV_SKYPAINT:SetStarScale( StarScale or CONV_SKYPAINT.StarScale )
    CONV_SKYPAINT:SetStarFade( StarFade or CONV_SKYPAINT.StarFade )
    CONV_SKYPAINT:SetStarSpeed( StarSpeed or CONV_SKYPAINT.StarSpeed )
end

-- Allows to edit dusk atributes of the env_skypaint
function conv.editSkyPaintDusk( DuskIntensity, DuskScale, DuskColor )
    if not CONV_SKYPAINT then return end

    local DuskColor = IsColor(DuskColor) and DuskColor:ToVector() or DuskColor

    CONV_SKYPAINT:SetDuskIntensity( DuskIntensity or CONV_SKYPAINT.DuskIntensity )
    CONV_SKYPAINT:SetDuskScale( DuskScale or CONV_SKYPAINT.DuskScale )
	CONV_SKYPAINT:SetDuskColor( DuskColor or CONV_SKYPAINT.DuskColor )
end

-- Allows to edit sun atributes of the env_skypaint
function conv.editSkyPaintSun( SunSize, SunColor )
    if not CONV_SKYPAINT then return end

    local SunColor = IsColor(SunColor) and SunColor:ToVector() or SunColor

    CONV_SKYPAINT:SetSunSize( SunSize or CONV_SKYPAINT.SunSize )
	CONV_SKYPAINT:SetSunColor( SunColor or CONV_SKYPAINT.SunColor )
end

-- Allows you to edit env_sun
function conv.editEnvSun( SunSize, OverlaySize, SunColor, OverlayColor )
    if not CONV_ENV_SUN then return end

    local SunColor = isvector(SunColor) and SunColor:ToColor() or SunColor
    local OverlayColor = isvector(OverlayColor) and OverlayColor:ToColor() or OverlayColor

    CONV_ENV_SUN:SetKeyValue( "size", SunSize or CONV_ENV_SUN.SunSize )
	CONV_ENV_SUN:SetKeyValue( "overlaysize", OverlaySize or CONV_ENV_SUN.OverlaySize )

    local suncolor = SunColor and Format( "%i %i %i", SunColor.r, SunColor.g, SunColor.b ) or CONV_ENV_SUN.SunColor
    CONV_ENV_SUN:SetKeyValue( "suncolor", suncolor )

    local overlaycolor = OverlayColor and Format( "%i %i %i", OverlayColor.r, OverlayColor.g, OverlayColor.b ) or CONV_ENV_SUN.OverlayColor
	CONV_ENV_SUN:SetKeyValue( "overlaycolor", overlaycolor )
end

--[[
==================================================================================================
                    DMGINFO UTILITIES
==================================================================================================
--]]

function conv.dmgInfoGetDamager(dmginfo)
    local att = IsValid(dmginfo:GetAttacker()) and dmginfo:GetAttacker()
    local inf = IsValid(dmginfo:GetInflictor()) and dmginfo:GetInflictor()
    local wep = IsValid(dmginfo:GetWeapon()) and dmginfo:GetWeapon()
    return att or inf or wep
end 


--[[
==================================================================================================
                    PLAYER UTILITIES
==================================================================================================
--]]

function PLAYER:CONV_SetPlayerClass(class)
    self:SetSaveValue("m_nControlClass", class or 1)
end

function PLAYER:CONV_GetPlayerClass()
    return self:GetInternalVariable("m_nControlClass")
end