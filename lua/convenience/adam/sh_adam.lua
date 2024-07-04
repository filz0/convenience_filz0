local Developer = GetConVar("developer")



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


-- Create a wrapper function around the desired function
-- 'preFunc' - Function to run before running the target function, passes the same arguments
-- 'postFunc' - Code to run AFTER running the function, passes a table of return values followed by the function arguments,
--  you can override the return values by returning something else in this function
function conv.wrapFunc( uniqueID, func, preFunc, postFunc )
    if !isfunction(func) then
        error("The function does not exist!")
    end


    conv.wrapFunc_OriginalFuncs = conv.wrapFunc_OriginalFuncs or {}


    if !conv.wrapFunc_OriginalFuncs[uniqueID] then
        conv.wrapFunc_OriginalFuncs[uniqueID] = func
    end


    local wrappedFunc = function(...)
        if isfunction(preFunc) then
            preFunc( ... )
        end


        local returnValues = table.Pack( conv.wrapFunc_OriginalFuncs[uniqueID](...) )


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