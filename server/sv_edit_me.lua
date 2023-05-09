QBCore = exports[Config.CoreFolder]:GetCoreObject()

---@param source number
---@param text string
---@param type number
---@param time number
function notify(source, text, type, time)
    if type and text then
        if Config.Notifications == 'qbcore' then
            if type == 1 then
                TriggerClientEvent('QBCore:Notify', source, text, 'success')
            elseif type == 2 then
                TriggerClientEvent('QBCore:Notify', source, text, 'primary')
            elseif type == 3 then
                TriggerClientEvent('QBCore:Notify', source, text, 'error')
            end
        elseif Config.Notifications == 'mythic_new' then
            if type == 1 then
                TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = 'success', text = text, style = { ['background-color'] = '#ffffff', ['color'] = '#000000' } })
            elseif type == 2 then
                TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = 'inform', text = text, style = { ['background-color'] = '#ffffff', ['color'] = '#000000' } })
            elseif type == 3 then
                TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = 'error', text = text, style = { ['background-color'] = '#ffffff', ['color'] = '#000000' } })
            end
        elseif Config.Notifications == 'okok' then
            if type == 1 then
                TriggerClientEvent('okokNotify:Alert', source, Lang:t('other.notification_title'), type, time, 'success')
            elseif type == 2 then
                TriggerClientEvent('okokNotify:Alert', source, Lang:t('other.notification_title'), type, time, 'info')
            elseif type == 3 then
                TriggerClientEvent('okokNotify:Alert', source, Lang:t('other.notification_title'), type, time, 'error')
            end
        elseif Config.Notifications == 'other' then
            -- Add your own
        end
    end
    if Config.Notifications == 'chat' then
        TriggerEvent('chatMessage', source, text)
    end
end


---@param source number
---@param plate string
---@param vehnetit number
function addVehicleKeys(source, plate, vehnetid)
    local src = source
    TriggerClientEvent(Config.CoreTriggers['vehicle_keys'], src, plate)
end