-- CONV_LOAD_TIMES = (CONV_LOAD_TIMES && CONV_LOAD_TIMES + 1) or 1
-- print("CONV loaded "..CONV_LOAD_TIMES.." time(s)!")

local files = file.Find("convenience/*", "LUA")
if !files then return end

for _, filename in ipairs(files) do
    filename = "convenience/"..filename
    if string.StartsWith(filename, "cl_") then

        AddCSLuaFile(filename)

        if CLIENT then
            include(filename)
            MsgN(filename, " included")
        end

    elseif string.StartsWith(filename, "sh_") then

        AddCSLuaFile(filename)
        include(filename)
        MsgN(filename, " included")

    elseif string.StartsWith(filename, "sv_") && SERVER then

        include(filename)
        MsgN(filename, " included")

    end
end