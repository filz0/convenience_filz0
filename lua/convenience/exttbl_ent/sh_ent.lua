local ENT = FindMetaTable("Entity")


-- Check if an entity has the supplied flags
function ENT:CONV_HasFlags( flags )
    if !IsValid(self) then return false end
    return bit.band(self:GetFlags(), flags)==flags
end


-- Call a method for this ent next tick
function ENT:CONV_CallNextTick( methodname, ... )

    local function func( me, ... )
        if IsValid(me) then
            me[methodname](me, ...)
        end
    end


    conv.callNextTick( func, self, ... )

end


-- Temporarily set a variable on an entity
function ENT:CONV_TempVar( name, value, duration )

    self[name.."ValBefore"] = self[name.."ValBefore"] or self[name]
    self[name] = value


    timer.Create("TempVar"..name..self:EntIndex(), duration, 1, function()
        if IsValid(self) then
            self[name] = ValBefore
            self[name.."ValBefore"] = nil

        end
    end)

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