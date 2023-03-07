fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

description 'Crypto Mining Simulator'
author 'qw-scripts'
version '0.1.0'

client_scripts {
    'bridge/init.lua',
    'bridge/**/*',
    'client/**/*'
}

server_scripts {
    'bridge/init.lua', 
    'bridge/**/*',
    'server/**/*',
    '@oxmysql/lib/MySQL.lua' 
}

shared_scripts { '@ox_lib/init.lua', 'shared/**/*'  }