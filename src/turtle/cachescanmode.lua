-- == Driver Code ==
rednet.open("left")
local controller

-- load cfg and get controller ID
if fs.exists("controllerID.cfg") then
    -- config exists, prepare to load data
    print("Detected existence of existing configuration.")
    local cfg = assert(fs.open("controllerID.cfg", "r"), "Error: Couldn't load config")
    local inData = cfg.readAll()
    cfg.close()
    controller = textutils.unserialize(inData)
else
    error("No Controller ID cfg.")
end

local listening = true
while listening do
    local senderID, senderMessage = rednet.receive("manage") -- CONTROLLER cachemaster.lua storeItems() line 50
    if senderID == controller.id and senderMessage == "INPUT" then
        --start the scan process
        turtle.suckDown()
        local itemCount = turtle.getItemCount(1)
        local data = {}
        while itemCount ~= 0 do
            local item = turtle.getItemDetail()
            if item then
                local damage = tostring(item.damage)
                local nameScheme = item.name.." "..damage
                data[nameScheme] = item.count
            else
                print("no items!")
            end
            turtle.drop()
            turtle.suckDown()
            itemCount = turtle.getItemCount(1)
        end
    
        -- send the data
        data = textutils.serialize(data)
        rednet.send(controller.id, data, "manage") -- CONTROLLER cachemaster.lua storeItems() line 52
    end
end