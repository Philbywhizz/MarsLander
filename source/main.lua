gstrGameVersion = "0.04"

inspect = require 'inspect'
-- https://github.com/kikito/inspect.lua

TLfres = require "tlfres"
-- https://love2d.org/wiki/TLfres

Slab = require 'Slab.Slab'
-- https://github.com/coding-jackalope/Slab/wiki

bitser = require 'bitser'
-- https://github.com/gvx/bitser

gintScreenWidth = 1024-- 1920
gintScreenHeight = 768-- 1080
garrCurrentScreen = {}	

cobjs = require "createobjects"
dobjs = require "drawobjects"
fun = require "functions"
cf = require "commonfunctions"
menus = require "menus"

garrLanders = {}	
garrGround = {}		-- stores the y value for the ground so that garrGround[Lander.x] = a value from 0 -> gintScreenHeight
garrObjects = {}	-- stores an object that needs to be drawn so that garrObjects[xvalue] = an object to be drawn on the ground
garrImages = {}
garrSound = {}

gintOriginX = cf.round(gintScreenWidth / 2,0)	-- this is the start of the world and the origin that we track as we scroll the terrain left and right
gintDefaultMass = 220		-- this is the mass the lander starts with hence the mass the noob engines are tuned to
garrMassRatio = 0			-- for debugging only. Records current mass/default mass ratio



gbolDebug = true

local function DoThrust(dt)

	if garrLanders[1].fuel - dt >= 0 then

		garrLanders[1].engineOn = true
		local angle_radian = math.rad(garrLanders[1].angle)
		local force_x = math.cos(angle_radian) * dt
		local force_y = math.sin(angle_radian) * dt
		
		-- adjust the thrust based on ship mass
		local massratio = gintDefaultMass / fun.GetLanderMass()	-- less mass = higher ratio = more thrust = less fuel needed to move
		if gbolDebug then garrMassRatio = massratio end			-- for debugging only
		force_x = force_x * massratio
		force_y = force_y * massratio

		garrLanders[1].vx = garrLanders[1].vx + force_x
		garrLanders[1].vy = garrLanders[1].vy + force_y
		
		garrLanders[1].fuel = garrLanders[1].fuel - dt
		

	else
		-- no fuel to thrust
		--! probably need to make a serious alert here

	
	end
end

local function TurnLeft(dt)

	--if garrLanders[1].landed == false then
		garrLanders[1].angle = garrLanders[1].angle - (90 * dt)
		if garrLanders[1].angle < 0 then garrLanders[1].angle = 360 end
	--end
	

end

local function TurnRight(dt)

	--if garrLanders[1].landed == false then
		garrLanders[1].angle = garrLanders[1].angle + (90 * dt)
		if garrLanders[1].angle > 360 then garrLanders[1].angle = 0 end
	--end
end

local function MoveShip(Lander, dt)
	Lander.x = Lander.x + Lander.vx
	Lander.y = Lander.y + Lander.vy
	
	local leftedge = gintOriginX - (gintScreenWidth / 2)
	if Lander.x < leftedge then Lander.x = leftedge end
	
	-- apply gravity
	if garrLanders[1].landed == false then
		Lander.vy = Lander.vy + (0.6 * dt)
	end
end

local function InitialiseGround()
-- initialie the ground array to be a flat line

	-- this creates a big flat space at the start of the game
	for i = 0, gintScreenWidth do
		garrGround[i] = gintScreenHeight * 0.80
	end
	
	fun.GetMoreTerrain(gintScreenWidth * 2)
	
	-- Place a single tower for testing purposes
	local randomx = love.math.random(100, gintScreenWidth - 100)
	cobjs.CreateObject(1,randomx)
	
	-- Place bases
	local basedistance = cf.round(gintScreenWidth * 1.5,0)
	for i = 1, 3 do
		cobjs.CreateObject(2, basedistance)		-- 2 = fuel base
		basedistance = cf.round(basedistance * 1.3,0)
	end
	
	--! Place spikes
	
end

local function RefuelLander(objBase)
-- drain fuel from the base and add it to the lander

	local refuelamt = math.min(objBase.fuelqty, (garrLanders[1].fueltanksize - garrLanders[1].fuel))

	objBase.fuelqty = objBase.fuelqty - refuelamt
	garrLanders[1].fuel = garrLanders[1].fuel + refuelamt
	
	-- disable the base if the tanks are empty
	if objBase.fuelqty <= 0 then objBase.active = false end

end

local function CheckForContact(Lander)
-- see if lander has contacted the ground

	local LanderXValue = cf.round(Lander.x)
	local groundYvalue
	
	Lander.landed = false
	
	if garrGround[LanderXValue] ~= nil then
		groundYvalue = cf.round(garrGround[LanderXValue],0)
	
		if Lander.y > groundYvalue - 8 then
			Lander.landed = true
			Lander.vx = 0
			-- Lander.vy = 0
			
			if Lander.vy > 0 then Lander.vy = 0 end
			
			-- see if landed near a fuel base
			local bestdist, bestbase = fun.GetDistanceToClosestBase(2)		-- 2 = type of base = fuel
			if bestdist <= 125 and bestdist > 0 then
				RefuelLander(bestbase)				
			end
			
		else
			Lander.landed = false
		end
	end
end

local function PlaySoundEffects()

	if garrLanders[1].engineOn then
		garrSound[1]:play()
	else
		garrSound[1]:stop()
	end

end

function love.keypressed( key, scancode, isrepeat)
	if key == "escape" then
		fun.RemoveScreen()
	end
end

function love.load()

	-- this line doesn't work for some reason. Perhaps love.load is the wrong place for it.
	--gintScreenWidth, gintScreenHeight = love.graphics.getDimensions()

    if love.filesystem.isFused( ) then
        void = love.window.setMode(gintScreenWidth, gintScreenHeight,{fullscreen=false,display=1,resizable=true, borderless=false})	-- display = monitor number (1 or 2)
        gbolDebug = false
    else
        void = love.window.setMode(gintScreenWidth, gintScreenHeight,{fullscreen=false,display=1,resizable=true, borderless=false})	-- display = monitor number (1 or 2)
    end
	
	love.window.setTitle("Mars Lander " .. gstrGameVersion)

	fun.AddScreen("MainMenu")
	-- fun.AddScreen("World")
	
	InitialiseGround()

	-- create one lander and add it to the global array
	-- ** this needs to be called AFTER InitialiseGround()
	table.insert(garrLanders, cobjs.CreateLander())
	
	garrImages[1] = love.graphics.newImage("/Assets/tower.png")
	garrImages[2] = love.graphics.newImage("/Assets/gastank.png")
	garrImages[3] = love.graphics.newImage("/Assets/Background-4.png")
	
	garrSound[1] = love.audio.newSource("Assets/wind.wav", "static")
	garrSound[2] = love.audio.newSource("Assets/387232__steaq__badge-coin-win.wav", "static")
	garrSound[3] = love.audio.newSource("Assets/Galactic-Pole-Position.mp3", "stream")
	garrSound[3]:setVolume(0.25)
	
	Slab.Initialize(args)
	
end

function love.draw()

	TLfres.beginRendering(gintScreenWidth,gintScreenHeight)
	
	local strCurrentScreen = garrCurrentScreen[#garrCurrentScreen]
	
	if strCurrentScreen == "MainMenu" then
		menus.DrawMainMenu()
	end
	
	if strCurrentScreen == "World" then
		dobjs.DrawWorld()
	end
	
	if strCurrentScreen == "Credits" then
		menus.DrawCredits()
	end	
	
	

	Slab.Draw()		--! can this be in an 'if' statement and not drawn if not on a SLAB screen?
	
	TLfres.endRendering({0, 0, 0, 1})

end

function love.update(dt)

	garrSound[3]:play()

	local strCurrentScreen = garrCurrentScreen[#garrCurrentScreen]
	
	if strCurrentScreen == "MainMenu" or strCurrentScreen == "Credits" then
		Slab.Update(dt)		--! should this be called only when the main menu is current?
	end
	
	if strCurrentScreen == "World" then

		if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
			DoThrust(dt)
		end

		if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
			TurnLeft(dt)
		end
		if love.keyboard.isDown("right") or love.keyboard.isDown("d")then
			TurnRight(dt)
		end
		
		MoveShip(garrLanders[1], dt)
		
		PlaySoundEffects()
		
		CheckForContact(garrLanders[1])
	end


end












