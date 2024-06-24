// 'CONV' - Just a bunch of general convenient functions


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
        if ply:PosInView(pos) then
            return true
        end
    end
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


-- DEPRECATED
function conv.getSpawnMenuNPCs()
    return table.Copy(ents._SpawnMenuNPCs)
end


-- Create a iterator function that iterates through a table
function conv.createIpairIterFunc( tbl )

    local inext = ipairs({})
    local Cache = nil
    
    local func = function()
        if ( Cache == nil ) then Cache = tbl end
        return inext, Cache, 0
    end

    return func

end