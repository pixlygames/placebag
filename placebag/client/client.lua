local QBCore = exports['qb-core']:GetCoreObject()

-- Local variables
local placedBags = {} -- Table to store all placed bags
local bagObjects = {} -- Table to store all bag objects
local bagBlips = {} -- Table to store all bag blips

-- Event to get player position for bag placement
RegisterNetEvent('placebag:client:getPlayerPosition', function(itemType)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    local position = {
        x = coords.x,
        y = coords.y,
        z = coords.z - 1.0, -- Place slightly below player to ensure it's on the ground
        w = heading
    }
    
    -- Send position back to server
    TriggerServerEvent('placebag:server:placeBag', itemType, position)
end)

-- Event to create bag and blip
RegisterNetEvent('placebag:client:createBagAndBlip', function(bagData)
    if not bagData or not bagData.id then
        print("Error: Invalid bag data received")
        return
    end
    
    -- Store bag data
    placedBags[bagData.id] = bagData
    
    -- Create bag object with a slight delay to ensure proper loading
    CreateBagObject(bagData)
    
    -- Create blip on map
    CreateBagBlip(bagData)
    
    if Config.Debug then
        print("Created bag and blip for ID: " .. bagData.id .. " at coords: " .. 
              json.encode({x = bagData.coords.x, y = bagData.coords.y, z = bagData.coords.z}))
    end
end)

-- Function to create bag object
function CreateBagObject(bagData)
    -- Delete existing object if it exists
    if bagObjects[bagData.id] then
        DeleteObject(bagObjects[bagData.id])
        bagObjects[bagData.id] = nil
    end
    
    -- Get prop model based on item type
    local propModel = Config.PropSettings.defaultProp
    local itemTypeConfig = Config.ItemTypes[bagData.itemType]
    
    if itemTypeConfig and itemTypeConfig.prop then
        propModel = itemTypeConfig.prop
    end
    
    -- Load model
    RequestModel(propModel)
    local timeout = 0
    while not HasModelLoaded(propModel) and timeout < 50 do
        Wait(10)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(propModel) then
        print("Failed to load model: " .. propModel)
        propModel = "prop_cs_heist_bag_01" -- Fallback to a common model
        RequestModel(propModel)
        Wait(500)
    end
    
    -- Create object
    local obj = CreateObject(propModel, bagData.coords.x, bagData.coords.y, bagData.coords.z, false, false, false)
    
    if not obj or obj == 0 then
        print("Failed to create object for bag ID: " .. bagData.id)
        return
    end
    
    SetEntityHeading(obj, bagData.coords.w or 0.0)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetEntityAsMissionEntity(obj, true, true)
    
    -- Store object
    bagObjects[bagData.id] = obj
    
    -- Add interaction target
    exports['qb-target']:AddTargetEntity(obj, {
        options = {
            {
                type = "client",
                event = "placebag:client:collectBag",
                icon = "fas fa-hand-paper",
                label = "Collect Bag",
                bagId = bagData.id
            }
        },
        distance = 2.0
    })
    
    SetModelAsNoLongerNeeded(propModel)
end

-- Function to create blip on map
function CreateBagBlip(bagData)
    -- Delete existing blip if it exists
    if bagBlips[bagData.id] then
        RemoveBlip(bagBlips[bagData.id])
        bagBlips[bagData.id] = nil
    end
    
    -- Create blip
    local blip = AddBlipForCoord(bagData.coords.x, bagData.coords.y, bagData.coords.z)
    
    -- Set blip properties
    SetBlipSprite(blip, Config.BlipSettings.sprite)
    SetBlipColour(blip, bagData.blipColor or Config.BlipSettings.color)
    SetBlipScale(blip, Config.BlipSettings.scale)
    SetBlipAsShortRange(blip, Config.BlipSettings.shortRange)
    
    -- Set blip name
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(bagData.blipName or Config.BlipSettings.name)
    EndTextCommandSetBlipName(blip)
    
    -- Store blip
    bagBlips[bagData.id] = blip
end

-- Event to remove bag and blip
RegisterNetEvent('placebag:client:removeBagAndBlip', function(bagId)
    -- Remove bag object
    if bagObjects[bagId] then
        exports['qb-target']:RemoveTargetEntity(bagObjects[bagId])
        DeleteObject(bagObjects[bagId])
        bagObjects[bagId] = nil
    end
    
    -- Remove blip
    if bagBlips[bagId] then
        RemoveBlip(bagBlips[bagId])
        bagBlips[bagId] = nil
    end
    
    -- Remove from stored bags
    placedBags[bagId] = nil
end)

-- Event to clear all bags
RegisterNetEvent('placebag:client:clearAllBags', function()
    -- Remove all bag objects
    for bagId, obj in pairs(bagObjects) do
        if DoesEntityExist(obj) then
            exports['qb-target']:RemoveTargetEntity(obj)
            DeleteObject(obj)
        end
    end
    
    -- Remove all blips
    for bagId, blip in pairs(bagBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    
    -- Clear tables
    placedBags = {}
    bagObjects = {}
    bagBlips = {}
end)

-- Event to collect bag
RegisterNetEvent('placebag:client:collectBag', function(data)
    local bagId = data.bagId
    
    if not bagId or not placedBags[bagId] then
        QBCore.Functions.Notify('Bag not found', 'error')
        return
    end
    
    -- Play animation
    TaskStartScenarioInPlace(PlayerPedId(), "PROP_HUMAN_BUM_BIN", 0, true)
    QBCore.Functions.Progressbar("collect_bag", "Collecting bag...", 3000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        ClearPedTasks(PlayerPedId())
        
        -- Trigger server event to collect bag
        TriggerServerEvent('placebag:server:collectBag', bagId)
    end, function() -- Cancel
        ClearPedTasks(PlayerPedId())
        QBCore.Functions.Notify('Cancelled', 'error')
    end)
end)

-- Add a command to force reload all bags
RegisterCommand('refreshbags', function()
    TriggerEvent('placebag:client:clearAllBags')
    TriggerServerEvent('placebag:server:requestAllBags')
    QBCore.Functions.Notify('Refreshing all bags...', 'primary', 3000)
end, false)

-- Event to request all bags from server
RegisterNetEvent('placebag:client:requestAllBags', function()
    TriggerServerEvent('placebag:server:requestAllBags')
end)

-- Request all bags when player spawns
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(3000) -- Wait a bit for everything to load
    TriggerServerEvent('placebag:server:requestAllBags')
end)

-- Resource cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    -- Remove all bag objects
    for bagId, obj in pairs(bagObjects) do
        if DoesEntityExist(obj) then
            DeleteObject(obj)
        end
    end
    
    -- Remove all blips
    for bagId, blip in pairs(bagBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
end) 