-- This file handles item location configuration for the turtle

-- == Driver code ==
rednet.open("left")

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

-- Put turtle in listen state
local senderID, nodeData = rednet.receive("itemconfig")
if senderID == controller.id then -- controller.id is nil?
    -- prepare the scanning operation
    local nodes = textutils.unserialize(nodeData)
    print("Place Item to be scanned in the first slot.\n".."1. Item has been placed.")
    local itemPlaced = read()
    itemPlaced = tonumber(itemPlaced) -- error check needed here
    local scanData = turtle.getItemDetail()
    local nameScheme
    if scanData then
        local damage = tostring(scanData.damage)
        nameScheme = scanData.name.." "..damage
    end
    print("Choose a DISPLAY NAME for this item.")
    local displayName = read()
    print("Which NODE does this item belong to?")
    for i = 1, #nodes do
        print(i..". ID: "..nodes[i]["id"].." Name: "..nodes[i]["name"])
    end
    local itemNode = read() -- error check needed here
    itemNode = tonumber(itemNode)
    print("Which SIDE does this item belong to?")
    local inSideQuestion = true
    local itemSide
    while inSideQuestion do
        itemSide = read()
        local validsides = {"front", "back", "left", "right"}
        for i = 1, #validsides do
            if itemSide == validsides[i] then
                inSideQuestion = false
            end
        end
        if inSideQuestion then
            print("Invalid response! Valid answers: front, back, left, right")
        end
    end
    print("What SIGNAL STRENGTH does this item belong to?")
    local inSignalStrengthQuestion = true
    local signalStrength
    while inSignalStrengthQuestion do
        signalStrength = read()
        signalStrength = tonumber(signalStrength)
        for i = 1, 15 do
            if signalStrength == i then
                inSignalStrengthQuestion = false
            end
        end
        if inSignalStrengthQuestion then
            print("Invalid response! Answer a number between 1 and 15")
        end
    end
    -- compile all the variables into one table
    local metadata = {}
    local count = 1
    table.insert(metadata, {nameScheme, displayName, itemNode, itemSide, signalStrength, count})
    metadata = textutils.serialize(metadata)
    -- send the data back
    rednet.send(controller.id, metadata, "itemconfig")
else
    error("Network Integrity check failed, stopping...")
end