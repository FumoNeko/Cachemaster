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
        -- the real problem isn't that the search term sucks, it's that remembering what to type is hard.
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

local function viewStorage(db)
    -- Do the pagination stuff
    term.clear()
    term.setCursorPos(1, 1)
    for k, v in pairs(db) do
        print(k..v[5])
    end
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
    local inCustomSearch = true
    while inCustomSearch do
        print("1. Add Custom Search")
        print("2. Remove Custom Search")
        local option = read()
        if option == "1" then
            local categories = {}
            if fs.exists("customsearches.cfg") then
                -- config exists, prepare to load data
                print("Detected existence of existing configuration.")
                local searchcfg = assert(fs.open("customsearches.cfg", "r"), "Error: Couldn't load config")
                local inData = searchcfg.readAll()
                searchcfg.close()

                categories = textutils.unserialize(inData)
                --array where key is categoryName and element is subArray holding list of keys for items
            else
                -- create the config file
                local searchconfig = assert(fs.open("customsearches.cfg", "w"), "Error: Could not create customsearches.cfg")
                searchconfig.close()
            end
            -- Start interrogation
            print("Name your search category.")
            local category = read()
            local addingKeys = true
            local keys = {}
            while addingKeys do
                print("Add a key to this category: ")
                local key = read()
                table.insert(keys, key)
                local deciding = true
                while deciding do
                    print("1. Add another key")
                    print("2. Done")
                    local op = read()
                    if op == "1" then
                        deciding = false
                        break
                    elseif op == "2" then
                        addingKeys = false
                        deciding = false
                        break
                    else
                        print("Invalid option!")
                    end
                end
                -- done adding keys, pack up data and save it
                categories[category] = keys
                local outData = textutils.serialize(categories)
                local searchFile = assert(fs.open("customsearches.cfg", "w"), "Error: Couldn't open customsearches.cfg")
                searchFile.write(outData)
                searchFile.close()
            end
        elseif option == "2" then
            local customsearches
            if fs.exists("customsearches.cfg") then
                -- config exists, prepare to load data
                print("Detected existence of existing configuration.")
                local searchcfg = assert(fs.open("customsearches.cfg", "r"), "Error: Couldn't load config")
                local inData = searchcfg.readAll()
                searchcfg.close()

                customsearches = textutils.unserialize(inData)
                --array where key is categoryName and element is subArray holding list of keys for items
            else
                -- create the config file
                local searchconfig = assert(fs.open("customsearches.cfg", "w"), "Error: Could not create customsearches.cfg")
                searchconfig.close()
            end
            -- List all categories
            for k,v in pairs(customsearches) do
                print(k)
            end
            print("Which category are you removing?")
            local remove = read()
            table.remove(customsearches, remove)
            -- pack data and save
            local f = assert(fs.open("customsearches.cfg", "w"), "Error, Couldn't open customsearches.cfg")
            local d = textutils.serialize(customsearches)
            f.write(d)
            f.close()
        else
            print("Invalid option!")
        end
    end
end

local function viewCustomSearch(db)
    -- Show data with only objects in the custom search
    term.clear()
    term.setCursorPos(1, 1)
    local customsearches
    if fs.exists("customsearches.cfg") then
        -- config exists, prepare to load data
        print("Detected existence of existing configuration.")
        local searchcfg = assert(fs.open("customsearches.cfg", "r"), "Error: Couldn't load config")
        local inData = searchcfg.readAll()
        searchcfg.close()
        customsearches = textutils.unserialize(inData)

        -- view our data
        print("Which category are you searching?")
        for k,v in pairs(customsearches) do
            print(k)
        end
        local searchcat = read()
        for i = 1, #customsearches[searchcat] do
            print(customsearches[searchcat][i].." "..db[searchcat][5])
        end
    else
        print("File not found: customsearches.cfg Exiting...")
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
        viewStorage(db)
    elseif option == 4 then
        -- Search Storage
        searchStorage()
    elseif option == 5 then
        -- Setup Custom Search
        setCustomSearch()
    elseif option == 6 then
        -- View Custom Search
        viewCustomSearch(db)
    elseif option == 7 then
        -- Exit
        print("Goodbye.")
        inMenu = false
    end
end