local QBCore = exports['qb-core']:GetCoreObject()

lib.locale()
local isPreviewing = false
local previewObject = nil

---@param text string
local function showTextUI(text)
    if Config.TextUI == 'ox_lib' then
        lib.showTextUI(text)
    elseif Config.TextUI == 'qbcore' then
        exports['qb-core']:DrawText(text)
    end
end

local function hideTextUI()
    if Config.TextUI == 'ox_lib' then
        lib.hideTextUI()
    elseif Config.TextUI == 'qbcore' then
        exports['qb-core']:HideText()
    end
end

local function cancelPlacement()
    DeleteObject(previewObject)
    previewObject = nil
    isPreviewing = false
    hideTextUI()
end

---@param coords vector3
---@param rotation vector3
---@todo Server event needs model defined
local function placeObject(coords, rotation)
    DeleteObject(previewObject)
    hideTextUI()

    TriggerServerEvent('void_parking:server:placeMeter', coords, rotation)
    previewObject, isPreviewing = nil, false
end

---@param func function
local function progressBar(func)
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
        func() 
    end, 
    function() -- Cancel

    end)
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

    showTextUI('[E] - Place | [Y] - Rotate | [Q] - Cancel')

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
                    QBCore.Functions.Notify(locale('cant_place'), 3, 3000)
                end
            end
        end
        Wait(1)
    end
end)

---@param type? string
---@param depot? table
local function openVehiclesMenu(type, depot)
    local vehicles
    if type == 'impound' then
        vehicles = lib.callback.await('void_parking:server:getVehicles', false, 'impound')
    else
        vehicles = lib.callback.await('void_parking:server:getVehicles', false)
    end
    if not next(vehicles) then return QBCore.Functions.Notify(locale('no_vehicles'), 2, 3000) end

    local vehicleMenu = {
        id = 'parking_menu',
        title = 'Parking Meter',
        options = {}
    }

    for _, car in pairs(vehicles) do
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
                if type == 'impound' then
                    local data = {
                        vehicleData = car,
                        takeoutCoords = depot.takeout_coords
                    }
                    TriggerServerEvent('void_parking:server:takeOutImpound', data)
                else
                    progressBar(function() TriggerServerEvent('void_parking:server:vehicleTakeout', car) end)
                end
            end,
        }
    end

    lib.registerContext(vehicleMenu)
    lib.showContext('parking_menu')
end

local function storeVehicle()
    local vehicle = GetVehiclePedIsIn(cache.ped, true)
    if not vehicle then return QBCore.Functions.Notify(locale('vehicle_not_found'), 2, 3000) end

    local mods = lib.getVehicleProperties(vehicle)

    TriggerServerEvent('void_parking:server:storeVehicle', VehToNet(vehicle), mods)
end

local depotPeds = {}
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
            distance = 2
        },
        {
            icon = 'fas fa-car',
            label = 'Store vehicle',
            onSelect = function()
                storeVehicle()
            end,
            distance = 3
        },
    }

    local model = Config.ParkingMeterModel
    if Config.Target == 'ox_target' then
        exports.ox_target:addModel(model, options)
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:AddTargetModel(model, {
            options = options,
            distance = 2.5
        })
    end

    -- Depots
    for _, depot in pairs(Config.Depots) do

        local pedModel = lib.requestModel(depot.ped_model)
    
        local depotPed = CreatePed(0, pedModel, depot.ped_coords.x, depot.ped_coords.y, depot.ped_coords.z - 1, depot.ped_coords.w, false, true)
        FreezeEntityPosition(depotPed, true)
        SetEntityInvincible(depotPed, true)
        SetBlockingOfNonTemporaryEvents(depotPed, true)
        TaskStartScenarioInPlace(depotPed, depot.ped_scenario, 0, true)

        depotPeds[#depotPeds] = pedModel

        local options = {
            {
                icon = "fas fa-warehouse",
                label = depot.depot_name,
                [onSelectParam] = function()
                    openVehiclesMenu('impound', depot)
                end,
                distance = 2.5
            }
        }
    
        if Config.Target == 'ox_target' then
            exports.ox_target:addLocalEntity(depotPed, options)
        elseif Config.Target == 'qb-target' then
            exports['qb-target']:AddTargetModel(depotPed, {
                options = options,
                distance = 2.5
            })
        end

        if depot.show_blip then
            local blip = AddBlipForCoord(depot.ped_coords.xyz)
            SetBlipSprite(blip, 317)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.7)
            SetBlipAsShortRange(blip, true)
            SetBlipColour(blip, 3)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(depot.depot_name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

lib.callback.register('void_parking:getAvailableSpot', function(positions)
    for k, v in pairs(positions) do
        if not IsPositionOccupied(v.x, v.y, v.z, 5, false, true, true) then
            QBCore.Functions.Notify(locale('depot_take_out'), 1, 3000)
            return v
        end
    end
    QBCore.Functions.Notify(locale('depot_err_no_space'), 2, 5000)
end)

AddStateBagChangeHandler('vehicleProperties', nil, function(bagName, _, value)
    local veh = GetEntityFromStateBagName(bagName)
    if not value or NetworkGetEntityOwner(veh) ~= cache.playerId then return end

    local mods = json.decode(value)
    lib.setVehicleProperties(veh, mods)

    Entity(veh).state:set('vehicleProperties', nil, true)
end)
