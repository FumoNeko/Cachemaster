-- This file handles adding modules to the database

local function writeConf(nodes, logging, turtle)
    local f = assert(fs.open("cacheconfig.cfg", "w"), "Error: Couldn't open handle to cacheconfig.cfg")
    local d = {nodes, logging, turtle}
    d = textutils.serialize(d)
    f.write(d)
    f.close()
end

local function centerWrite(text)
    local width, height = term.getSize()
    local x, y = term.getCursorPos()
    term.setCursorPos(math.ceil((width / 2) - (text:len() / 2)), y)
    term.write(text)
end

local function drawNodeMenu(select)
    local w,h = term.getSize() -- w51, h18
    term.clear()
    term.setCursorPos(1,1)
    centerWrite("Node Menu")
    term.setCursorPos(1,2)
    centerWrite(string.rep("-",w))
    local options = {"Add Node", "Remove Node", "Return to Setup Menu"}
    -- Highlight the currently selected string
    options[select] = "[ "..options[select].." ]"
    -- draw options
    term.setCursorPos(1,9)
    centerWrite(options[1])
    term.setCursorPos(1,11)
    centerWrite(options[2])
    term.setCursorPos(1,13)
    centerWrite(options[3])
    -- keyboard controls
    -- UP = 200, DOWN = 208, ENTER = 28
    local id, key = os.pullEvent("key")
    if key == 200 then
        if select <=1 then
            select = 3
            return select
        else
            select = select - 1
            return select
        end
    elseif key == 208 then
        if select >=3 then
            select = 1
            return select
        else
            select = select + 1
            return select
        end
    elseif key == 28 then
        local proceeding = true
        return select, proceeding
    end
end

local function nodeDef(nodes, logging, turtle)
    term.clear()
    term.setCursorPos(1, 1)
    local select, continuing = drawNodeMenu(1)
    local inNodeMenu = true
    while inNodeMenu do
        if continuing then
            if select == 1 then
            -- Add Node
                local len = #nodes + 1
                print("What is the Computer ID of this node?")
                local id = read()
                id = tonumber(id) -- do error checking here in future
                print("What is the Name of this node?")
                local name = read()
                table.insert(nodes, {id = id, name = name})
                writeConf(nodes, logging, turtle)
                continuing = nil
            elseif select == 2 then
            -- Remove Node
                print("Which node is to be removed?")
                for i = 1, #nodes do
                    print(i..". ID: "..nodes[i]["id"].." Name: "..nodes[i]["name"])
                end
                local removeNode = read() -- do error checking here in future
                removeNode = tonumber(removeNode)
                table.remove(nodes, removeNode)
                writeConf(nodes, logging, turtle)
                continuing = nil
            elseif select == 3 then
                term.clear()
                term.setCursorPos(1,1)
                continuing = nil
                inNodeMenu = false
                return
            end
        else
            select, continuing = drawNodeMenu(select)
        end
    end
end

local function itemDef(nodes, logging, turtle)
    term.clear()
    term.setCursorPos(1, 1)
    print("Proceed to the Scanner Turtle and follow the instructions.")
    -- send the node data so that the turtle can operate and await instruction
    local nodeData = textutils.serialize(nodes)
    rednet.send(turtle.id, nodeData, "itemconfig") -- TURTLE cacheconfigmode.lua line 30
    local senderID, senderMessage = rednet.receive("itemconfig") -- TURTLE cacheconfigmode.lua line 87
    -- got data back, write to db
    if senderID == turtle.id then
        local metadata = textutils.unserialize(senderMessage)
        local db
        -- file check for db
        if fs.exists("cachedata.db") then
            -- db exists, prepare to load data
            print("Detected existence of existing Database.")
            local handle = assert(fs.open("cachedata.db", "r"), "Error: Couldn't load database!")
            local inData = handle.readAll()
            handle.close()
            db = textutils.unserialize(inData)
        else
            -- create the database if none exists
            local dataFile = assert(fs.open("cachedata.db", "w"), "Error: Could not create cachedata.db!")
            dataFile.close()
            db = {}
        end
        -- construct the database
        --[[
            Database Design:
            hashed using nameScheme from scanData for fast input/output sync
            [ item.name.." "..tostring(item.damage) ]
            data: {displayName, itemNode, itemSide, signalStrength, count}
        ]]
        local nameScheme = metadata[1][1]
        local displayName = metadata[1][2]
        local itemNode = metadata[1][3]
        local itemSide = metadata[1][4]
        local signalStrength = metadata[1][5]
        local count = metadata[1][6]
        db[displayName] = {nameScheme, itemNode, itemSide, signalStrength, count}
        -- write data to file
        local f = assert(fs.open("cachedata.db", "w"), "Error: Couldn't open handle to cachedata.db")
        dat = textutils.serialize(db)
        f.write(dat)
        f.close()
    else
        print("Network Integrity error. Turtle ID did not match.")
    end
end

local function loggingctl(nodes, logging, turtle)
    term.clear()
    term.setCursorPos(1, 1)
    print("1. Enable Logging")
    print("2. Disable Logging")
    local inLogMenu = true 
    while inLogMenu do
        local option = read()
        option = tonumber(option)
        if option == 1 then
            logging.logging = 1
            print("Logging has been ENABLED!")
            inLogMenu = false
        elseif option == 2 then
            logging.logging = 0
            print("Logging has been DISABLED!")
            inLogMenu = false
        else
            print("Invalid input!")
        end
    end
    writeConf(nodes, logging, turtle)
end

local function scanDef(nodes, logging, turtle)
    term.clear()
    term.setCursorPos(1, 1)
    print("What is the ID of the Scanner turtle?")
    local id = read()
    id = tonumber(id) -- do error handling here in future
    turtle.id = id
    print("Scanner Turtle ID set to "..id)
    writeConf(nodes, logging, turtle)
end

local function drawMainMenu(select)
    local w, h = term.getSize() -- w51 h18
    term.clear()
    term.serCursorPos(1,1)
    centerWrite("Setup Menu")
    term.setCursorPos(1,2)
    centerWrite(string.rep("-",w))
    local options = {"Add/Remove Node", "Add/Remove Item Definition", "Enable/Disable Logging", "Add/Remove Scanner Turtle", "Exit"}
    -- Highlight the currently selected string
    options[select] = "[ "..options[select].." ]"
    -- draw options
    term.setCursorPos(1,7)
    centerWrite(options[1])
    term.setCursorPos(1,9)
    centerWrite(options[2])
    term.setCursorPos(1,11)
    centerWrite(options[3])
    term.setCursorPos(1,13)
    centerWrite(options[4])
    term.setCursorPos(1,15)
    centerWrite(options[5])
    -- keyboard controls
    -- UP = 200, DOWN = 208, ENTER = 28
    local id, key = os.pullEvent("key")
    if key == 200 then
        if select <= 1 then
            select = 5
            return select
        else
            select = select - 1
            return select
        end
    elseif key == 208 then
        if select >= 5 then
            select = 1
            return select
        else
            select = select + 1
            return select
        end
    elseif key == 28 then
        local proceeding = true
        return select, proceeding
    end
end

-- == Driver code ==
-- initial setup and variable initialization
rednet.open("back")
term.clear()
term.setCursorPos(1, 1)
local nodes = {}
local logging = {}
local turtle = {}
if fs.exists("cacheconfig.cfg") then
    -- config exists, prepare to load data
    print("Detected existence of existing configuration.")
    local cfg = assert(fs.open("cacheconfig.cfg", "r"), "Error: Couldn't load config")
    local inData = cfg.readAll()
    cfg.close()

    local configData = textutils.unserialize(inData)
    nodes = configData[1] -- fix annoying bug where if you cancel the program before a node is created, the program errors here.
    logging = configData[2]
    turtle = configData[3]
else
    -- create the config file
    local configFile = assert(fs.open("cacheconfig.cfg", "w"), "Error: Could not create cacheconfig.txt")
    configFile.close()
end

-- Menu
local select, continuing = drawMainMenu(1)
local inMenu = true
while inMenu do
    if continuing then
        if select == 1 then
            nodeDef(nodes, logging, turtle)
            continuing = nil
        elseif select == 2 then
            itemDef(nodes, logging, turtle)
            continuing = nil
        elseif select == 3 then
            loggingctl(nodes, logging, turtle)
            continuing = nil
        elseif select == 4 then
            scanDef(nodes, logging, turtle)
            continuing = nil
        elseif select == 5 then
            term.clear()
            term.setCursorPos(1,1)
            print("Goodbye.")
            continuing = nil
            inMenu = false
        end
    else
        select, continuing = drawMainMenu(select)
    end
end