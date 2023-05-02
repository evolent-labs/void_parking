fx_version 'cerulean'
game 'gta5'

author 'Void Development | https://discord.gg/YEs29zEMk7'

shared_scripts {
    '@ox_lib/init.lua',
    '@qb-core/shared/locale.lua',
	'locales/en.lua',
    'shared/sh_config.lua',
}

client_scripts {
    -- '@PolyZone/client.lua',
	-- '@PolyZone/ComboZone.lua',
    'client/cl_edit_me.lua',
    'client/cl_main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_edit_me.lua',
    'server/sv_main.lua',
}

lua54 'yes'
