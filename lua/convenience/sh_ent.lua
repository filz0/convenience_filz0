local ENT = FindMetaTable("Entity")


    -- Temporarily set a variable on an entity
function ENT:TempVar( name, value, duration )

    local ValBefore = self[name]
    self[name] = value


    timer.Create("TempVar"..name..self:EntIndex(), duration, 1, function()
        if IsValid(self) then
            self[name] = ValBefore
        end
    end)

end


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