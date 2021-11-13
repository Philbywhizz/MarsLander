
-- ~~~~~~~~~~~~~~~
-- assetloader.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Asset managment tool for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local Assets = {}
Assets.debugOutput  = true
Assets.imageSets    = {}
Assets.images       = {}
Assets.sounds       = {}
Assets.fonts        = {}
Assets.animations   = {}



-- ~~~~~~~~~~~~~~
-- Dependencies
-- ~~~~~~~~~~~~~~

local Anim8 = require("lib.anim8")



-- ~~~~~~~~~~~~~~~~
-- Local variables
-- ~~~~~~~~~~~~~~~~

local prefix    = " [Asset Tool] "
local newSource = love.audio.newSource
local newImage  = love.graphics.newImage
local newFont   = love.graphics.newFont
local fs        = love.filesystem
local fileExtensions = {
    ["image"] = {"png", "jpg", "jpeg", "bmp", "tga", "hdr", "pic", "exr"},
    ["sound"] = {"ogg", "mp3", "oga", "ogv", "wav", "flac"},
}
local audioStreamSizeLimit = 1024



-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~

local function log(...)
    if Assets.debugOutput then
        print(prefix.. ...)
        -- TODO: Add support for logging into a logfile
    end
end



local function getFileExtension(path)
    return path:match("[^.]+$")
end



local function getFilename(path)
    return path:match("([^/]+)%..+")
end



local function getDirectoryItems(basePath, items)
    local items = items or {}

    -- Check if the given path is valid
    local baseInfo = fs.getInfo(basePath)
    if baseInfo.type == "directory" then

        -- Found initial directory
        log("[Info] Found directory at path '/"..basePath.."'")

        -- Recursivly load directories and files
        local fileNames = fs.getDirectoryItems(basePath)
        for _, name in ipairs(fileNames) do
            local filePath = basePath.."/"..name

            -- Found a single file
            local fileInfo = fs.getInfo(filePath)
            if fileInfo.type == "file" then
                local item = {}
                item.name = name
                item.path = filePath
                item.fileType = getFileExtension(item.path)
                item.fileSize = fileInfo.size / 1000 -- Convert bytes to kb
                table.insert(items, item)

            -- Found another directory, load the content as well!
            elseif fileInfo.type == "directory" then
                getDirectoryItems(filePath, items)
            end
        end
    else
        -- Base directory not found
        log("[WARN] No directory at path '"..basePath.."'. Skipping!")
    end
    return items
end



-- ~~~~~~~~~~~~~~~~~
-- Public functions
-- ~~~~~~~~~~~~~~~~~

function Assets.loadDirectory(path)
    local directoryName = path:match("([^/]+)$")
    local items = getDirectoryItems(path)

    -- Iterate all loaded files and sort based on their type
    for _, item in pairs(items) do
        local fileLoaded = false

        -- Check if the file is an image
        for _, extension in pairs(fileExtensions.image) do
            if item.fileType == extension then
                -- Create new image data
                Assets.newImageSet(item.path)
                log("[Info] New image: "..item.name)
                fileLoaded = true
                break
            end
        end

        -- Check if the file is a sound
        for _, extension in pairs(fileExtensions.sound) do
            if item.fileType == extension then
                -- Determine if the file should be streamed
                -- fileSize in kilobytes
                local mode = "static"
                if item.fileSize >= audioStreamSizeLimit then
                    mode = "stream"
                end

                -- Create new sound data
                Assets.newSound(item.path, mode)
                log("[Info] New Sound: "..item.name)
                fileLoaded = true
                break
            end
        end

        -- Show a warning when no supported file type is found
        if not fileLoaded then
            log("[WARN] Cannot load file '"..item.name.."'. Skipping!")
        end
    end
end



function Assets.newImageSet(path, ...)
    local imageData = {}
    imageData.image    = newImage(path, ...)
    imageData.width    = imageData.image:getWidth()
    imageData.height   = imageData.image:getHeight()
    local filename  = getFilename(path)
    Assets.images[filename] = imageData
    return imageData
end



function Assets.newImage(path, ...)
    local image     = newImage(path, ...)
    local filename  = getFilename(path)
    Assets.images[filename] = image
    return image
end



function Assets.newSound(path, ...)
    local sound     = newSource(path, ...)
    local filename  = getFilename(path)
    Assets.sounds[filename] = sound
    return sound
end



function Assets.newFont(...)
    local args      = {...}
    local font      = newFont(...)
    local filename  = "font"..args[1]

    if type(args[1]) == "string" then
        filename = getFilename(args[1])..args[2]
    end

    Assets.fonts[filename] = font
    return font
end



function Assets.newAnimation(name, image, width, height, column, row, durations, onLoop)

    local grid = Anim8.newGrid(width, height, image:getWidth(), image:getHeight())
    local animation = Anim8.newAnimation(grid(column, row), durations, onLoop)
    animation.name = name
    animation.grid = grid
    animation.image = image
    local anim8_draw = animation.draw
    animation.draw = function(animation, ...)
        -- just to skip passing the spritesheet everytime manually.. yikes -_-'
        anim8_draw(animation, animation.image, ...)
    end
    return animation
end



function Assets.draw(name, ...)
    local image = Assets.getImage(name)
    love.graphics.draw(image, ...)
end



function Assets.playSound(name, isLooping)
    local sound = Assets.getSound(name)
    -- if the sound needs to be played more then once at the same time, clone it
    -- sound = Assets.getSound(name):clone()
    sound:setLooping(isLooping or false)
    sound:play()
    return sound
end



function Assets.getImage(name)
    if not Assets.images[name] then
        error(prefix.."Image '"..name.."' does not exist.")
    end
    return Assets.images[name].image
end



function Assets.getImageSet(name)
    if not Assets.images[name] then
        error(prefix.."Image '"..name.."' does not exist.")
    end
    return Assets.images[name]
end



function Assets.getAnimation(name)
    if not Assets.animations[name] then
        error(prefix.."Animation '"..name.."' does not exist.")
    end
    return Assets.animations[name]
end



function Assets.getSound(name)
    if not Assets.sounds[name] then
        error(prefix.."Sound '"..name.."' does not exist.")
    end
    return Assets.sounds[name]
end



function Assets.getFont(name)
    if not Assets.fonts[name] then
        error(prefix.."Font '"..name.."' does not exist.")
    end
    return Assets.fonts[name]
end



function Assets.setFont(name)
    local font = Assets.getFont(name)
    love.graphics.setFont(font)
    return font
end


return Assets