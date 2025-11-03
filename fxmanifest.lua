fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'TonNom'
description 'TIG complet sans NUI - OX_LIB only'
version '3.0.1'

shared_scripts {
    '@ox_lib/init.lua'
}

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'ox_lib',
    'oxmysql'
}
