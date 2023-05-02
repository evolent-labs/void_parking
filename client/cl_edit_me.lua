---@param vehicle string 
---@param data table
function initVehicle(vehicle, data)
    local coords = GetEntityCoords(PlayerPedId())

    Framework.Functions.SetVehicleProperties(vehicle, json.decode(data.mods))

    SetVehicleNumberPlateText(vehicle, data.plate)

    SetEntityHeading(vehicle, coords.w)

    exports['LegacyFuel']:SetFuel(vehicle, 100.0)

    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)

    TriggerEvent("vehiclekeys:client:SetOwner", data.plate)

    SetVehicleEngineOn(vehicle, true, true)
end


---@param vehicle number
---@param body_health number
---@param engine_health number
function setVehicleDamage(vehicle, body_health, engine_health)
    body_health += 0.0
    engine_health += 0.0

    if body_health < 900.0 then
        SmashVehicleWindow(vehicle, 0)
        SmashVehicleWindow(vehicle, 1)
        SmashVehicleWindow(vehicle, 2)
        SmashVehicleWindow(vehicle, 3)
        SmashVehicleWindow(vehicle, 4)
        SmashVehicleWindow(vehicle, 5)
        SmashVehicleWindow(vehicle, 6)
        SmashVehicleWindow(vehicle, 7)
    end

    if body_health < 800.0 then
        SetVehicleDoorBroken(vehicle, 0, true)
        SetVehicleDoorBroken(vehicle, 1, true)
        SetVehicleDoorBroken(vehicle, 2, true)
        SetVehicleDoorBroken(vehicle, 3, true)
        SetVehicleDoorBroken(vehicle, 4, true)
        SetVehicleDoorBroken(vehicle, 5, true)
        SetVehicleDoorBroken(vehicle, 6, true)
    end

    if engine_health < 700.0 then
        SetVehicleTyreBurst(vehicle, 1, false, 990.0)
        SetVehicleTyreBurst(vehicle, 2, false, 990.0)
        SetVehicleTyreBurst(vehicle, 3, false, 990.0)
        SetVehicleTyreBurst(vehicle, 4, false, 990.0)
    end

    if engine_health < 500.0 then
        SetVehicleTyreBurst(vehicle, 0, false, 990.0)
        SetVehicleTyreBurst(vehicle, 5, false, 990.0)
        SetVehicleTyreBurst(vehicle, 6, false, 990.0)
        SetVehicleTyreBurst(vehicle, 7, false, 990.0)
    end

    SetVehicleEngineHealth(vehicle, engine_health)
    SetVehicleBodyHealth(vehicle, body_health)
end
