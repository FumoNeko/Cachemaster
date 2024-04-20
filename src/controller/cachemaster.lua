-- handle input output and logging

local function writeConf(d, fileName)
    local f = assert(fs.open(fileName, "w"), "Error: Couldn't open handle to "..fileName)
    local o = textutils.serialize(d)
    f.write(o)
    f.close()
end

local function centerWrite(text)
    local width, height = term.getSize()
    local x, y = term.getCursorPos()
    term.setCursorPos(math.ceil((width / 2) - (text:len() / 2)), y)
    term.write(text)
end

local function assertFile(fileName, requiresSetup, setupFile)
    if fs.exists(fileName) then
        -- config exists, prepare to load data
        print("Detected existence of existing configuration.")
        local handle = assert(fs.open(fileName, "r"), "Error: Couldn't load file "..fileName)
        local inData = handle.readAll()
        handle.close()
        local outData = textutils.unserialize(inData)
        return outData
    else
        if requiresSetup then
            -- abort, file must be populated elsewhere first
            print("File not found. Run "..setupFile.." first before proceeding.")
            return nil
        else
            -- create empty config file
            local hnd = assert(fs.open(fileName, "w"), "Error: Could not create file "..fileName)
            local empty = {}
            hnd.write(textutils.serialize(empty))
            hnd.close()
            local h = assert(fs.open(fileName, "r"), "Error: Couldn't load file "..fileName)
            local dat = h.readAll()
            h.close()
            local out = textutils.unserialize(dat)
            return out
        end
    end
end

local function storeItems(db, turtle)
    -- Tell the turtle to scan the items from the input chest and extract them.
    term.clear()
    term.setCursorPos(1, 1)
    rednet.send(turtle.id, "INPUT", "manage") -- TURTLE cachescanmode.lua line 19
    local data
    local senderID, senderMessage = rednet.receive("manage") -- TURTLE cachescanmode.lua line 41
    if senderID == turtle.id then
        data = textutils.unserialize(senderMessage)
        -- Add to the counts for each item in the db
        for k, v in pairs(data) do
            db[k][5] = db[k][5] + v
        end
    end
    -- write the db data to file
    writeConf(db, "cachedata.db")
    return db
end

local function takeItems(nodes, db)
    -- Ask the user which item to output and send the signal to the node
    term.clear()
    term.setCursorPos(1, 1)
    local inItemSelect = true
    while inItemSelect do
        print("Which Item do you want?")
        local item = read() -- uses displayNames now, but still kind of daunting to remember names on the spot. A GUI would fix this.
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
            rednet.send(nodeID, nodeOut, "IO") -- NODE cachelistener.lua line 32
            -- Reduce count value from DB
            db[item][5] = db[item[5]] - 64
            writeConf(db, "cachedata.db")
            return db
        else
            print("No Such item in database!")
            return db
        end
    end
end

local function viewStorage(db)
    term.clear()
    term.setCursorPos(1, 1)
    for k, v in pairs(db) do
        print(k..v[5])
    end
end

local function partialKeySearch(uinput, hashTable)
    local results = {}
    for key, value in pairs(hashTable) do
        if string.find(key:lower(), uinput:lower(), 1, true) then
            results[key] = value
        end
    end
    return results
end

local function searchStorage(db)
    term.clear()
    term.setCursorPos(1, 1)
    print("Enter search term: ")
    local uinput = read()
    local searchResults = partialKeySearch(uinput)
    for k, v in pairs(searchResults) do
        print(k.." - "..value[5])
    end
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
            --array where key is categoryName and element is subArray holding list of keys for items
            local categories = assertFile("customsearches.cfg")
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
                writeConf(categories, "customsearches.cfg")
            end
        elseif option == "2" then
            local customsearches = assertFile("customsearches.cfg")
            -- List all categories
            for k,v in pairs(customsearches) do
                print(k)
            end
            print("Which category are you removing?")
            local remove = read()
            table.remove(customsearches, remove)
            -- pack data and save
            writeConf(customsearches, "customsearches.cfg")
        else
            print("Invalid option!")
        end
    end
end

local function viewCustomSearch(db)
    -- Show data with only objects in the custom search
    term.clear()
    term.setCursorPos(1, 1)
    local customsearches = assertFile("customsearches.cfg", true, "Setup Custom Search")
    if customsearches == nil then
    else
        -- view our data
            print("Which category are you searching?")
            for k,v in pairs(customsearches) do
                print(k)
            end
            local searchcat = read()
            for i = 1, #customsearches[searchcat] do
                print(customsearches[searchcat][i].." "..db[searchcat][5])
            end
    end
end

-- == Driver Code ==
rednet.open("back")

-- read config to get info about nodes, logging bool and turtle ID
local nodes
local logging
local turtle

local configData = assertFile("cacheconfig.cfg", true, "cachesetup.lua")
if configData == nil then
    error("Run cachesetup.lua first!")
else
    nodes = configData[1]
    logging = configData[2]
    turtle = configData[3]
end

local db = assertFile("cachedata.db", true, "cachesetup.lua")
if db == nil then
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
        searchStorage(db)
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