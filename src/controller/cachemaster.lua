-- handle input output and logging

local function storeItems(db, turtle)
    -- Tell the turtle to scan the items from the input chest and extract them.
    term.clear()
    term.setCursorPos(1, 1)
    rednet.send(turtle.id, "INPUT", "manage")
    local data
    local senderID, senderMessage = rednet.receive("manage")
    if senderID == turtle.id then
        data = textutils.unserialize(senderMessage)
        -- Add to the counts for each item in the db
        for k, v in pairs(data) do
            db[k][5] = db[k][5] + v
        end
    end
    -- write the db data to file
    local f = assert(fs.open("cachedata.db", "w"), "Error: Couldn't open database!")
    local d = textutils.serialize(db)
    f.write(d)
    f.close()
    return db
end

local function takeItems(nodes, db)
    -- Ask the user which item to output and send the signal to the node
    term.clear()
    term.setCursorPos(1, 1)
    local inItemSelect = true
    while inItemSelect do
        print("Which Item do you want?")
        local item = read() -- "minecraft:log 0" there isn't a way to solve this without massive hash table
        if db[item] then
            inItemSelect = false
            -- Get which Node the item is in
            local nodeID = nodes[db[item][2]]["id"]
            -- Get Location information from DB
            local itemSide = db[item][3]
            local signalStrength = db[item][4]
            local nodeOut = {itemSide, signalStrength}
            nodeOut = textutils.serialize(nodeOut)
            -- Send the signal to the node
            rednet.send(nodeID, nodeOut, "IO")
            -- Reduce count value from DB
            db[item][5] = db[item[5]] - 64
        else
            print("No Such item in database!")
        end
    end
end

local function viewStorage()
    -- Do the pagination stuff
    term.clear()
    term.setCursorPos(1, 1)
end

local function searchStorage()
    -- Do Cosine Similarity Search
    term.clear()
    term.setCursorPos(1, 1)
end

local function setCustomSearch()
    -- Ask user for name of search then add search terms to array and save
    term.clear()
    term.setCursorPos(1, 1)
end

local function viewCustomSearch()
    -- Show data with only objects in the custom search
    term.clear()
    term.setCursorPos(1, 1)
end

-- == Driver Code ==
rednet.open("back")

-- read config to get info about nodes, logging bool and turtle ID
local nodes
local logging
local turtle

if fs.exists("cacheconfig.cfg") then
    print("Detected configuration file.")
    local cfg = assert(fs.open("cacheconfig.cfg", "r"), "Error: Couldn't load config!")
    local inData = cfg.readAll()
    cfg.close()
    local configData = textutils.unserialize(inData)
    nodes = configData[1]
    logging = configData[2]
    turtle = configData[3]
else
    error("Configuration file does not exist. Run cachesetup.lua first.")
end

local db
if fs.exists("cachedata.db") then
    print("Detected Database file.")
    local h = assert(fs.open("cachedata.db", "r"), "Error: Couldn't load Database!")
    local in_ = h.readAll()
    h.close()
    db = textutils.unserialize(in_)
else
    error("Database file does not exist. Run cachesetup.lua first.")
end

-- Main menu
local inMenu = true 
while inMenu do
    print("Welcome to the CacheMaster Interface! Please select an option:")
    print("1. Input Items into Storage")
    print("2. Output Item From Storage")
    print("3. View Storage")
    print("4. Search Storage")
    print("5. Setup Custom Search")
    print("6. View Custom Search")
    print("7. Exit")
    local option = read()
    option = tonumber(option) -- do error check here
    if option == 1 then
        -- Input Items into Storage
        db = storeItems(db, turtle)
    elseif option == 2 then
        -- Output Item from Storage
        takeItems(nodes, db)
    elseif option == 3 then
        -- View Storage
        viewStorage()
    elseif option == 4 then
        -- Search Storage
        searchStorage()
    elseif option == 5 then
        -- Setup Custom Search
        setCustomSearch()
    elseif option == 6 then
        -- View Custom Search
        viewCustomSearch()
    elseif option == 7 then
        -- Exit
        print("Goodbye.")
        inMenu = false
    end
end