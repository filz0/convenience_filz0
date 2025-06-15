NODE_TYPE_GROUND = 2
NODE_TYPE_AIR = 3
NODE_TYPE_CLIMB = 4
NODE_TYPE_WATER = 5

local SIZEOF_INT = 4
local SIZEOF_SHORT = 2

local SIZEOF_INT = 4
local SIZEOF_SHORT = 2
local AINET_VERSION_NUMBER = 37
local NUM_HULLS = 10
local MAX_NODES = 1500

CONV_AINNET_VER     = CONV_AINNET_VER || 0
CONV_MAP_VER        = CONV_MAP_VER || 0
CONV_NODES_ALL      = CONV_NODES_ALL || {}
CONV_NODES_GROUND   = CONV_NODES_GROUND || {}
CONV_NODES_AIR      = CONV_NODES_AIR || {}
CONV_NODES_CLIMB    = CONV_NODES_CLIMB || {}
CONV_NODES_WATER    = CONV_NODES_WATER || {}
--CONV_NODES_LINKS    = CONV_NODES_LINKS || {}
CONV_NODES_LOOKUP   = CONV_NODES_LOOKUP || {}

local function toUShort(b)

	local i = { string.byte( b, 1, SIZEOF_SHORT ) }
	
	return i[1] + i[2] * 256
	
end

local function toInt(b)

	local i = { string.byte( b, 1, SIZEOF_INT) }
	
	i = i[1] + i[2] * 256 + i[3] * 65536 + i[4] * 16777216
	
	if ( i > 2147483647 ) then return i -4294967296 end
	
	return i
	
end

local function ReadInt(f) return toInt( f:Read( SIZEOF_INT ) ) end
local function ReadUShort(f) return toUShort( f:Read( SIZEOF_SHORT ) ) end



-- Reads the .ain file for the current map and returns a table of AI nodes
function conv.parseNodeFile()

	local f = file.Open( "maps/graphs/" ..game.GetMap() .. ".ain", "rb", "GAME" )

    if (!f) then return end

    CONV_AINNET_VER     =  0
    CONV_MAP_VER        =  0
    CONV_NODES_ALL      = {}
    CONV_NODES_GROUND   = {}
    CONV_NODES_AIR      = {}
    CONV_NODES_CLIMB    = {}
    CONV_NODES_WATER    = {}
    --CONV_NODES_LINKS    = {}
    CONV_NODES_LOOKUP   = {}

    local ainet_ver = ReadInt(f)
    local map_ver = ReadInt(f)

    CONV_AINNET_VER = ainet_ver
    CONV_MAP_VER = map_ver

    if( ainet_ver != AINET_VERSION_NUMBER ) then

        MsgN("Unknown graph file")

        return
    end

    local numNodes = ReadInt(f)

    if ( numNodes > MAX_NODES || numNodes < 0 ) then

        MsgN("Graph file has an unexpected amount of nodes")
        return
    end

    for i = 1, numNodes do

        local v = Vector( f:ReadFloat(), f:ReadFloat(), f:ReadFloat() )
        local yaw = f:ReadFloat()
        local flOffsets = {}

        for i = 1, NUM_HULLS do
            flOffsets[i] = f:ReadFloat()
        end

        local nodetype = f:ReadByte()
        local nodeinfo = ReadUShort(f)
        local zone = f:ReadShort()
        
        local node = {
            pos = v,
            yaw = yaw,
            offset = flOffsets,
            type = nodetype,
            info = nodeinfo,
            zone = zone,
            neighbor = {},
            numneighbors = 0,
            link = {},
            numlinks = 0
        }

        table.insert( CONV_NODES_ALL, node )

    end

    --[[
    local numLinks = ReadInt(f)
    for i = 1, numLinks do

        local link = {}
        local srcID = f:ReadShort()
        local destID = f:ReadShort()
        local nodesrc = CONV_NODES_ALL[ srcID + 1 ]
        local nodedest = CONV_NODES_ALL[ destID + 1 ]

        if ( nodesrc && nodedest ) then
            table.insert( nodesrc.neighbor, nodedest )
            nodesrc.numneighbors = nodesrc.numneighbors + 1
            
            nodesrc.numlinks = nodesrc.numlinks + 1
            link.src = nodesrc
            link.srcID = srcID + 1
            table.insert( nodesrc.link, link )
            
            nodedest.numneighbors = nodedest.numneighbors + 1
            table.insert( nodedest.neighbor, nodesrc )
            
            nodedest.numlinks = nodedest.numlinks + 1
            link.dest = nodedest
            link.destID = destID + 1
            table.insert( nodedest.link, link )

        else 
            MsgN("Unknown link source or destination " .. srcID .. " " .. destID) 
        end

        local moves = {}

        for i = 1, NUM_HULLS do
            moves[i] = f:ReadByte()
        end

        link.move = moves
        table.insert( CONV_NODES_LINKS, link )
    end
    ]]

    for i = 1, numNodes do
        table.insert( CONV_NODES_LOOKUP, ReadInt(f) )
    end

	f:Close()

    for i = 1, #CONV_NODES_ALL do

        local node = CONV_NODES_ALL[i]
        local nodetype = node.type

        if nodetype == 2 then table.insert( CONV_NODES_GROUND, node )
		elseif nodetype == 3 then table.insert( CONV_NODES_AIR, node )
		elseif nodetype == 4 then table.insert( CONV_NODES_CLIMB, node )
		elseif nodetype == 5 then table.insert( CONV_NODES_WATER, node )
		end
    end

end