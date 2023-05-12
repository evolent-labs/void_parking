fx_version 'cerulean'
game 'gta5'

author 'darkets @ Void | https://discord.gg/YEs29zEMk7'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/sh_config.lua',
}

client_scripts {
    'client/cl_main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_main.lua',
}

files {
    'locales/*.json'
}

lua54 'yes'
