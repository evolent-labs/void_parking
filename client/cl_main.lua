local QBCore = exports['qb-core']:GetCoreObject()

local isPreviewing = false
local previewObject = nil

local function cancelPlacement()
    DeleteObject(previewObject)
    previewObject = nil
    isPreviewing = false
    lib.hideTextUI()
end

---@param coords vector3
---@param rotation vector3
---@param model string
local function placeObject(coords, rotation, model)
    FreezeEntityPosition(previewObject, true)
    TriggerServerEvent('void_parking:server:placeMeter', coords, rotation, model)

    DeleteObject(previewObject)
    previewObject = nil
    isPreviewing = false
    lib.hideTextUI()
end

local function storeVehicle()
    local vehicle = GetVehiclePedIsIn(cache.ped, true)
    if not vehicle then return QBCore.Functions.Notify('Vehicle was not found') end

    local mods = lib.getVehicleProperties(vehicle)

    TriggerServerEvent('void_parking:server:storeVehicle', VehToNet(vehicle), mods)
end

local function openVehiclesMenu()
    local nearbyVehicles = lib.callback.await('void_parking:server:getVehiclesNearby', false)

    local vehicleMenu = {
        id = 'parking_menu',
        title = 'Parking Meter',
        options = {}
    }

    for _, car in pairs(nearbyVehicles) do
        local mods = json.decode(car.mods)

        vehicleMenu.options[#vehicleMenu.options + 1] = {
            title = QBCore.Shared.Vehicles[car.vehicle].name,
            description = ('Plate: %s'):format(mods.plate, mods.fuelLevel, mods.engineHealth, mods.bodyHealth),
            icon = 'car',
            metadata = {
                {label = 'Engine', value = mods.engineHealth},
                {label = 'Body', value = mods.bodyHealth},
                {label = 'Fuel', value = mods.fuelLevel}
            },
            onSelect = function()
                QBCore.Functions.Progressbar("takeout_vehicle", 'Pulling out vehicle', math.random(3000, 5000), false, true, {
                    disableMovement = false,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }, {
                    animDict = nil,
                    anim = nil,
                    flags = 16,
                }, {}, {}, function()
                    TriggerServerEvent('void_parking:server:vehicleTakeout', car)
                end, function()
                end)
            end,
        }
    end

    lib.registerContext(vehicleMenu)
    lib.showContext('parking_menu')
end

RegisterNetEvent('void_parking:client:placeMeter', function()
    if isPreviewing then return end
    isPreviewing = true

    local model = Config.ParkingMeterModel

    lib.requestModel(model)

    previewObject = CreateObject(model, GetEntityCoords(cache.ped), false, true, false)

    SetEntityAlpha(previewObject, 100, false)
    SetEntityCollision(previewObject, false, false)
    FreezeEntityPosition(previewObject, true)

    lib.showTextUI('[E] - Place | [Y] - Rotate | [Q] - Cancel')

    while isPreviewing do
        local hit, _, coords, _, _ = lib.raycast.cam(1, 4)

        if hit then
            SetEntityCoords(previewObject, coords.x, coords.y, coords.z)

            PlaceObjectOnGroundProperly(previewObject)

            if IsControlJustPressed(0, 44) then cancelPlacement() end

            if IsControlPressed(0, 246) then
                local rot = GetEntityRotation(previewObject)
                SetEntityRotation(previewObject, rot.x, rot.y, rot.z + 1.0, 0, true)
            end

            if IsControlJustPressed(0, 38) then
                local dis = #(coords - GetEntityCoords(cache.ped))

                if dis < 2.5 then
                    local rotation = GetEntityRotation(previewObject)
                    placeObject(coords, rotation, model)
                else
                    QBCore.Functions.Notify('You can\'t place it here', 'error')
                end
            end
        end
        Wait(1)
    end
end)

CreateThread(function()
    local onSelectParam = Config.Target == 'qb-target' and 'action' or 'onSelect'

    local options = {
        {
            icon = 'fas fa-list',
            label = 'Vehicle List',
            [onSelectParam] = function()
                openVehiclesMenu()
            end,
            canInteract = function()
                return not IsPedInAnyVehicle(cache.ped)
            end,
            distance = 3
        },
        {
            icon = 'fas fa-car',
            label = 'Store vehicle',
            onSelect = function()
                storeVehicle()
            end,
            distance = 3
        }
    }

    if Config.Target == 'ox_target' then
        exports.ox_target:addModel(Config.ParkingMeterModel, options)
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:AddTargetModel(Config.ParkingMeterModel, {
            options = options,
            distance = 2.5
        })
    end
end)

AddStateBagChangeHandler('vehicleProperties', nil, function(bagName, _, value)
    local veh = GetEntityFromStateBagName(bagName)
    if not value or NetworkGetEntityOwner(veh) ~= cache.playerId then return end

    local mods = json.decode(value)
    lib.setVehicleProperties(veh, mods)

    Entity(veh).state:set('vehicleProperties', nil, true)
end)
