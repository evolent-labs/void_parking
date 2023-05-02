local MySQL = MySQL

local STATE_UNPARKED = 0
local STATE_PARKED = 1

local db = {}

local INSERT_PARKING_METER = 'INSERT INTO parkingmeters (coords, rotation) VALUES (?, ?)'
---@param coords vector3
---@param rotation vector3
function db.insertParkingMeter(coords, rotation)
    MySQL.prepare(INSERT_PARKING_METER, { json.encode(coords), json.encode(rotation) })
end

local UPDATE_VEHICLE = 'UPDATE player_vehicles SET state = ?, coords = ?, fuel = ?, engine = ?, body = ? WHERE plate = ?'
---@param vehData table
function db.updateVehicle(vehData)
    MySQL.query(UPDATE_VEHICLE, { STATE_PARKED, vehData.coords, vehData.mods.fuel, vehData.mods.engineHealth, vehData.mods.bodyHealth, vehData.mods.plate })
end

local SET_VEHICLE_UNPARKED = 'UPDATE player_vehicles SET state = ? WHERE plate = ?'
---@param plate string
function db.setVehicleUnparked(plate)
    MySQL.prepare(SET_VEHICLE_UNPARKED, { STATE_UNPARKED, plate })
end

local GET_VEHICLES = 'SELECT * FROM player_vehicles WHERE citizenid = ?'
---@param citizenid string
function db.getVehicles(citizenid)
    return MySQL.query.await(GET_VEHICLES, { citizenid })
end

local GET_METERS = 'SELECT * FROM parkingmeters'
function db.getParkingMeters()
    return MySQL.query.await(GET_METERS)
end

return db
