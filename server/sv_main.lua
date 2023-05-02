local QBCore = exports['qb-core']:GetCoreObject()

local db = require 'server.modules.db'

---@param number number
---@param decimals number
local function round(number, decimals)
    local scale = 10 ^ decimals
    local c = 2 ^ 52 + 2 ^ 51
    return ((number * scale + c) - c) / scale
end

RegisterNetEvent('void_parking:server:placeMeter', function(coords, rotation, model)
    local src = source
    local ped = GetPlayerPed(src)

    local dis = #(GetEntityCoords(ped) - coords)

    if dis > 2.0 then return end

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

    TriggerClientEvent("vehiclekeys:client:SetOwner", src, vehicle.plate)

    db.setVehicleUnparked(vehicle.plate)
    Entity(veh).state:set('vehicleProperties', vehicle.mods, true)
end)

RegisterNetEvent('void_parking:server:storeVehicle', function(vehicle, vehMods)
    local src = source
    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)

    local vehicle = NetworkGetEntityFromNetworkId(vehicle)
    if not vehicle then return notify(src, 'Vehicle not found', 3, 3000) end

    local plate = GetVehicleNumberPlateText(vehicle)
    local vehCoords = GetEntityCoords(vehicle)

    if #(pedCoords - vehCoords) > 7 then return TriggerClientEvent('QBCore:Notify', src, 'Vehicle too far', 'error') end

    local vehData = {
        coords = json.encode({
            x = round(vehCoords.x, 2),
            y = round(vehCoords.y, 2),
            z = round(vehCoords.z, 2),
            h = round(GetEntityHeading(vehicle), 2)
        }),
        mods = vehMods
    }

    DeleteEntity(vehicle)
    db.updateVehicle(vehData)

    TriggerClientEvent('QBCore:Notify', src, 'Vehicle Stored', 'success')
end)

lib.callback.register('void_parking:server:getVehiclesNearby', function(source)
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)

    local player = QBCore.Functions.GetPlayer(src)
    local cid = player.PlayerData.citizenid

    local vehicles = db.getVehicles(cid)

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

QBCore.Functions.CreateUseableItem('parking_meter', function(source, item)
	local Player = QBCore.Functions.GetPlayer(source)
	if Player.Functions.GetItemByName(item.name) then
		TriggerClientEvent('void_parking:client:placeMeter', source)
	end
end)

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    local parkingMeters = db.getParkingMeters()

    for k, v in pairs(parkingMeters) do
        local coords = json.decode(v.coords)
        local rotation = json.decode(v.rotation)

        local obj = CreateObjectNoOffset(`prop_parkingpay`, coords.x, coords.y, coords.z, true, false, false)
        SetEntityRotation(obj, rotation.x, rotation.y, rotation.z, 0, true)
    
        FreezeEntityPosition(obj, true)
    end
end)
