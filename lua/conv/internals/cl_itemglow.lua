--[[
==================================================================================================
                    MODULE BY relaxtakenotes
==================================================================================================
--]]
local istable = istable
local render = render
local Material = Material
local CreateMaterial = CreateMaterial
local hook = hook
local IsValid = IsValid

module( "conv_itemglow", package.seeall )

local MODE_NOTVISIBLE 		= 0
local MODE_VISIBLE 			= 1

local List, ListSize		= {}, 0
local RenderEnt				= NULL

local ENTS, SPEED	= 1, 2

function Add( ents, speed )

	if ( ListSize >= 255 ) then return end				--Maximum 255 reference values
	if ( not istable( ents ) ) then ents = { ents } end	--Support for passing Entity as first argument
	if ( ents[ 1 ] == nil ) then return end				--Do not pass empty tables
	
	local data = {
		[ ENTS ] = ents,
		[ SPEED ] = speed or 1,
	}
	
	ListSize = ListSize + 1
	List[ ListSize ] = data
	
end



function RenderedEntity()
	
	return RenderEnt
end
	


local function IsOnScreen(ent)

	local pos = ent:GetPos() + ent:OBBCenter()
	local screenPos = pos:ToScreen()

	return screenPos.visible
end



local tr = { collisiongroup = COLLISION_GROUP_WORLD, output = {} }
local function IsInWorld()

	local pos = EyePos()
	
	tr.start = pos
	tr.endpos = pos

	return util.TraceLine( tr ).HitWorld
end



local function IsValidScene()
	local scene = render.GetRenderTarget()

    return scene ~= nil
end



local function RenderModels(ents)

	for i = 1, #ents do

		local ent = ents[i]

		if IsValid(ent) then			

			if not ent:Alive() then return end
			if not IsOnScreen(ent) then return end

			RenderEnt = ent

			ent:DrawModel()

		end

	end
	
end



local function Render()

	if (IsInWorld()) then return end
	if (IsValidScene()) then return end

	
	for i = 1, ListSize do

		local data = List[i]

		if (data) then

			local ents = data[ENTS]
			local speed = data[SPEED]
			
			RenderModels(ents)

			local blend = math.abs( CurTime() * speed % 2 - 1 )
			render.SetBlend(blend)
			render.SuppressEngineLighting( true )
				RenderModels(ents)
			render.SuppressEngineLighting( false )
			render.SetBlend(1)

		end

	end

	RenderEnt = NULL

end



local function CONVRenderItemGlow()

	hook.Run( "CONVSetupItemGlow")

	if ( ListSize == 0 ) then return end

	Render()
	
	List, ListSize = {}, 0	
end



hook.Add("PreDrawOpaqueRenderables", "CONVRenderItemGlow", function(isDrawingDepth, isDrawSkybox, isDraw3DSkybox)
	if not isDrawingDepth and not isDrawSkybox and not isDraw3DSkybox then
    	CONVRenderItemGlow()	
	end
end)

hook.Add("PreDrawTranslucentRenderables", "CONVRenderItemGlow", function(isDrawingDepth, isDrawSkybox, isDraw3DSkybox)
    if not isDrawingDepth and not isDrawSkybox and not isDraw3DSkybox then
    	CONVRenderItemGlow()	
	end
end)


-- Helper function to apply outline fast effect using conv.callOnClient
function conv.addOutlineFast( hookName, ents, speed )

	if not ents then hook.Remove( "CONVSetupItemGlow", hookName ) return end

	hook.Add( "CONVSetupItemGlow", hookName, function()

		conv_itemglow.Add( ents, speed )

	end )

end
