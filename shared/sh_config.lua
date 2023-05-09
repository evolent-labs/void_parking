Config = {}

Config.CoreFolder = 'qb-core'
Config.Target = 'ox_target' -- qb-target | ox_target
Config.TextUI = 'ox_lib' -- qbcore | ox_lib
Config.Inventory = 'ox_inventory' -- qb-inventory | ox_inventory
Config.Notifications = 'qbcore' -- qbcore | mythic_new | okok | other
Config.UnloadEvent = 'QBCore:Client:OnPlayerUnload'

Config.ParkingMeterModel = 'prop_parkingpay'

Config.Depots = {
    [1] = {
        ped_coords = vector4(483.98, -1309.51, 29.23, 250.69), -- [[ Ped position for the depot ]]
        ped_model = 'cs_josef', -- [[ Ped model from https://docs.fivem.net/docs/game-references/ped-models/ ]]
        ped_scenario = 'WORLD_HUMAN_CLIPBOARD', -- [[ Ped scenario from https://github.com/DioneB/gtav-scenarios ]]
        takeout_coords = { -- [[ All of the positions that vehicles can be spawned on after they have been taken out. If one position is occupied, it will choose the next one. ]]
            vector4(487.24, -1332.86, 29.32, 301.16),
            vector4(490.73, -1339.3, 29.28, 355.72),
            vector4(498.73, -1337.53, 29.32, 359.52)
        },
        depot_name = 'Hayes Depot', -- [[ This will change blip names and menu headers ]]
        show_blip = true, -- [[ Whether or not to show the blip on the map and minimap of this depot ]]
        depot_price = 500 -- [[ The price players have to pay to get their vehicle out of the depot ]]
    }
}
