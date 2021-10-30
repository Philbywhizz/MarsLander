local functions = {}

function functions.AddScreen(strNewScreen)
	table.insert(garrCurrentScreen, strNewScreen)
end

function functions.RemoveScreen()
	table.remove(garrCurrentScreen)
	if #garrCurrentScreen < 1 then
	
		--if success then
			love.event.quit()       --! this doesn't dothe same as the EXIT button
		--end
	end
end

function functions.SwapScreen(newscreen)
-- swaps screens so that the old screen is removed from the stack
-- this adds the new screen then removes the 2nd last screen.

    fun.AddScreen(newscreen)
    table.remove(garrCurrentScreen, #garrCurrentScreen - 1)
end

function functions.GetTerrainNoise(intAmountToCreate)
-- gets a predictable terrain value (deterministic) base on x

	local groundtablesize = #garrGround
	
	local gameID = math.pi
	
	local terrainmaxheight = (gintScreenHeight * 0.90)
	local terrainminheight = (gintScreenHeight * 0.65)
	local terrainstep = (terrainmaxheight - terrainminheight) / 2
	local terrainoctaves = 8
	
	repeat
		terrainoctaves = terrainoctaves + 1
	until 2 ^ terrainoctaves >= terrainstep
	
	for i = groundtablesize + 1, groundtablesize + intAmountToCreate do
	
		local newgroundaltitude
		for oct = 1, terrainoctaves do
			newgroundaltitude = garrGround[i-1] + (love.math.noise(i / 2^oct, gameID) - 0.5) * 2 ^ (terrainoctaves - oct - 1)
		end
		if newgroundaltitude < terrainminheight then newgroundaltitude = terrainminheight end
		if newgroundaltitude > terrainmaxheight then newgroundaltitude = terrainmaxheight end

		table.insert(garrGround, newgroundaltitude)
	end
end

function functions.GetLanderMass(Lander)
-- return the mass of all the bits on the lander

	local result = 0

	-- all the masses are stored in this table so add them up
	for i = 1, #Lander.mass do
		result = result + Lander.mass[i]
	end
	
	-- add the mass of the fuel
	result = result + Lander.fuel
	
	return result
end

function functions.SaveGameSettings()
-- save game settings so they can be autoloaded next session
	local savefile
	local serialisedString
	local success, message
	local savedir = love.filesystem.getSource()
	
    savefile = savedir .. "/" .. "settings.dat"
    serialisedString = bitser.dumps(garrGameSettings)
    success, message = nativefs.write(savefile, serialisedString )
end

function functions.LoadGameSettings()

    local savedir = love.filesystem.getSource()
    love.filesystem.setIdentity( savedir )
    
    local savefile, contents

    savefile = savedir .. "/" .. "settings.dat"
    contents, _ = nativefs.read(savefile) 
	local success
    success, garrGameSettings = pcall(bitser.loads, contents)		--! should do pcall on all the "load" functions
	
	if success == false then
		garrGameSettings = {}
	end
	
	--[[ FIXME:
	-- This is horrible bugfix and needs refactoring. If a player doesn't have
	-- a settings.dat already then all the values in garrGameSettings table are 
	-- nil. This sets some reasonable defaults to stop nil value crashes.
	]]--
	if garrGameSettings.PlayerName == nil then
		garrGameSettings.PlayerName = gstrDefaultPlayerName
	end
	if garrGameSettings.HostIP == nil then
		garrGameSettings.HostIP = "127.0.0.1"
	end
	if garrGameSettings.HostPort == nil then
		garrGameSettings.HostPort = "6000"
	end
	if garrGameSettings.FullScreen == nil then
		garrGameSettings.FullScreen = false
	end
end

function functions.SaveGame()
-- uses the globals because too hard to pass params

--! for some reason bitser throws runtime error when serialising true / false values.

    local savefile
    local contents
    local success, message
    local savedir = love.filesystem.getSource()
    
    savefile = savedir .. "/" .. "landers.dat"
    serialisedString = bitser.dumps(garrLanders)
    success, message = nativefs.write(savefile, serialisedString )
    
    savefile = savedir .. "/" .. "ground.dat"
    serialisedString = bitser.dumps(garrGround)
    success, message = nativefs.write(savefile, serialisedString )
    
    savefile = savedir .. "/" .. "objects.dat"
    serialisedString = bitser.dumps(garrObjects)    -- 
    success, message = nativefs.write(savefile, serialisedString )   
	
	lovelyToasts.show("Game saved",3, "middle")
    
end

function functions.LoadGame()
    
    local savedir = love.filesystem.getSource()
    love.filesystem.setIdentity( savedir )
    
    local savefile
    local contents

    savefile = savedir .. "/" .. "landers.dat"
    contents, _ = nativefs.read( savefile) 
    garrLanders = bitser.loads(contents)    

    savefile = savedir .. "/" .. "ground.dat"
    contents, _ = nativefs.read( savefile) 
    garrGround = bitser.loads(contents)   
   
    savefile = savedir .. "/" .. "objects.dat"
    contents, _ = nativefs.read(savefile) 
    garrObjects = bitser.loads(contents)  
    
  
end

function functions.GetDistanceToClosestBase(xvalue, intBaseType)
-- returns two values: the distance to the closest base, and the object/table item for that base
-- if there are no bases (impossible) then the distance value returned will be -1
-- note: if distance is a negative value then the Lander has not yet passed the base

	local closestdistance = 0
	local closestbase = {}
	local absdist
	local dist
	
	for k,v in pairs(garrObjects) do
		if v.objecttype == intBaseType then
			absdist = math.abs(xvalue - (v.x + 85))			-- the + bit is an offset to calculate the landing pad and not the image
			dist = (xvalue - (v.x + 85))						-- same but without the math.abs
			if closestdistance == 0 or absdist <= closestdistance then
				closestdistance = absdist
				closestbase = v
			end
		end
	end
	
	-- now we have the closest base, work out the distance to the landing pad for that base
	local realdist = xvalue - (closestbase.x + 85)			-- the + bit is an offset to calculate the landing pad and not the image

	return  realdist, closestbase

end

function functions.IsOnLandingPad(intBaseType)
-- returns a true / false value

	local mydist, _ = fun.GetDistanceToClosestBase(garrLanders[1].x, intBaseType)
	if mydist >= -80 and mydist <= 40 then
		return true
	else
		return false
	end
end

function functions.InitialiseGround()
-- initialise the ground array to be a flat line
-- add bases to garrObjects

	-- this creates a big flat space at the start of the game
	for i = 0, (gintScreenWidth * 0.90) do
		garrGround[i] = gintScreenHeight * 0.80
	end
	
	fun.GetTerrainNoise(gintScreenWidth * 2)

	-- Place bases
	local basedistance = cf.round(gintScreenWidth * 1.5,0)
	for i = 1, 20 do
		cobjs.CreateObject(enum.basetypeFuel, basedistance)		-- 2 = fuel base
		basedistance = cf.round(basedistance * 1.3,0)
		if basedistance > #garrGround then fun.GetTerrainNoise(basedistance * 2) end
	end
	
	-- place random buildings
	for i = 1, 50 do
		local bolPlacementOkay = false
		local rndnum
		repeat
			rndnum = love.math.random(1, #garrGround)
			local disttobase, _ = fun.GetDistanceToClosestBase(rndnum, enum.basetypeFuel)
			if disttobase <= 250 and disttobase >= -250 then
				-- too close to fuel base
			else
				bolPlacementOkay = true
			end
		until bolPlacementOkay
		cobjs.CreateObject(enum.basetypeBuilding1, rndnum)
	end
	
	-- place random buildings
	for i = 1, 50 do
		local bolPlacementOkay = false
		local rndnum
		repeat
			rndnum = love.math.random(1, #garrGround)
			local disttobase, _ = fun.GetDistanceToClosestBase(rndnum, enum.basetypeFuel)
			if disttobase <= 250 and disttobase >= -250 then
				-- too close to fuel base
			else
				bolPlacementOkay = true
			end
		until bolPlacementOkay
		cobjs.CreateObject(enum.basetypeBuilding2, rndnum)
	end
	
	--! Place spikes
	
	
end

function functions.ResetGame()

	garrGround = {}
	garrObjects = {}
	fun.InitialiseGround()

	garrLanders = {}
	table.insert(garrLanders, cobjs.CreateLander())

	end

function functions.LanderHasUpgrade(Lander, strModuleName)

	for i = 1, #Lander.modules do
		if Lander.modules[i] == strModuleName then
			return true
		end
	end
	return false
end


return functions
