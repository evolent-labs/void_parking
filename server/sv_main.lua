lib.locale()
local db = require 'server.modules.db'

---@param number number
---@param decimals number
local function round(number, decimals)
    local scale = 10 ^ decimals
    local c = 2 ^ 52 + 2 ^ 51
    return ((number * scale + c) - c) / scale
end

RegisterNetEvent('void_parking:server:placeMeter', function(coords, rotation)
    local src = source
    local ped = GetPlayerPed(src)

    local dis = #(GetEntityCoords(ped) - coords)
    if dis > 2.0 then return end

    local model = Config.ParkingMeterModel
    local obj = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, true, false, false)
    if not DoesEntityExist(obj) then return end

    local player = QBCore.Functions.GetPlayer(src)
    player.Functions.RemoveItem('parking_meter', 1)

    SetEntityRotation(obj, rotation.x, rotation.y, rotation.z, 0, true)
    FreezeEntityPosition(obj, true)

    local objCoords = {
        x = round(coords.x, 2),
        y = round(coords.y, 2),
        z = round(coords.z, 2),
    }

    local objHeading = {
        x = round(rotation.x, 2),
        y = round(rotation.y, 2),
        z = round(rotation.z, 2),
    }

    db.insertParkingMeter(objCoords, rotation)
end)

RegisterNetEvent('void_parking:server:storeVehicle', function(vehicle, vehMods, hours)
    local src = source
    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)

    local vehicle = NetworkGetEntityFromNetworkId(vehicle)
    if not vehicle then return notify(src, locale('vehicle_not_found'), 3, 3000) end

    local plate = GetVehicleNumberPlateText(vehicle)
    local vehCoords = GetEntityCoords(vehicle)

    if #(pedCoords - vehCoords) > 7 then return notify(src, locale('too_far'), 3, 3000) end

    local vehData = {
        coords = json.encode({
            x = round(vehCoords.x, 2),
            y = round(vehCoords.y, 2),
            z = round(vehCoords.z, 2),
            h = round(GetEntityHeading(vehicle), 2)
        }),
        mods = vehMods,
        hours = hours
    }

    DeleteEntity(vehicle)
    db.updateVehicle(vehData)

    notify(src, locale('vehicle_stored'), 1, 4000)
end)

RegisterNetEvent('void_parking:server:vehicleTakeout', function(vehicle)
    local src = source
    local ped = GetPlayerPed(src)

    local model = joaat(vehicle.vehicle)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, true)

    while not DoesEntityExist(veh) do Wait(10) end

    while GetVehiclePedIsIn(ped) ~= veh do
        Wait(0)
        TaskWarpPedIntoVehicle(ped, veh, -1)
    end

    addVehicleKeys(src, vehicle.plate, NetworkGetNetworkIdFromEntity(veh))

    db.setVehicleUnparked(vehicle.plate)
    Entity(veh).state:set('vehicleProperties', vehicle.mods, true)
end)

local impoundVehicles = {}
lib.callback.register('void_parking:server:getVehicles', function(source, type)
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)

    local player = QBCore.Functions.GetPlayer(src)
    local cid = player.PlayerData.citizenid

    local vehicles = {}
    if type == 'impound' then
        for k, v in pairs(impoundVehicles) do
            if v.citizenid == cid then
                vehicles[k] = v
            end
        end

        return vehicles
    else
        vehicles = db.getVehicles(cid)
    end

    local nearbyVehicles = {}
    for _, car in pairs(vehicles) do
        if car.state ~= 1 then goto skip end

        if car.coords then
            local carCoords = json.decode(car.coords)
            local dis = #(coords - vec3(carCoords.x, carCoords.y, carCoords.z))
            
            if dis < 20 then
                nearbyVehicles[#nearbyVehicles + 1] = car
            end
        end

        ::skip::
    end

    return nearbyVehicles
end)

RegisterNetEvent('void_parking:server:takeOutImpound', function(data)
    local src = source

    local vehicleData = data.vehicleData
    local vehicleMods = json.decode(data.vehicleData.mods)

    local availableSpot = lib.callback.await('void_parking:getAvailableSpot', src, data.takeoutCoords)

    local newVehicle = CreateVehicle(vehicleMods.model, availableSpot.x, availableSpot.y, availableSpot.z, availableSpot.w, true, false)
    while not DoesEntityExist(newVehicle) do Wait(50) end

    local vehNetId = NetworkGetNetworkIdFromEntity(newVehicle)

    local timeout = 100
    while not NetworkGetEntityOwner(new_vehicle) and timeout > 0 do
        Wait(0)
        timeout -= 1
    end

    TriggerClientEvent('ox_lib:setVehicleProperties', src, vehNetId, vehicleMods)
    addVehicleKeys(src, vehicleMods.plate, vehNetId)

    impoundVehicles[vehicleMods.plate] = nil
end)

-- Framework
if Config.Inventory ~= 'ox_inventory' then
    QBCore.Functions.CreateUseableItem('parking_meter', function(source, item)
        local Player = QBCore.Functions.GetPlayer(source)
        if Player.Functions.GetItemByName(item.name) then
            TriggerClientEvent('void_parking:client:placeMeter', source)
        end
    end)
end

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    local parkingMeters = db.getParkingMeters()

    for k, v in pairs(parkingMeters) do
        local coords = json.decode(v.coords)
        local rotation = json.decode(v.rotation)

        local obj = CreateObjectNoOffset(joaat(Config.ParkingMeterModel), coords.x, coords.y, coords.z, true, false, false)
        SetEntityRotation(obj, rotation.x, rotation.y, rotation.z, 0, true)
        FreezeEntityPosition(obj, true)
    end

    for k, v in pairs(db.getImpoundVehicles()) do
        impoundVehicles[v.plate] = v
    end
end)

RegisterCommand('parkingsetup', function(source)
    if source ~= 0 then return warn('This command must be executed from the server console') end

    MySQL.query('UPDATE player_vehicles SET state = 1 WHERE state = 0;')
    print('Set up completed. Players now may get their vehicles at the nearest depot.')
end)
