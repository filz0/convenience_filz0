if game.SinglePlayer() then return end

local conv_sendaddons = 
	CreateConVar("conv_sendaddons", "0", FCVAR_ARCHIVE, 
		"Send all mounted workshop addons to clients when they join the server.")

if !conv_sendaddons:GetBool() then 
	MsgN("[CONV] conv_sendaddons is disabled, skipping addon sending.")
	return 
end

MsgN("[CONV] Adding workshop resources for clients to download...")

for k, v in ipairs(engine.GetAddons()) do
	if !v.mounted then 
		MsgN("[CONV] Skipping", v.title, "as it is not mounted.") 
		continue 
	end
	
    resource.AddWorkshop( v.wsid )
	MsgN("[CONV] Running resource.AddWorkshop for ", v.title, "...")
end