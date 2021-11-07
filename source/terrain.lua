
-- ~~~~~~~~~~~~
-- terrain.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- A terrain generator for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local Terrain = {}



-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~

local function initialiseGround()
-- initialise the ground array to be a flat line
-- add bases to garrObjects

	-- this creates a big flat space at the start of the game
	for i = 0, (gintScreenWidth * 0.90) do
		garrGround[i] = gintScreenHeight * 0.80
	end

	Terrain.generate(gintScreenWidth * 2)

end


local function getLastBaseID(baseType)
-- scans the garrObjects array and returns the index (id) of the last object in the array of type baseType
-- returns 0 if no base of that type found
-- accepts basetypeBuilding meaning any building

	local lastBaseID = 0
	for i = 1, #garrObjects do
		-- if the object type == base type then capture ID
		-- if the baseType is any building then test for building1 or building2
		if (garrObjects[i].objecttype == baseType) or 
			(baseType == enum.basetypeBuilding and (garrObjects[i].objecttype == enum.basetypeBuilding1 or garrObjects[i].objecttype == enum.basetypeBuilding2)) then
			lastBaseID = i
		end
	end
	return lastBaseID
end


-- ~~~~~~~~~~~~~~~~~
-- Public functions
-- ~~~~~~~~~~~~~~~~~

function Terrain.initialize()
    initialiseGround()
end



function Terrain.generate(intAmountToCreate)
-- gets a predictable terrain value (deterministic) base on x



	-- create terrain
	local groundTableSize = #garrGround
	local gameID = math.pi

	local terrainmaxheight = (gintScreenHeight * 0.90)
	local terrainminheight = (gintScreenHeight * 0.65)
	local terrainstep = (terrainmaxheight - terrainminheight) / 2
	local terrainoctaves = 8

	repeat
		terrainoctaves = terrainoctaves + 1
	until 2 ^ terrainoctaves >= terrainstep

	for i = groundTableSize + 1, (groundTableSize + intAmountToCreate) do

		local newgroundaltitude
		for oct = 1, terrainoctaves do
			newgroundaltitude = garrGround[i-1] + (love.math.noise(i / 2^oct, gameID) - 0.5) * 2 ^ (terrainoctaves - oct - 1)
		end
		if newgroundaltitude < terrainminheight then newgroundaltitude = terrainminheight end
		if newgroundaltitude > terrainmaxheight then newgroundaltitude = terrainmaxheight end

		table.insert(garrGround, newgroundaltitude)
		
	end
	
	groundTableSize = #garrGround
	
	-- add some buildings before adding fuel

	repeat
		local lastBuildingIndex
		local nextBuildingX	
	
		-- get the index/id of the last building
		lastBuildingIndex = getLastBaseID(enum.basetypeBuilding)
		if lastBuildingIndex == 0 then
			nextBuildingX = gintOriginX + love.math.random(200,2000)
		else
			nextBuildingX = garrObjects[lastBuildingIndex].x + love.math.random(200,2000)
		end	
		if nextBuildingX <= groundTableSize then
			local newBaseType = love.math.random(7,8)		-- hack
			cobjs.CreateObject(newBaseType, nextBuildingX)
		else
			break
		end		
	until not true	-- infinite loop using a break statement		
	
	-- add fuel bases after the buildings so they can draw layered if need be

	-- create as many fuel bases as the current terrain allows
	repeat
		local lastFuelBaseIndex
		local nextBaseX	
	
		lastFuelBaseIndex = getLastBaseID(enum.basetypeFuel)
		if lastFuelBaseIndex == 0 then
			nextBaseX = cf.round(gintScreenWidth * 1.5,0)	--! this should probably use originX and not screenwidth
		else
			nextBaseX = cf.round(garrObjects[lastFuelBaseIndex].x * 1.3,0)
		end
		
		if nextBaseX <= groundTableSize then
			-- create base
			cobjs.CreateObject(enum.basetypeFuel, nextBaseX)
		else
			break
		end		
	until not true	-- infinite loop using a break statement
	
	-- TODO: find a way to remove terrain that is behind the lander and likely never needed

end



function Terrain.draw(worldoffset)
-- draws the terrain as a bunch of lines that are 1 pixel in length

	love.graphics.setColor(1,1,1,1)
	-- ensure we have enough terrain
	if (worldoffset + gintScreenWidth) > #garrGround then
		Terrain.generate(gintScreenWidth * 2)
	end

	for i = 1, #garrGround - 1 do
		if i < worldoffset - (gintScreenWidth) or i > worldoffset + (gintScreenWidth) then
			-- don't draw. Do nothing
		else
			love.graphics.line(i - worldoffset, garrGround[i], i + 1 - worldoffset, garrGround[i+1])
			-- draw a vertical line straight down to reflect solid terra firma
			-- love.graphics.setColor(115/255,115/255,115/255,1)
			love.graphics.setColor(205/255,92/255,92/255,1)
			love.graphics.line(i - worldoffset, garrGround[i],i - worldoffset, gintScreenHeight)
			love.graphics.setColor(1,1,1,1)
		end
	end
end


return Terrain