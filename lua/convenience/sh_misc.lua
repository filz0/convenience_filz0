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

    return angleDifference <= self:GetFOV() && !tr.Hit

end


    -- Insert an entity into a table, which is later removed once it is no longer valid
function table.InsertEntity( tbl, ent )

    if !IsValid(ent) then return end -- Must be ent

    table.insert(tbl, ent)
    ent:CallOnRemove("RemoveFrom_"..tostring(tbl), function()
        table.RemoveByValue(tbl, ent)
    end)

end




    
if SERVER then

    -- Spawn a NPC from the spawn menu
    function ents.CreateSpawnMenuNPC( SpawnMenuClass, pos, wep )


        -- Find NPC in spawn menu
        local SpawnMenuTable = ents.__SpawnMenuNPCs__ && ents.__SpawnMenuNPCs__[SpawnMenuClass] or list.Get("NPC")[SpawnMenuClass]
        if !SpawnMenuTable then
            ErrorNoHaltWithStack("No such NPC found: '", SpawnMenuClass, "'\n")
            return
        end
        

        -- Create NPC
        local NPC = ents.Create( SpawnMenuTable.Class )
        if !IsValid(NPC) then
            ErrorNoHaltWithStack("No such NPC found: '", SpawnMenuTable.Class, "'\n")
            return
        end


        -- Position
        NPC:SetPos(pos)


        -- Give weapon
        if SpawnMenuTable.Weapons then

            local wep = wep or table.Random(SpawnMenuTable.Weapons)

            if wep then
                NPC:Give( wep )
            end

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


        -- Spawn and Activate
        NPC:Spawn()
        NPC:Activate()


        return NPC


    end

end