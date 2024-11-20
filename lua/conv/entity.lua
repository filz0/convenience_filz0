local ENTITY = FindMetaTable("Entity")
if ( !ENTITY ) then return end

function ENTITY:SetSpawnFlags(...)
    self:SetKeyValue("spawnflags", bit.bor(...))
end

function ENTITY:AddSpawnFlags(...)
    self:SetKeyValue("spawnflags", bit.bor(self:GetSpawnFlags(), ...))
end

function ENTITY:RemoveSpawnFlags(...)
    self:SetKeyValue("spawnflags", bit.band(self:GetSpawnFlags(), bit.bnot(...)))
end