---@diagnostic disable: undefined-global, undefined-field, param-type-mismatch
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
            error("Populate file first.")
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

local function drawMainMenu(select)
    local w, h = term.getSize() -- w51 h18
    term.clear()
    term.setCursorPos(1,1)
    centerWrite("Main Menu")
    term.setCursorPos(1,2)
    centerWrite(string.rep("-",w))
    local options = {"Input Items Into Storage", "Output Item From Storage", "View Storage", "Search Storage", "Setup Custom Search", "View Custom Search", "Exit"}
    -- Highlight the currently selected string
    options[select] = "[ "..options[select].." ]"
    -- draw options
    term.setCursorPos(1,5)
    centerWrite(options[1])
    term.setCursorPos(1,7)
    centerWrite(options[2])
    term.setCursorPos(1,9)
    centerWrite(options[3])
    term.setCursorPos(1,11)
    centerWrite(options[4])
    term.setCursorPos(1,13)
    centerWrite(options[5])
    term.setCursorPos(1,15)
    centerWrite(options[6])
    term.setCursorPos(1,17)
    centerWrite(options[7])
    -- keyboard controls
    -- UP = 200, DOWN = 208, ENTER = 28
    local id, key = os.pullEvent("key")
    if key == 200 then
        if select <= 1 then
            select = 7
            return select
        else
            select = select - 1
            return select
        end
    elseif key == 208 then
        if select >= 7 then
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

local function drawSetCustomSearch(select, inSubMenu)
    local w, h = term.getSize() -- w51 h18
    term.clear()
    term.setCursorPos(1,1)
    centerWrite("Set Custom Search")
    term.setCursorPos(1,2)
    centerWrite(string.rep("-",w))
    local options = {"Add Custom Search", "Remove Custom Search"}
    local suboptions = {"Add Another Key", "Done"}
    -- highlight currently selected string
    options[select] = "[ "..options[select].." ]"
    suboptions[select] = "[ "..suboptions[select].." ]"
    if inSubMenu then
        -- draw subMenu
        term.setCursorPos(1, 8)
        centerWrite(suboptions[1])
        term.setCursorPos(1, 11)
        centerWrite(suboptions[2])
        -- keyboard controls
        -- UP = 200, DOWN = 208, ENTER = 28
        local id, key = os.pullEvent("key")
        if key == 200 then
            if select <= 1 then
                select = 2
                return select
            else
                select = select - 1
                return select
            end
        elseif key == 208 then
            if select >= 2 then
                select = 1
                return select
            else
                select = select + 1
                return select
            end
        elseif key == 28 then
            local proceeding = true
            term.clear()
            term.setCursorPos(1,1)
            return select, proceeding
        end
    else
        -- draw menu
        term.setCursorPos(1, 8)
        centerWrite(options[1])
        term.setCursorPos(1, 11)
        centerWrite(options[2])
        -- keyboard controls
        -- UP = 200, DOWN = 208, ENTER = 28
        local id, key = os.pullEvent("key")
        if key == 200 then
            if select <= 1 then
                select = 2
                return select
            else
                select = select - 1
                return select
            end
        elseif key == 208 then
            if select >= 2 then
                select = 1
                return select
            else
                select = select + 1
                return select
            end
        elseif key == 28 then
            local proceeding = true
            term.clear()
            term.setCursorPos(1,1)
            return select, proceeding
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

local function paginate(db)
    local pages = {}
    local currentPage = {}

    for k,v in pairs(db) do
        table.insert(currentPage, k) -- 15 keys per page as a subtable
        if #currentPage == 15 then
            table.insert(pages, currentPage) -- main table with each page subtable
            currentPage = {}
        end
    end

    if #currentPage > 0 then
        table.insert(pages, currentPage)
    end

    return pages
end

local function drawStorage(currentPage)
    term.setBackgroundColor(colors.blue)
    term.clear()
    -- header
    term.setCursorPos(1,1)
    term.write("ITEM")
    centerWrite("STORAGE")
    term.setCursorPos(44,1)
    term.write("NUM")

    -- background
    term.setCursorPos(1,2)
    local w,h = term.getSize()
    for i = 1,7 do
        term.setBackgroundColor(colors.gray)
        print(string.rep(" ",w))
        term.SetBackgroundColor(colors.green)
        print(string.rep(" ",w))
    end
    term.SetBackgroundColor(colors.gray)
    print(string.rep(" ",w))

    -- footer --
    -- page number
    term.setCursorPos(1,18)
    term.setTextColor(colors.black)
    term.setBackgroundColor(colors.yellow)
    centerWrite("Page "..currentPage)

    -- page arrows and exit key
    term.setCursorPos(20,18)
    print("<")
    term.setCursorPos(31,18)
    print(">")
    term.setCursorPos(1,18)
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.red)
    print("EXIT")

    -- set back to default settings
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end

local function viewStorage(db)
    term.clear()
    term.setCursorPos(1, 1)
            -- for k, v in pairs(db) do -- NEEDS GUI REFACTOR LATER
            --     print(k.." "..v[5])
            -- end
    -- paginate the database
    local pages = paginate(db) -- pages[1] = array page 1; pages[1][1] = string page 1 key 1
    local currentPage = 1
    local inViewMode = true
    drawStorage(currentPage)
    while inViewMode do
        -- draw database elements
        term.setCursorPos(1,2)
        for i = 1,7,2 do
            if pages[currentPage][i] then
                term.setBackgroundColor(colors.gray)
                print(pages[currentPage][i])
            end
            if pages[currentPage][i+1] then
                term.setBackgroundColor(colors.green)
                print(pages[currentPage][i+1])
            end
        end
        if pages[currentPage][15] then
            term.setBackgroundColor(colors.gray)
            print(pages[currentPage][15])
        end

        -- draw counts for each element
        term.setCursorPos(44,2)
        for i = 1,7,2 do
            if pages[currentPage][i] then
                term.setBackgroundColor(colors.gray)
                print(db[pages[currentPage][i]][5])
            end
            if pages[currentPage][i+1] then
                term.setBackgroundColor(colors.green)
                print(db[pages[currentPage[i]][5])
            end
        end
        if pages[currentPage][15] then
            term.setBackgroundColor(colors.gray)
            print(db[pages[currentPage][i]][15])
        end

        -- button functionality
        local event, button, x, y = os.pullEvent("mouse_click")
        if y == 18 then
            if x <= 4 then
                -- exit button
                term.setBackgroundColor(colors.black)
                term.clear()
                inViewMode = false
                break
            elseif x == 20 then
                -- page down
                if currentPage <= 1 then
                    currentPage = #pages
                else
                    currentPage = currentPage + 1
                end
            elseif x == 31 then
                -- page up
                if currentPage >= #pages then
                    currentPage = 1
                else
                    currentPage = currentPage + 1
                end
            end
        end
        drawStorage(currentPage)
    end
    -- loop broken, reset to default
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1,1)
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
    for k, v in pairs(searchResults) do -- NEEDS GUI REFACTOR LATER
        print(k.." - "..v[5])
    end
end

local function setCustomSearch()
    -- Ask user for name of search then add search terms to array and save
    term.clear()
    term.setCursorPos(1, 1)
    local select, proceeding = drawSetCustomSearch(1)
    local inCustomSearch = true
    while inCustomSearch do
        if proceeding then
            if select == 1 then
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
                    local opt, continuing = drawSetCustomSearch(1, true)
                    while deciding do
                        if continuing then
                            if opt == 1 then
                                deciding = false
                                continuing = nil
                                break
                            elseif opt == 2 then
                                addingKeys = false
                                deciding = false
                                continuing = nil
                                break
                            end
                        else
                            opt, continuing = drawSetCustomSearch(opt, true)
                        end
                    end
                    -- done adding keys, pack up data and save it
                    categories[category] = keys
                    writeConf(categories, "customsearches.cfg")
                end
            elseif select == 2 then
                local customsearches = assertFile("customsearches.cfg")
                -- List all categories NEEDS GUI REFACTOR LATER
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
        else
            select, proceeding = drawSetCustomSearch(select, proceeding)
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
        -- view our data NEEDS GUI REFACTOR LATER
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
local select, continuing = drawMainMenu(1)
local inMenu = true 
while inMenu do
    if continuing then
        if select == 1 then
            -- Input Items into Storage
            db = storeItems(db, turtle)
            continuing = nil
        elseif select == 2 then
            -- Output Item from Storage
            takeItems(nodes, db)
            continuing = nil
        elseif select == 3 then
            -- View Storage
            viewStorage(db)
            continuing = nil
        elseif select == 4 then
            -- Search Storage
            searchStorage(db)
            continuing = nil
        elseif select == 5 then
            -- Setup Custom Search
            setCustomSearch()
            continuing = nil
        elseif select == 6 then
            -- View Custom Search
            viewCustomSearch(db)
            continuing = nil
        elseif select == 7 then
            -- Exit
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