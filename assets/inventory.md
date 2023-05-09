If you're using qb-inventory, add this to qb-core/shared/items.lua

	['parking_meter'] 			 = {['name'] = 'parking_meter', 				['label'] = 'Parking Meter', 				['weight'] = 20000, 		['type'] = 'item', 		['image'] = 'parking_meter.png', 		['unique'] = false, 		['useable'] = true, 	['shouldClose'] = true,	   ['combinable'] = nil,   ['description'] = 'Create your own parking spot'},




If you're using ox_inventory, add this to ox_inventory/data/items.lua

['parking_meter'] = {
    label = 'Parking Meter',
    weight = 20000,
    stack = true,
    close = true,
    description = "Create a vehicle parking point yourself",
    client = {
        event = 'void_parking:client:placeMeter'
    }
},

And add parking_meter.png to your inventory images
