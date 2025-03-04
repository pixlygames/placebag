local QBCore = exports['qb-core']:GetCoreObject()

-- Initialize database table on resource start
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `placed_bags` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `item_type` VARCHAR(50) NOT NULL,
            `item_name` VARCHAR(50) NOT NULL,
            `item_amount` INT(11) NOT NULL,
            `coords` VARCHAR(255) NOT NULL,
            `placed_by` VARCHAR(50) NOT NULL,
            `placed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        )
    ]])
    
    -- Load all placed bags when server starts
    LoadAllPlacedBags()
end)

-- Load all placed bags from database
function LoadAllPlacedBags()
    MySQL.query('SELECT * FROM placed_bags', {}, function(result)
        if result and #result > 0 then
            for _, bag in ipairs(result) do
                local coords = json.decode(bag.coords)
                
                -- Get item type configuration
                local itemType = bag.item_type
                local itemTypeConfig = Config.ItemTypes[itemType]
                local itemConfig = nil
                
                -- Find the specific item configuration
                if itemTypeConfig and itemTypeConfig.items then
                    itemConfig = itemTypeConfig.items[bag.item_name]
                end
                
                -- Create complete bag data with all necessary information
                local bagData = {
                    id = bag.id,
                    itemType = itemType,
                    itemName = bag.item_name,
                    itemAmount = bag.item_amount,
                    coords = coords,
                    placedBy = bag.placed_by,
                    -- Add blip and prop information from config
                    blipColor = (itemConfig and itemConfig.blipColor) or Config.BlipSettings.color,
                    blipName = (itemConfig and itemConfig.blipName) or Config.BlipSettings.name
                }
                
                -- Add a small delay between each bag creation to prevent overloading
                Wait(50)
                
                -- Broadcast to all clients to create the bag and blip
                TriggerClientEvent('placebag:client:createBagAndBlip', -1, bagData)
                
                if Config.Debug then
                    print('Loaded bag ID: ' .. bag.id .. ' with item: ' .. bag.item_name)
                end
            end
        end
    end)
end

-- Command to place a bag
QBCore.Commands.Add('placebag', 'Place a bag with items (Admin Only)', {{name = 'type', help = 'Item type (drugs, weapons, valuables)'}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player has admin permissions - IMPROVED CHECK
    if not IsPlayerAdmin(src) then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to use this command', 'error')
        return
    end
    
    local itemType = args[1] and args[1]:lower() or nil
    
    -- Validate item type
    if not itemType or not Config.ItemTypes[itemType] then
        local validTypes = ''
        for type, _ in pairs(Config.ItemTypes) do
            validTypes = validTypes .. type .. ', '
        end
        validTypes = validTypes:sub(1, -3) -- Remove trailing comma and space
        
        TriggerClientEvent('QBCore:Notify', src, 'Invalid item type. Valid types: ' .. validTypes, 'error')
        return
    end
    
    -- Get player position to place the bag
    TriggerClientEvent('placebag:client:getPlayerPosition', src, itemType)
end, 'admin')

-- IMPROVED: Check if player has admin permissions
function IsPlayerAdmin(source)
    -- Method 1: Check using QBCore's built-in IsPlayerAdmin function if available
    if QBCore.Functions.HasPermission then
        local hasPermission = QBCore.Functions.HasPermission(source, 'admin') or 
                             QBCore.Functions.HasPermission(source, 'god') or 
                             QBCore.Functions.HasPermission(source, 'superadmin')
        if hasPermission then return true end
    end
    
    -- Method 2: Check player's permission group directly
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        local group = Player.PlayerData.permission
        -- Debug print to help troubleshoot
        if Config.Debug then
            print("Player permission group: " .. tostring(group))
        end
        
        -- Check if the group is in the allowed admin groups
        if Config.AdminGroups[group] then
            return true
        end
        
        -- Additional check for common admin group names
        if group == 'admin' or group == 'superadmin' or group == 'god' or group == 'mod' then
            return true
        end
    end
    
    -- Method 3: Check if player has admin menu access
    if QBCore.Functions.IsOptin then
        return QBCore.Functions.IsOptin(source)
    end
    
    return false
end

-- Event to place a bag at the player's position
RegisterNetEvent('placebag:server:placeBag', function(itemType, position)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player or not IsPlayerAdmin(src) then return end
    
    -- Select a random item from the specified type
    local selectedItem = SelectRandomItem(itemType)
    if not selectedItem then
        TriggerClientEvent('QBCore:Notify', src, 'No items configured for type: ' .. itemType, 'error')
        return
    end
    
    -- Calculate random amount if specified as a range
    local amount = selectedItem.amount
    if type(amount) == 'table' and amount.min and amount.max then
        amount = math.random(amount.min, amount.max)
    end
    
    -- Prepare data for database
    local coords = {
        x = position.x,
        y = position.y,
        z = position.z,
        w = position.w -- Heading
    }
    
    -- Insert into database
    MySQL.insert('INSERT INTO placed_bags (item_type, item_name, item_amount, coords, placed_by) VALUES (?, ?, ?, ?, ?)',
        {
            itemType,
            selectedItem.name,
            amount,
            json.encode(coords),
            Player.PlayerData.citizenid
        },
        function(id)
            if id then
                local bagData = {
                    id = id,
                    itemType = itemType,
                    itemName = selectedItem.name,
                    itemAmount = amount,
                    coords = coords,
                    placedBy = Player.PlayerData.citizenid,
                    blipColor = selectedItem.blipColor or Config.BlipSettings.color,
                    blipName = selectedItem.blipName or Config.BlipSettings.name
                }
                
                -- Broadcast to all clients to create the bag and blip
                TriggerClientEvent('placebag:client:createBagAndBlip', -1, bagData)
                
                TriggerClientEvent('QBCore:Notify', src, 'Bag placed with ' .. selectedItem.label, 'success')
                
                if Config.Debug then
                    print('Placed bag ID: ' .. id .. ' with item: ' .. selectedItem.name .. ' by: ' .. Player.PlayerData.citizenid)
                end
            else
                TriggerClientEvent('QBCore:Notify', src, 'Failed to place bag', 'error')
            end
        end
    )
end)

-- Select a random item from the specified type based on chance
function SelectRandomItem(itemType)
    local typeConfig = Config.ItemTypes[itemType]
    if not typeConfig or not typeConfig.items then return nil end
    
    local items = {}
    local totalChance = 0
    
    -- Prepare items with their chances
    for itemName, itemData in pairs(typeConfig.items) do
        local chance = itemData.chance or 100
        totalChance = totalChance + chance
        
        table.insert(items, {
            name = itemName,
            label = itemData.label,
            amount = itemData.amount,
            chance = chance,
            blipColor = itemData.blipColor,
            blipName = itemData.blipName
        })
    end
    
    -- Select a random item based on chance
    local randomNum = math.random(1, totalChance)
    local currentChance = 0
    
    for _, item in ipairs(items) do
        currentChance = currentChance + item.chance
        if randomNum <= currentChance then
            return item
        end
    end
    
    -- Fallback to first item if something goes wrong
    return items[1]
end

-- Event when a player collects a bag
RegisterNetEvent('placebag:server:collectBag', function(bagId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Get bag data from database
    MySQL.query('SELECT * FROM placed_bags WHERE id = ?', {bagId}, function(result)
        if result and result[1] then
            local bag = result[1]
            local itemName = bag.item_name
            local itemAmount = bag.item_amount
            
            -- Add item to player inventory
            if Player.Functions.AddItem(itemName, itemAmount) then
                -- Remove bag from database
                MySQL.query('DELETE FROM placed_bags WHERE id = ?', {bagId})
                
                -- Get item label for notification
                local itemLabel = QBCore.Shared.Items[itemName] and QBCore.Shared.Items[itemName].label or itemName
                
                -- Notify player
                TriggerClientEvent('QBCore:Notify', src, 'You found ' .. itemAmount .. 'x ' .. itemLabel, 'success')
                
                -- Broadcast to all clients to remove the bag and blip
                TriggerClientEvent('placebag:client:removeBagAndBlip', -1, bagId)
                
                if Config.Debug then
                    print('Player ' .. Player.PlayerData.citizenid .. ' collected bag ID: ' .. bagId)
                end
            else
                TriggerClientEvent('QBCore:Notify', src, 'Your pockets are full', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'Bag not found', 'error')
        end
    end)
end)

-- Event to sync bag removal when database is updated externally
RegisterNetEvent('placebag:server:syncBags', function()
    LoadAllPlacedBags()
end)

-- Command to reload all bags (Admin Only)
QBCore.Commands.Add('reloadbags', 'Reload all placed bags (Admin Only)', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player has admin permissions
    if not IsPlayerAdmin(src) then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to use this command', 'error')
        return
    end
    
    -- Clear all bags on all clients
    TriggerClientEvent('placebag:client:clearAllBags', -1)
    
    -- Reload all bags from database
    LoadAllPlacedBags()
    
    TriggerClientEvent('QBCore:Notify', src, 'All bags reloaded', 'success')
end, 'admin')

-- Event to handle bag reload requests from clients
RegisterNetEvent('placebag:server:requestAllBags', function()
    local src = source
    
    -- Load all bags for this specific client
    MySQL.query('SELECT * FROM placed_bags', {}, function(result)
        if result and #result > 0 then
            -- First clear any existing bags for this client
            TriggerClientEvent('placebag:client:clearAllBags', src)
            
            -- Wait a moment for the clear to complete
            Wait(500)
            
            for _, bag in ipairs(result) do
                local coords = json.decode(bag.coords)
                
                -- Get item type configuration
                local itemType = bag.item_type
                local itemTypeConfig = Config.ItemTypes[itemType]
                local itemConfig = nil
                
                -- Find the specific item configuration
                if itemTypeConfig and itemTypeConfig.items then
                    itemConfig = itemTypeConfig.items[bag.item_name]
                end
                
                -- Create complete bag data with all necessary information
                local bagData = {
                    id = bag.id,
                    itemType = itemType,
                    itemName = bag.item_name,
                    itemAmount = bag.item_amount,
                    coords = coords,
                    placedBy = bag.placed_by,
                    -- Add blip and prop information from config
                    blipColor = (itemConfig and itemConfig.blipColor) or Config.BlipSettings.color,
                    blipName = (itemConfig and itemConfig.blipName) or Config.BlipSettings.name
                }
                
                -- Add a small delay between each bag creation to prevent overloading
                Wait(50)
                
                -- Send to the specific client that requested the bags
                TriggerClientEvent('placebag:client:createBagAndBlip', src, bagData)
                
                if Config.Debug then
                    print('Sent bag ID: ' .. bag.id .. ' to player: ' .. src)
                end
            end
            
            -- Notify the player
            TriggerClientEvent('QBCore:Notify', src, 'Loaded ' .. #result .. ' bags', 'success')
        else
            if Config.Debug then
                print('No bags found in database for player: ' .. src)
            end
        end
    end)
end) 