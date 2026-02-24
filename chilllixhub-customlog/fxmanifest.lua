fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'ChilLLix Hub'
description 'Custom logging resource – Discord webhook logs with okokChat chat announcements'
version '1.0.0'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'qb-core',
    'qb-multicharacter',
}
