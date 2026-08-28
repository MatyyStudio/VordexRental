fx_version 'cerulean'
game 'gta5'

author 'Vordex'
description 'Advanced Vehicle Rental System'
version '1.2.0'

-- Tohle zajistí, že script spadne/upozorní, pokud ox_target neběží
dependencies {
    'ox_lib',
    'ox_target'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}