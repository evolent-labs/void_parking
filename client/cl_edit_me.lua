QBCore = exports[Config.CoreFolder]:GetCoreObject()

---@param text string
---@param type string
---@param time number
function notify(text, type, time)
    if type and text then
        if Config.Notifications == 'qbcore' then
            if type == 1 then
                QBCore.Functions.Notify(text, 'success')
            elseif type == 2 then
                QBCore.Functions.Notify(text, 'primary')
            elseif type == 3 then
                QBCore.Functions.Notify(text, 'error')
            end
        elseif Config.Notifications == 'mythic' then
            if type == 1 then
                exports['mythic_notify']:SendAlert('success', text, { ['background-color'] = '#ffffff', ['color'] = '#000000' })
            elseif type == 2 then
                exports['mythic_notify']:SendAlert('inform', text, { ['background-color'] = '#ffffff', ['color'] = '#000000' })
            elseif type == 3 then
                exports['mythic_notify']:SendAlert('error', text, { ['background-color'] = '#ffffff', ['color'] = '#000000' })
            end
        elseif Config.notifications == 'okok' then
            if type == 1 then
                exports['okokNotify']:Alert(Lang:t('other.notification_title'), text, time, 'success')
            elseif type == 2 then
                exports['okokNotify']:Alert(Lang:t('other.notification_title'), text, time, 'info')
            elseif type == 3 then
                exports['okokNotify']:Alert(Lang:t('other.notification_title'), text, time, 'error')
            end
        elseif Config.Notifications == 'chat' then
            TriggerEvent('chatMessage', text)
        elseif Config.Notifications == 'other' then
            -- Add your own
        end
    end
end

---@param func function
function progressBar(func)
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
