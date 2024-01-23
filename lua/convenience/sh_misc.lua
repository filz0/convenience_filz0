local PLY = FindMetaTable("Player")


    -- Check if any player can see this position
function PLY:PosInView( pos )

    -- mafs idk chat gpt wrote this
    local eyePos = self:GetShootPos()
    local eyeAngles = self:EyeAngles()
    local direction = (pos - eyePos):GetNormalized() -- Get the direction from player's eye to the position
    local angleDifference = math.deg(math.acos(eyeAngles:Forward():Dot(direction))) -- Calculate angle difference

    local tr = util.TraceLine({
        start = eyePos,
        endpos = pos,
        mask = MASK_VISIBLE,
    })

    return angleDifference <= self:GetFOV()*1.25 && !tr.Hit

end


    -- Insert an entity into a table, which is later removed once it is no longer valid
function table.InsertEntity( tbl, ent )

    if !IsValid(ent) then return end -- Must be ent

    table.insert(tbl, ent)
    ent:CallOnRemove("RemoveFrom_"..tostring(tbl), function()
        table.RemoveByValue(tbl, ent)
    end)

end