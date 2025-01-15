local Developer = GetConVar("developer")
local ENT = FindMetaTable("Entity")
local NPC = FindMetaTable("NPC")


--[[
==================================================================================================
                    TIMER / TICK STUFF
==================================================================================================
--]]


-- Do something next tick/frame
function conv.callNextTick( func, ... )

    local argtbl = table.Pack(...)

    timer.Simple(0, function()
        func(unpack(argtbl))
    end)

end 


-- Do something after a certain amount of ticks/frames
function conv.callAfterTicks( ticknum, func, ... )

    conv.callNextTick( function( ... )

        if ticknum <= 0 then
            func(...)
        else
            conv.callAfterTicks( ticknum-1, func, ... )
        end
        

    end, ... )

end


-- An ipairs for loop that runs the code every tick
-- 'func' sends key and value as arguments
-- Example:
-- conv.tickForEach( tbl, function(k, v)
--     print(k, v)
-- end)
-- Slow and useless maybe idk lol
function conv.tickForEach( tbl, func )
    for k, v in ipairs(tbl) do
        conv.callAfterTicks( k, func, k, v )
    end
end


--[[
==================================================================================================
                    WRAPPER FUNCTIONS
==================================================================================================
--]]


-- Create a wrapper function around the desired function
-- 'preFunc' - Function to run before running the target function, passes the same arguments
-- 'postFunc' - Code to run AFTER running the function, passes a table of return values followed by the function arguments,
--  You can override the return values by returning something else in either of the functions
function conv.wrapFunc( uniqueID, func, preFunc, postFunc )
    if !isfunction(func) then
        error("The function does not exist!")
    end


    -- Store original func
    conv.wrapFunc_OriginalFuncs = conv.wrapFunc_OriginalFuncs or {}
    if !conv.wrapFunc_OriginalFuncs[uniqueID] then
        conv.wrapFunc_OriginalFuncs[uniqueID] = func
    end


    local ogfunc = conv.wrapFunc_OriginalFuncs[uniqueID]
    if !isfunction(ogfunc) then
        return -- Func was removed?
    end


    local wrappedFunc = function(...)
        if isfunction(preFunc) then
            local returnValuesPre = table.Pack( preFunc( ... ) )

            if istable(returnValuesPre) && !table.IsEmpty(returnValuesPre) then
                return unpack(returnValuesPre)
            end
        end

        local returnValues = table.Pack( ogfunc(...) )


        if isfunction(postFunc) then
            local returnValuesPost = table.Pack( postFunc( returnValues, ... ) )

            if !table.IsEmpty(returnValuesPost) then
                return unpack(returnValuesPost)
            end
        end


        return unpack(returnValues)
    end

    return wrappedFunc
end


-- Same as above, but the original function is lost
function conv.wrapFunc2( func, preFunc, postFunc )
    if !isfunction(func) then
        error("The function does not exist!")
    end

    local wrappedFunc = function(...)
        if isfunction(preFunc) then
            preFunc( ... )
        end

        local returnValues = table.Pack( func(...) )


        if isfunction(postFunc) then
            local returnValues = table.Pack( postFunc( returnValues, ... ) )

            if !table.IsEmpty(returnValues) then
                return unpack(returnValues)
            end
        end


        return unpack(returnValues)
    end

    return wrappedFunc
end


--[[
==================================================================================================
                    FILES / INCLUDE
==================================================================================================
--]]


function conv.addFile( File, directory )
	local prefix = string.lower( string.Left( File, 3 ) )
    local isServerFile = (prefix == "sv_" or File=="sv.lua")
    local isClientFile = (prefix == "cl_" or File=="cl.lua")
    local isSharedFile = !isClientFile && !isServerFile

	if isServerFile && SERVER then

		include( directory .. File )
        return
    
    end


    if isClientFile then
		if SERVER then
			AddCSLuaFile( directory .. File )
		elseif CLIENT then
			include( directory .. File )
		end

        return
    end


	if isSharedFile then
		AddCSLuaFile( directory .. File )
		include( directory .. File )
	end
end


function conv.includeDir( directory )
	directory = directory .. "/"

	local files, directories = file.Find( directory .. "*", "LUA" )

	for _, v in ipairs( files ) do
		if string.EndsWith( v, ".lua" ) then
			conv.addFile( v, directory )
		end
	end

	for _, v in ipairs( directories ) do
		conv.includeDir( directory .. v )
	end
end

--[[
==================================================================================================
                    DEBUG
==================================================================================================
--]]


-- Prints but only if "developer" is more than 1
-- Also prints to all SuperAdmins on dedicated servers
function conv.devPrint(...)
    if Developer:GetInt() < 1 && !(SERVER && game.IsDedicated()) then return end

    if SERVER && game.IsDedicated() then
        for _, superadmin in player.Iterator() do
            if superadmin:IsSuperAdmin() then
                local clprintStr = "[SERVER] "
                local clColStr = ""

                for _, v in ipairs(table.Pack(...)) do
                    if IsColor(v) then
                        clColStr = "Color("..v.r..", "..v.g..", "..v.b.."), "
                        continue 
                    end

                    clprintStr = clprintStr..tostring(v)
                end

                local LuaSend = 'MsgC( '..clColStr..'"'..clprintStr..'" ) MsgN()'

                superadmin:SendLua( LuaSend )
            end
        end
    end

    local args = table.Pack(...)
    local foundCol = false
    for _, arg in ipairs(args) do
        if IsColor(arg) then
            MsgC(arg, SERVER && "[SERVER] " or "[CLIENT] ")
            foundCol = true
            break
        end
    end

    if !foundCol then
        MsgC(SERVER && "[SERVER] " or "[CLIENT] ")
    end

    MsgC(...)
    MsgN()
end


-- Debug Overlay QOL
-- https://wiki.facepunch.com/gmod/debugoverlay
-- conv.overlay("Something", function()
--     return {}
-- end)
function conv.overlay( funcname, argsFunc )
    if !Developer:GetBool() then return end
    local args = argsFunc()
    debugoverlay[funcname](unpack(args))
end


--[[
==================================================================================================
                    PLAYER VISIBILITY
==================================================================================================
--]]


-- Checks if any player on the server can see this position right now
function conv.playersSeePos( pos )
    for _, ply in player.Iterator() do
        if conv.plyCanSeePos( ply, pos ) then
            return true
        end
    end
end



-- Checks if a player on the server can see this position right now
function conv.plyCanSeePos( ply, pos )
    local eyePos = ply:GetShootPos()
    local eyeAngles = ply:EyeAngles()
    local direction = (pos - eyePos):GetNormalized() -- Get the direction from player's eye to the position
    local angleDifference = math.deg(math.acos(eyeAngles:Forward():Dot(direction))) -- Calculate angle difference

    local tr = util.TraceLine({
        start = eyePos,
        endpos = pos,
        mask = MASK_VISIBLE,
    })

    return angleDifference <= ply:GetFOV() && !tr.Hit
end


--[[
==================================================================================================
                    NPC SPAWNING
==================================================================================================
--]]


function conv.getSpawnMenuNPCs()
    return conv._SpawnMenuNPCs
end


--[[
==================================================================================================
                    ENTITY TIMER / TICK FUNCTIONS
==================================================================================================
--]]



-- Call a method for this ent next tick
function ENT:CONV_CallNextTick( methodnameorfunc, ... )
    local function func( me, ... )
        if !IsValid(me) then return end
        
        if isstring(methodnameorfunc) then
            me[methodnameorfunc](me, ...)
        elseif isfunction(methodnameorfunc) then
            methodnameorfunc(...)
        else
            error("Invalid type in CONV_CallNextTick.")
        end
    end

    conv.callNextTick( func, self, ... )
end


-- Temporarily set a variable on an entity
-- This assumes the variable does not exist currently, so it will be nil after 'duration'
function ENT:CONV_TempVar( name, value, duration )

    self[name] = value

    timer.Create("TempVar"..name..self:EntIndex(), duration, 1, function()
        if IsValid(self) then
            self[name] = nil
        end
    end)

end


-- Remove a temporary variable
function ENT:CONV_RemoveTempVar( name )
    timer.Remove("TempVar"..name..self:EntIndex())
    self[name] = nil
end


-- Temporarily sets variables created by ENT:NetworkVar()
function ENT:CONV_TempNetVar( funcName, value, duration )

    local setFuncName = "Set"..funcName
    local getFuncName = "Get"..funcName

    if !self[setFuncName.."NetValBefore"] then
        self[setFuncName](name, value)
    end

    self[setFuncName.."NetValBefore"] = self[setFuncName.."NetValBefore"] or self[getFuncName]()

    timer.Create("TempNetVar"..setFuncName..self:EntIndex(), duration, 1, function()
        if IsValid(self) then
            self[setFuncName](value)
            self[setFuncName.."NetValBefore"] = nil
        end
    end)

end


-- Like timer.Simple but with a built in valid check and varargs
function ENT:CONV_TimerSimple(dur, func, ...)

    local args = table.Pack(...)

    timer.Simple(dur, function()
        if IsValid(self) then
            func(unpack(args))
        end
    end)
end


-- Like timer.Create but with a built in valid check and varargs
-- Also automatically concatinates the name with the entity's entity index
function ENT:CONV_TimerCreate(name, dur, reps, func, ...)
    local timerName = name..self:EntIndex()
    local args = table.Pack(...)
    
    timer.Create(timerName, dur, reps, function()
        if !IsValid(self) then
            timer.Remove(timerName)
            return
        end

        func(unpack(args))
    end)
end


-- Like timer.Remove but automatically concatinates the name with the entity's entity index
function ENT:CONV_TimerRemove(name)
    timer.Remove(name..self:EntIndex())
end


--[[
==================================================================================================
                    ENTITY UTILITIES
==================================================================================================
--]]


-- Stores the entity in a table, and removes it from said table when the entity is no longer valid
function ENT:CONV_StoreInTable( tbl )
    if !istable(tbl) then return end

    table.insert(tbl, self)

    self:CallOnRemove("RemoveFrom"..tostring(tbl), function()
        if istable(tbl) then
            table.RemoveByValue(tbl, self)
        end
    end)
end


-- Maps the entity to a table where itself is used as a key
-- Removes itself from said table when no longer valid
-- 'Value' is optional and is 'true' by default
function ENT:CONV_MapInTable( tbl, value )
    if !istable(tbl) then return end

    tbl[self] = ( value or true )

    self:CallOnRemove("RemoveMappedFrom"..tostring(tbl), function()
        if istable(tbl) then
            tbl[self] = nil
        end
    end)
end


-- Adds a hook for this entity that terminates once it is no longer valid
-- 'Type' is the type of hook, such as "Think"
-- 'func' is the function to run in the hook. First argument is 'self'.
-- 'name' is optional and allows multiple hooks of the same type to be added to the ent (if they have different names)
function ENT:CONV_AddHook( Type, func, name )
    local id = "CONV_EntityHook_"..self:EntIndex().."_"..Type
    if name then id = id .. name end

    hook.Add(Type, id, function(...)
        if !IsValid(self) then
            return
        end

        func(self, ...)
    end)

    self:CallOnRemove("CONV_RemoveHook_"..id, function()
        hook.Remove(Type, id)
    end)
end


--[[
==================================================================================================
                    NPC UTILITIES
==================================================================================================
--]]


-- Checks if the NPC has a certain capability
function NPC:CONV_HasCapability( cap )
    return bit.band(self:CapabilitiesGet(), cap) == cap
end