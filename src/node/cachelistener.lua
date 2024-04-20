-- This is the basic node listener that listens for signals from controller

-- == Driver code ==
rednet.open("bottom")

-- config check and resolve controller ID before any instructions
local controller = {}
if fs.exists("controllerID.cfg") then
    -- config exists, prepare to load data
    print("Detected existence of existing configuration.")
    local cfg = assert(fs.open("controllerID.cfg", "r"), "Error: Couldn't load config")
    local inData = cfg.readAll()
    cfg.close()

    local configData = textutils.unserialize(inData)
    controller = configData
else
    -- create the config file
    local configFile = assert(fs.open("controllerID.cfg", "w"), "Error: Could not create cacheconfig.txt")
    print("What is the Computer ID of the Controller?")
    local id = read()
    id = tonumber(id) -- error check needed here
    controller.id = id
    local confData = textutils.serialize(controller)
    configFile.write(confData)
    configFile.close()
end

-- put node in listen mode and wait for instructions from controller
local listening = true
while listening do
    local senderID, senderMessage = rednet.receive("IO") -- CONTROLLER cachemaster.lua takeItems() line 83
    if senderID == controller.id then
        -- Unpack data and output the signal [1] itemSide [2] signalStrength
        local data = textutils.unserialize(senderMessage)
        local itemSide = data[1]
        local signalStrength = data[2]
        redstone.setAnalogOutput(itemSide, signalStrength)
        redstone.setAnalogOutput(itemSide, 0)
    end
end