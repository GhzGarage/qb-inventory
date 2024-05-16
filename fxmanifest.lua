fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'Player inventory system providing a variety of features for storing and managing items'
version '2.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
    'config/*.lua',
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/main.css',
    'html/app.js',
    'html/images/*.png',
}

dependency 'qb-weapons'
