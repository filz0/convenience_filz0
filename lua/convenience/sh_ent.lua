local ENT = FindMetaTable("Entity")


    -- Call a method for this ent next tick
function ENT:CallNextTick( methodname, ... )

    local function func( me, ... )
        if IsValid(me) then
            me[methodname](me, ...)
        end
    end


    conv.callNextTick( func, self, ... )

end


    -- Temporarily set a variable on an entity
function ENT:TempVar( name, value, duration )

    self[name.."ValBefore"] = self[name.."ValBefore"] or self[name]
    self[name] = value

    -- print(name, "set to", value)


    timer.Create("TempVar"..name..self:EntIndex(), duration, 1, function()
        if IsValid(self) then
            self[name] = ValBefore
            self[name.."ValBefore"] = nil
            -- print(name, "set back to", ValBefore)
        end
    end)

end


    -- DEPRECATED
    -- A regular timer, but just for entities
    -- Will stop if the ent is not valid
    -- Id does not have to include entindex, that is done automatically
    -- Returns timer name
function ENT:ConvTimer( id, delay, func, reps )

    local TimerName = id..self:EntIndex()


    timer.Create(TimerName, delay, reps or 1, function()

        if !IsValid(self) then
            timer.Remove(TimerName)
            return
        end

        func()

    end)


    return TimerName

end


    -- Timer simple for entities with a built-in valid check
function ENT:Conv_STimer( delay, func, ... )
    local tbl = table.Pack(...)
    timer.Simple(delay, function()
        if IsValid(self) then
            func(unpack(tbl))
        end
    end)
end


    -- Check if an entity has the supplied flags
function ENT:Conv_HasFlags( flags )
    if !IsValid(self) then return false end
    return bit.band(self:GetFlags(), flags)==flags
end