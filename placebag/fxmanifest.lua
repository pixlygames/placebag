fx_version 'cerulean'
game 'gta5'

author 'Pixly Games'
description 'Admin Placeable Bags/Items with Persistent Blips'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config/config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

lua54 'yes' 
